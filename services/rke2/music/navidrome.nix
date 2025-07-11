{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.navidrome;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.navidrome = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.svc.rke2.music.enable = true;
    az.server.rke2.manifests."app-navidrome" = [
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "navidrome";
          namespace = "kube-system";
        };
        spec = {
          targetNamespace = "app-music";

          chart = "oci://tccr.io/truecharts/navidrome";

          valuesContent = builtins.toJSON {
            global.namespace = "app-music";
            workload.main.podSpec.containers.main.env.ND_SCANNER_SCHEDULE = "0"; # manual only

            persistence.data = {
              type = "pvc";
              size = "10Gi";
            };

            persistence.music = {
              type = "pvc";
              existingClaim = "music"; # see default.nix
            };

            service.main = {
              ipFamilyPolicy = "PreferDualStack";
              ipFamilies = ["IPv4" "IPv6"];
            };
          };
        };
      }
    ];

    az.svc.rke2.envoyGateway.httpRoutes = [
      {
        name = "navidrome";
        namespace = "app-music";
        hostnames = ["navidrome.${domain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "navidrome";
                port = 4533;
              }
            ];
          }
        ];
      }
    ];

    az.svc.rke2.authelia.rules = [
      {
        domain = ["navidrome.${domain}"];
        policy = "bypass";
      }
    ];
  };
}
