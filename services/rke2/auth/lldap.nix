# TODO: OIDC
{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.lldap;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.lldap = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.svc.rke2.cnpg.enable = true;
    az.server.rke2.manifests."app-lldap" = [
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "lldap";
          namespace = "kube-system";
        };
        spec = {
          targetNamespace = "app-lldap";
          createNamespace = true;

          chart = "oci://tccr.io/truecharts/lldap";

          valuesContent = builtins.toJSON {
            service.main = {
              ports.main.port = 80;
              #ipFamilyPolicy = "PreferDualStack"; # for some reason the webUI doesn't really work w/ dual stack
              #ipFamilies = ["IPv4" "IPv6"];
            };
            service.ldap = {
              enabled = true;
              ports.ldap = {
                enabled = true;
                port = 389;
              };
              ipFamilyPolicy = "PreferDualStack";
              ipFamilies = ["IPv4" "IPv6"];
            };

            persistence.data = {
              type = "pvc";
              size = "1Gi";
            };
            workload.main.podSpec.containers.main.env = let
              split = lib.strings.splitString "." domain;
            in {
              LLDAP_HTTP_URL = "https://lldap.${domain}";
              LLDAP_LDAP_BASE_DN = lib.strings.concatMapStringsSep "," (n: "dc=${n}") split;
            };
          };
        };
      }
    ];

    az.svc.rke2.envoyGateway.httpRoutes = [
      {
        name = "lldap";
        namespace = "app-lldap";
        hostnames = ["lldap.${domain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "lldap";
                port = 80;
              }
            ];
          }
        ];
      }
    ];

    az.svc.rke2.authelia.rules = [
      {
        domain = ["lldap.${domain}"];
        subject = "group:admin";
        policy = "two_factor";
      }
    ];
  };
}
