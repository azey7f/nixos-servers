{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}: let
  domains = lib.filterAttrs (_: v: v.enable) config.az.cluster.domainSpecific.feishin;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.domainSpecific.feishin = lib.mkOption {
    type = with lib.types;
      attrsOf (submodule {
        options = with azLib.opt; {
          enable = optBool false;
        };
      });
    default = {};
  };

  config = lib.mkIf (domains != {}) {
    az.server.rke2.namespaces."app-feishin" = {
      networkPolicy.fromNamespaces = ["envoy-gateway"];
    };

    az.server.rke2.images = {
      feishin = {
        imageName = "ghcr.io/jeffvli/feishin";
        finalImageTag = "1.2.0";
        imageDigest = "sha256:ac74207b4fb49c4b8c84234f4a593b1320e461602eface311050094956bdbc78";
        hash = "sha256-4aBI/UzoRTjqbUSQsknMe5rDzaj8ez0aAYJsxNLm/HQ="; # renovate: ghcr.io/jeffvli/feishin 1.2.0
      };
    };
    services.rke2.manifests."feishin".content = lib.flatten (lib.mapAttrsToList (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in [
        {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            name = "feishin-${id}";
            namespace = "app-feishin";
          };
          spec = {
            replicas = 1;
            selector.matchLabels.app = "feishin-${id}";
            template.metadata.labels.app = "feishin-${id}";

            template.spec.securityContext = {
              runAsNonRoot = true;
              seccompProfile.type = "RuntimeDefault";
              runAsUser = 65534;
              runAsGroup = 65534;
            };

            template.spec.containers = [
              {
                name = "feishin";
                image = images.feishin.imageString;
                env = lib.attrsToList {
                  SERVER_NAME = "navidrome";
                  SERVER_TYPE = "navidrome";
                  SERVER_URL = "https://navidrome.${domain}";
                  SERVER_LOCK = "true";
                };
                securityContext = {
                  allowPrivilegeEscalation = false;
                  capabilities.drop = ["ALL"];
                };
                volumeMounts = [
                  {
                    name = "nginx-cache";
                    mountPath = "/var/cache/nginx";
                  }
                  {
                    name = "run";
                    mountPath = "/run";
                  }
                ];
              }
            ];
            template.spec.volumes = [
              {
                name = "nginx-cache";
                emptyDir.sizeLimit = "100Mi";
              }
              {
                name = "run";
                emptyDir.sizeLimit = "100Mi";
              }
            ];
          };
        }

        {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            name = "feishin-${id}";
            namespace = "app-feishin";
          };
          spec = {
            selector.app = "feishin-${id}";
            ipFamilyPolicy = "SingleStack";
            ipFamilies = ["IPv6"];
            ports = [
              {
                name = "feishin";
                port = 80;
                protocol = "TCP";
              }
            ];
          };
        }
      ])
      domains);

    az.cluster.core.envoyGateway.httpRoutes =
      lib.mapAttrsToList (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in {
        name = "feishin-${id}";
        namespace = "app-feishin";
        hostnames = ["music.${domain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "feishin-${id}";
                port = 80;
              }
            ];
          }
        ];
        customCSP.default-src = ["'self'" "data:" "blob:" "https://navidrome.${domain}"];
      })
      domains;

    az.cluster.core.auth.authelia.rules = [
      {
        domain = lib.mapAttrsToList (domain: cfg: "music.${domain}") domains;
        policy = "bypass";
      }
    ];
  };
}
