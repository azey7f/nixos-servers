{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.music.navidrome;
  domain = config.az.server.rke2.baseDomain;
  images = config.az.server.rke2.images;
in {
  options.az.svc.rke2.music.navidrome = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.svc.rke2.music.enable = true;

    az.server.rke2.images = {
      navidrome = {
        imageName = "deluan/navidrome";
        finalImageTag = "0.58.0";
        imageDigest = "sha256:2ae037d464de9f802d047165a13b1c9dc2bdbb14920a317ae4aef1233adc0a3c";
        hash = "sha256-gqHFoDTkXsy6glM8kizYdd/OTKnNWrKSXYG7o93JR34="; # renovate: deluan/navidrome 0.58.0
      };
    };
    services.rke2.manifests."music".content = [
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "navidrome-data";
          namespace = "app-music";
        };
        spec = {
          accessModes = ["ReadWriteOnce"];
          resources.requests.storage = "1Gi";
        };
      }

      {
        apiVersion = "apps/v1";
        kind = "StatefulSet";
        metadata = {
          name = "navidrome";
          namespace = "app-music";
        };
        spec = {
          selector.matchLabels.app = "navidrome";
          template.metadata.labels.app = "navidrome";
          serviceName = "navidrome";

          template.spec.securityContext = {
            runAsNonRoot = true;
            seccompProfile.type = "RuntimeDefault";
            runAsUser = 65534;
            runAsGroup = 65534;
            fsGroup = 65534;
          };

          template.spec.containers = [
            {
              name = "navidrome";
              image = images.navidrome.imageString;
              env = lib.attrsets.mapAttrsToList (name: value: {inherit name value;}) {
                ND_DATAFOLDER = "/data";
                ND_MUSICFOLDER = "/music";
                ND_SCANNER_SCHEDULE = "0"; # manual only

                ND_PORT = "80";
                ND_ENABLEINSIGHTSCOLLECTOR = "false"; # container has no internet access anyways

                ND_ENABLESHARING = "true";
                ND_DEFAULTSHAREEXPIRATION = "2557920h";
              };
              volumeMounts = [
                {
                  name = "navidrome-data";
                  mountPath = "/data";
                }
                {
                  name = "navidrome-music";
                  mountPath = "/music";
                  readOnly = true;
                }
              ];
              securityContext = {
                allowPrivilegeEscalation = false;
                capabilities.drop = ["ALL"];
              };
            }
          ];
          template.spec.volumes = [
            {
              name = "navidrome-data";
              persistentVolumeClaim.claimName = "navidrome-data";
            }
            {
              name = "navidrome-music";
              persistentVolumeClaim.claimName = "music"; # see ./default.nix
            }
          ];
        };
      }

      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "navidrome";
          namespace = "app-music";
        };
        spec = {
          selector.app = "navidrome";
          ipFamilyPolicy = "PreferDualStack";
          ipFamilies = ["IPv4" "IPv6"];
          ports = [
            {
              name = "http";
              port = 80;
              protocol = "TCP";
            }
          ];
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
                port = 80;
              }
            ];
          }
        ];
        # allow embedding
        responseHeaders.x-frame-options = null;
        customCSP.frame-ancestors = ["'self'" "https:"];
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
