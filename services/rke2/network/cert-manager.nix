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
  domain = config.az.server.rke2.baseDomain;
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
          targetNamespace = "cert-manager";
          createNamespace = true;

          chart = "cert-manager";
          repo = "https://charts.jetstack.io";
          version = "1.18.2";

          valuesContent = builtins.toJSON {
            crds.enabled = true;
            config.enableGatewayAPI = true;
            extraArgs = [
              # use local NS directly
              "--dns01-recursive-nameservers-only"
              "--dns01-recursive-nameservers=knot-public.app-nameserver.svc:53"
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
                nameserver = "knot-public.app-nameserver.svc";
                tsigKeyName = "acme";
                tsigAlgorithm = "HMACSHA256";
                tsigSecretSecretRef = {
                  name = "${config.az.svc.rke2.nameserver.domains.${config.az.server.rke2.baseDomain}.id}-rfc2136-tsig";
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
