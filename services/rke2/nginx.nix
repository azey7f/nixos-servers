{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.nginx;
in {
  options.az.svc.rke2.nginx = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.server.rke2.manifests."app-nginx" = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "app-nginx";
        metadata.labels.name = "app-nginx";
      }
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "nginx-cm";
          namespace = "app-nginx";
        };
        data."index.html" = ''
          <h2>temp test site</h2>
          :3
        '';
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "nginx";
          namespace = "app-nginx";
        };
        spec = {
          selector.matchLabels.app = "nginx";
          template.metadata.labels.app = "nginx";

          template.spec.containers = [
            {
              name = "nginx";
              image = "nginx";
              volumeMounts = [
                {
                  name = "nginx-cm";
                  mountPath = "/usr/share/nginx/html";
                }
              ];
            }
          ];

          template.spec.volumes = [
            {
              name = "nginx-cm";
              configMap = {
                name = "nginx-cm";
                items = [
                  {
                    key = "index.html";
                    path = "index.html";
                  }
                ];
              };
            }
          ];
        };
      }

      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "nginx";
          namespace = "app-nginx";
        };
        spec = {
          selector.app = "nginx";
          ipFamilyPolicy = "PreferDualStack";
          ipFamilies = ["IPv4" "IPv6"];
          ports = [
            {
              name = "nginx";
              port = 80;
              protocol = "TCP";
            }
          ];
        };
      }
    ];

    az.svc.rke2.envoyGateway.httpRoutes = [
      {
        name = "nginx";
        namespace = "app-nginx";
        hostnames = ["${config.az.server.rke2.baseDomain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "nginx";
                port = 80;
              }
            ];
          }
        ];
        csp = "strict";
      }
    ];
  };
}
