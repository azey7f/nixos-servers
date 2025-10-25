{
  config,
  lib,
  azLib,
  ...
}: let
  domains = lib.filterAttrs (_: v: v.enable) config.az.cluster.domainSpecific.certManager;
  nsConfig = config.az.cluster.core.nameserver.external;
in {
  options.az.cluster.domainSpecific.certManager = lib.mkOption {
    type = with lib.types;
      attrsOf (submodule {
        options = with azLib.opt; {
          enable = optBool false;
        };
      });
    default = {};
  };

  config = lib.mkIf (domains != {}) {
    az.server.rke2.namespaces."cert-manager" = {
      networkPolicy.fromNamespaces = ["metrics-system"];
      networkPolicy.toDomains = ["acme-v02.api.letsencrypt.org"];
      networkPolicy.extraEgress = [
        {toEntities = ["kube-apiserver"];}
        {toPorts = [{ports = [{port = "53";}];}];} # DNS01
      ];
    };

    services.rke2.autoDeployCharts."cert-manager" = {
      repo = "https://charts.jetstack.io";
      name = "cert-manager";
      version = "v1.19.0";
      hash = "sha256-tYFjQGkVH86Ac9DgjUVOcS2vf5v7nfALNdX9y6AZNrg="; # renovate: https://charts.jetstack.io cert-manager v1.19.0

      targetNamespace = "cert-manager";
      values = {
        crds.enabled = true;
        config.enableGatewayAPI = true;

        prometheus = lib.optionalAttrs config.az.cluster.core.metrics.enable {
          enabled = true;
          servicemonitor.enabled = true;
          servicemonitor.labels.release = "metrics";
        };
      };

      extraDeploy = [
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

            email = config.az.cluster.contactMail;
            privateKeySecretRef.name = "letsencrypt-certkey";

            solvers = [
              {
                selector.dnsNames = lib.flatten (lib.mapAttrsToList (domain: _:
                  if !nsConfig.enable || !(builtins.elem domain nsConfig.zones)
                  then throw "certManager enabled on domain not managed by local nameserver"
                  else [
                    "*.${domain}"
                    "${domain}"
                  ])
                domains);

                dns01.rfc2136 = {
                  nameserver = "knot-external.app-nameserver.svc";
                  tsigKeyName = "acme";
                  tsigAlgorithm = "HMACSHA256";
                  tsigSecretSecretRef = {
                    name = "external-rfc2136-tsig";
                    key = "secret";
                  };
                };
              }
            ];
          };
        }
      ];
    };
  };
}
