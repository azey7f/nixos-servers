{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  domains = lib.filterAttrs (_: v: v.enable) config.az.cluster.domainSpecific.navidrome;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.domainSpecific.navidrome = lib.mkOption {
    type = with lib.types;
      attrsOf (submodule {
        options = with azLib.opt; {
          enable = optBool false;
        };
      });
    default = {};
  };

  config = lib.mkIf (domains != {}) {
    az.cluster.domainSpecific.music =
      builtins.mapAttrs (domain: cfg: {
        enable = true;
      })
      domains;

    az.server.rke2.images = {
      navidrome = {
        imageName = "deluan/navidrome";
        finalImageTag = "0.58.0";
        imageDigest = "sha256:2ae037d464de9f802d047165a13b1c9dc2bdbb14920a317ae4aef1233adc0a3c";
        hash = "sha256-gqHFoDTkXsy6glM8kizYdd/OTKnNWrKSXYG7o93JR34="; # renovate: deluan/navidrome 0.58.0
      };
    };
    services.rke2.manifests."navidrome".content = lib.flatten (
      lib.mapAttrsToList (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in [
        {
          apiVersion = "v1";
          kind = "PersistentVolumeClaim";
          metadata = {
            name = "navidrome-data";
            namespace = "app-music-${id}";
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
            namespace = "app-music-${id}";
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
              fsGroupChangePolicy = "OnRootMismatch"; # don't need to check all 100k files every mount
            };

            template.spec.containers = [
              {
                name = "navidrome";
                image = images.navidrome.imageString;
                env = lib.attrsToList {
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
            namespace = "app-music-${id}";
          };
          spec = {
            selector.app = "navidrome";
            ipFamilyPolicy = "SingleStack";
            ipFamilies = ["IPv6"];
            ports = [
              {
                name = "http";
                port = 80;
                protocol = "TCP";
              }
            ];
          };
        }
      ])
      domains
    );

    az.cluster.core.envoyGateway.httpRoutes =
      lib.mapAttrsToList (
        domain: cfg: let
          id = builtins.replaceStrings ["."] ["-"] domain;
        in {
          name = "navidrome";
          namespace = "app-music-${id}";
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
      )
      domains;

    az.cluster.core.auth.authelia.rules = [
      {
        domain = lib.mapAttrsToList (domain: cfg: "navidrome.${domain}") domains;
        policy = "bypass";
      }
    ];
  };
}
