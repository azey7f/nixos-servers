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

          template.spec.securityContext = {
            runAsNonRoot = true;
            seccompProfile.type = "RuntimeDefault";
            runAsUser = 65532;
            runAsGroup = 65532;
          };

          template.spec.containers = [
            {
              name = "nginx";
              image = "nginxinc/nginx-unprivileged";
              volumeMounts = [
                {
                  name = "nginx-cm";
                  mountPath = "/usr/share/nginx/html";
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
              port = 8080;
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
                port = 8080;
              }
            ];
          }
        ];
        csp = "strict";
      }
    ];

    az.svc.rke2.authelia.rules = [
      {
        domain = [config.az.server.rke2.baseDomain];
        methods = ["GET" "HEAD"];
        policy = "bypass";
      }
    ];
  };
}
