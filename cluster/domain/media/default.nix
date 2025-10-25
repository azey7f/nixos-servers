{
  config,
  lib,
  azLib,
  ...
}: let
  domains = lib.filterAttrs (_: v: v.enable) config.az.cluster.domainSpecific.media;
  images = config.az.server.rke2.images;
in {
  imports = azLib.scanPath ./.;

  options.az.cluster.domainSpecific.media = lib.mkOption {
    type = with lib.types;
      attrsOf (submodule {
        options = with azLib.opt; {
          enable = optBool false;
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
          lib.nameValuePair "app-media-${id}" {
            networkPolicy.fromNamespaces = ["envoy-gateway"];
          }
      )
      domains;

    services.rke2.manifests."10-media".content =
      lib.mapAttrsToList (
        domain: cfg: let
          id = builtins.replaceStrings ["."] ["-"] domain;
        in {
          apiVersion = "v1";
          kind = "PersistentVolumeClaim";
          metadata = {
            name = "media";
            namespace = "app-media-${id}";
          };
          spec = {
            accessModes = ["ReadWriteOnce"];
            resources.requests.storage = "10Ti"; # media be big
          };
        }
      )
      domains;
  };
}
