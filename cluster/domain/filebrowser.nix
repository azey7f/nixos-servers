{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  domains = lib.filterAttrs (_: v: v.enable) config.az.cluster.domainSpecific.filebrowser;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.domainSpecific.filebrowser = lib.mkOption {
    type = with lib.types;
      attrsOf (submodule {
        options = with azLib.opt; {
          enable = optBool false;
	  storage = optStr "100Gi";
        };
      });
    default = {};
  };

  config = lib.mkIf (domains != {}) {
     az.server.rke2.namespaces =
      lib.mapAttrs' (
        domain: cfg: let
          id = builtins.replaceStrings ["."] ["-"] domain;
        in
          lib.nameValuePair "app-filebrowser-${id}" {
            networkPolicy.fromNamespaces = ["envoy-gateway"];
          }
      )
      domains;

    az.server.rke2.images = {
      filebrowser = {
        imageName = "filebrowser/filebrowser";
        finalImageTag = "v2.52.0";
        imageDigest = "sha256:363c1eae79e7c08bbb994c3511875cbcb65e70df9ac850221d60400c362f4ff9";
        hash = "sha256-6DSIl3Xo0A8IZW7myjBuMltUS2c4K0HY7y6JkaNOTBo="; # renovate: filebrowser/filebrowser v2.52.0
      };
    };

    services.rke2.manifests."filebrowser".content = lib.flatten (
      lib.mapAttrsToList (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in [
      {
          apiVersion = "v1";
          kind = "PersistentVolumeClaim";
          metadata = {
            name = "files";
            namespace = "app-filebrowser-${id}";
          };
          spec = {
            accessModes = ["ReadWriteOnce"];
            resources.requests.storage = cfg.storage;
          };
        }
      {
          apiVersion = "v1";
          kind = "PersistentVolumeClaim";
          metadata = {
            name = "filebrowser-db";
            namespace = "app-filebrowser-${id}";
          };
          spec = {
            accessModes = ["ReadWriteOnce"];
            resources.requests.storage = "1Gi";
          };
        }
      {
          apiVersion = "v1";
          kind = "PersistentVolumeClaim";
          metadata = {
            name = "filebrowser-config";
            namespace = "app-filebrowser-${id}";
          };
          spec = {
            accessModes = ["ReadWriteOnce"];
            resources.requests.storage = "10Mi";
          };
        }

        {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            name = "filebrowser-${id}";
            namespace = "app-filebrowser-${id}";
          };
          spec = {
            selector.matchLabels.app = "filebrowser-${id}";
            template.metadata.labels.app = "filebrowser-${id}";

            template.spec.securityContext = {
              runAsNonRoot = true;
              seccompProfile.type = "RuntimeDefault";
              runAsUser = 65534;
              runAsGroup = 65534;
              fsGroup = 65534;
            };

            template.spec.containers = [
              {
                name = "filebrowser";
                image = images.filebrowser.imageString;
                volumeMounts = [
                  {
                    name = "files";
                    mountPath = "/srv";
                  }
                  {
                    name = "filebrowser-db";
                    mountPath = "/database";
                  }
                  {
                    name = "filebrowser-config";
                    mountPath = "/config";
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
                name = "files";
                persistentVolumeClaim.claimName = "files";
              }
              {
                name = "filebrowser-config";
                persistentVolumeClaim.claimName = "filebrowser-config";
              }
              {
                name = "filebrowser-db";
                persistentVolumeClaim.claimName = "filebrowser-db";
              }
            ];
          };
        }

        {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            name = "filebrowser-${id}";
            namespace = "app-filebrowser-${id}";
          };
          spec = {
            selector.app = "filebrowser-${id}";
            ipFamilyPolicy = "SingleStack";
            ipFamilies = ["IPv6"];
            ports = [
              {
                name = "filebrowser";
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
          name = "filebrowser-${id}";
          namespace = "app-filebrowser-${id}";
          hostnames = ["files.${domain}"];
          rules = [
            {
              backendRefs = [
                {
                  name = "filebrowser-${id}";
                  port = 80;
                }
              ];
            }
          ];
          csp = "lax";
        }
      )
      domains;

    az.cluster.core.auth.authelia.rules =
      lib.mapAttrsToList (
        domain: cfg: let
          id = builtins.replaceStrings ["."] ["-"] domain;
        in {
          domain = ["files.${domain}"];
	  subject = "group:admin";
          policy = "two_factor";
        }
      )
      domains;
  };
}
