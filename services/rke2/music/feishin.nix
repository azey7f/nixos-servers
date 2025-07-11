{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
} @ args:
with lib; let
  cfg = config.az.svc.rke2.feishin;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.feishin = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.server.rke2.manifests."app-feishin" = [
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "feishin";
          namespace = "app-music";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "feishin";
          template.metadata.labels.app = "feishin";
          template.spec.containers = [
            {
              name = "feishin";
              image = "ghcr.io/jeffvli/feishin";
              env = lib.attrsets.mapAttrsToList (name: value: {inherit name value;}) {
                SERVER_LOCK = "true";
                SERVER_NAME = "navidrome";
                SERVER_TYPE = "navidrome";
                SERVER_URL = "https://navidrome.${domain}";
              };
            }
          ];
        };
      }

      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "feishin";
          namespace = "app-music";
        };
        spec = {
          selector.app = "feishin";
          # listens on 0.0.0.0:9180 by default, no way to change it seemingly - # TODO: make an issue
          ipFamilyPolicy = "SingleStack";
          ipFamilies = ["IPv4"];
          ports = [
            {
              name = "feishin";
              port = 9180;
              protocol = "TCP";
            }
          ];
        };
      }
    ];

    az.svc.rke2.envoyGateway.httpRoutes = [
      {
        name = "feishin";
        namespace = "app-music";
        hostnames = ["music.${domain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "feishin";
                port = 9180;
              }
            ];
          }
        ];
        customCSP.default-src = ["'self'" "data:" "blob:" "https://navidrome.${domain}"];
      }
    ];

    az.svc.rke2.authelia.rules = [
      {
        domain = ["music.${domain}"];
        policy = "bypass";
      }
    ];
  };
}
