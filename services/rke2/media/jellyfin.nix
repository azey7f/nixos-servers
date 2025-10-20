{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.media.jellyfin;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.media.jellyfin = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.svc.rke2.media.enable = true;

    services.rke2.autoDeployCharts."jellyfin" = {
      targetNamespace = "app-media";

      repo = "https://jellyfin.github.io/jellyfin-helm";
      name = "jellyfin";
      version = "2.4.0";
      hash = "sha256-bRvEoIGeTXQRzC5FGpj5q/1jGnMnwNLrBVLynNRSxNY="; # renovate: https://jellyfin.github.io/jellyfin-helm jellyfin 2.4.0

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
          # listens on 0.0.0.0 by default, can only be changed imperatively - https://github.com/jellyfin/jellyfin/issues/13930
          # hhhhhhhhgtdhfph why is it so hard for software to just bind to :: by default.
          ipFamilyPolicy = "SingleStack";
          ipFamilies = ["IPv4"];
        };
        persistence.media.existingClaim = "media";
      };
    };

    az.svc.rke2.envoyGateway.httpRoutes = [
      {
        name = "jellyfin";
        namespace = "app-media";
        hostnames = ["jellyfin.${domain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "jellyfin";
                port = 8096;
              }
            ];
          }
        ];
      }
    ];

    az.svc.rke2.authelia.rules = [
      {
        domain = ["jellyfin.${domain}"];
        subject = "group:admin";
        policy = "two_factor";
      }
    ];
  };
}
