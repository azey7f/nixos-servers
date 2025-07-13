{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.certManager;
in {
  options.az.svc.rke2.certManager = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.server.rke2.manifests."cert-manager" = [
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "cert-manager";
          namespace = "kube-system";
        };
        spec = {
          chart = "cert-manager";
          repo = "https://charts.jetstack.io";
          targetNamespace = "cert-manager";
          createNamespace = true;
          valuesContent = builtins.toJSON {
            crds.enabled = true;
            config.enableGatewayAPI = true;
            extraArgs = [
              # use local NS directly
              "--dns01-recursive-nameservers-only"
              "--dns01-recursive-nameservers=knot.app-nameserver.svc:53"
            ];
          };
        };
      }
      {
        apiVersion = "cert-manager.io/v1";
        kind = "ClusterIssuer";
        metadata = {
          name = "letsencrypt-issuer";
          namespace = "cert-manager";
        };
        spec.acme = {
          server = "https://acme-v02.api.letsencrypt.org/directory";
          preferredChain = "ISRG Root X2"; # ECDSA P-384

          email = "domain-admin@${config.az.server.rke2.baseDomain}";
          privateKeySecretRef.name = "letsencrypt-certkey";
          solvers = [
            {
              selector = {};
              dns01.rfc2136 = {
                nameserver = "knot.app-nameserver.svc";
                tsigKeyName = "acme";
                tsigAlgorithm = "HMACSHA256";
                tsigSecretSecretRef = {
                  name = "rfc2136-tsig";
                  key = "secret";
                };
              };
            }
          ];
        };
      }
    ];
  };
}
