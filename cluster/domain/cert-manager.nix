{
  config,
  lib,
  azLib,
  ...
}: let
  domains = config.az.cluster.domainSpecific.certManager;
  nsConfig = config.az.cluster.core.nameserver;
in {
  options.az.cluster.domainSpecific.certManager = lib.mkOption {
    type = with lib.types;
      attrsOf (submodule {
        options = with azLib.opt; {
          issuer = lib.mkOption {
	    type = with lib.types; enum ["letsencrypt" "selfsigned"];
	    # must be set
	  };
        };
      });
    default = {};
  };

  config = lib.mkIf (domains != {}) {
    az.server.rke2.namespaces."cert-manager" = {
      networkPolicy.fromNamespaces = ["metrics-system"];
      networkPolicy.toNamespaces = ["app-nameserver"];
      networkPolicy.toWAN = true; # acme-v02.api.letsencrypt.org
      networkPolicy.toCluster = true; # apiserver
      networkPolicy.toPorts = {
        # DNS01
        tcp = [53];
        udp = [53];
      };
    };
    az.server.rke2.namespaces."app-nameserver".networkPolicy.fromNamespaces = ["cert-manager"];

    services.rke2.autoDeployCharts."cert-manager" = {
      repo = "https://charts.jetstack.io";
      name = "cert-manager";
      version = "v1.19.1";
      hash = "sha256-9ypyexdJ3zUh56Za9fGFBfk7Vy11iEGJAnCxUDRLK0E="; # renovate: https://charts.jetstack.io cert-manager v1.19.1

      targetNamespace = "cert-manager";
      values = {
        crds.enabled = true;
        config.enableGatewayAPI = true;
        extraArgs = [
          # use local NS directly
          "--dns01-recursive-nameservers-only"
          "--dns01-recursive-nameservers=knot.app-nameserver.svc:53"
        ];

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
                  then throw "letsencrypt issuer enabled on domain not managed by local nameserver"
                  else [
                    "*.${domain}"
                    "${domain}"
                  ])
                (lib.filterAttrs (_: d: d.issuer == "letsencrypt") domains));

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
        {
          apiVersion = "cert-manager.io/v1";
          kind = "ClusterIssuer";
          metadata = {
	    # used for sites that can't easily get valid TLS certs
	    # e.g. .arpa rDNS zones
            name = "selfsigned-issuer";
            namespace = "cert-manager";
          };
          spec.selfSigned = {};
        }
      ];
    };
  };
}
