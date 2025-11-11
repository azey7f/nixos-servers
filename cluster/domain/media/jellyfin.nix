{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  domains = lib.filterAttrs (_: v: v.enable) config.az.cluster.domainSpecific.jellyfin;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.domainSpecific.jellyfin = lib.mkOption {
    type = with lib.types;
      attrsOf (submodule {
        options = with azLib.opt; {
          enable = optBool false;
        };
      });
    default = {};
  };

  config = lib.mkIf (domains != {}) {
    az.cluster.domainSpecific.media =
      builtins.mapAttrs (domain: cfg: {
        enable = true;
      })
      domains;

    services.rke2.autoDeployCharts = lib.mapAttrs' (domain: cfg: let
      id = builtins.replaceStrings ["."] ["-"] domain;
    in
      lib.nameValuePair "jellyfin-${id}" {
        targetNamespace = "app-media-${id}";

        repo = "https://jellyfin.github.io/jellyfin-helm";
        name = "jellyfin";
        version = "2.5.0";
        hash = "sha256-GzyLqPAXGQTVICEeq9RnWs9IF4ceqp9WZR3XLgEEsPU="; # renovate: https://jellyfin.github.io/jellyfin-helm jellyfin 2.5.0

        values = {
          podSecurityContext = {fsGroup = 65534;};
          securityContext = {
            privileged = false;
            allowPrivilegeEscalation = false;
            capabilities.drop = ["ALL"];
            runAsUser = 65534;
            runAsGroup = 65534;
            runAsNonRoot = true;
            fsGroup = 65534;
            seccompProfile.type = "RuntimeDefault";
          };

          service = {
            # NOTE: listens on 0.0.0.0 by default, can only be changed imperatively - https://github.com/jellyfin/jellyfin/issues/13930
            # hhhhhhhhgtdhfph why is it so hard for software to just bind to :: by default.
            ipFamilyPolicy = "SingleStack";
            ipFamilies = ["IPv6"]; # rTODO
          };
          persistence.media.existingClaim = "media";
        };
      })
    domains;

    az.cluster.core.envoyGateway.httpRoutes =
      lib.mapAttrsToList (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in {
        name = "jellyfin";
        namespace = "app-media-${id}";
        hostnames = ["jellyfin.${domain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "jellyfin-${id}";
                port = 8096;
              }
            ];
          }
        ];
      })
      domains;

    az.cluster.core.auth.authelia.rules =
      lib.mapAttrsToList (domain: cfg: {
        domain = ["jellyfin.${domain}"];
        subject = "group:admin";
        policy = "two_factor";
      })
      domains;
  };
}
