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
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.nginx = with azLib.opt; {
    enable = optBool false;
    repo = optStr "https://git.${domain}/infra/${domain}";
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
        data."default.conf" = ''
          server {
          	listen 8080 default_server;
          	listen [::]:8080 default_server;

          	root /srv/current/static;

          	index ________________none;

          	rewrite ^(?<path>.*)/__autoindex\.json$	$path/			last;
          	rewrite ^(?<path>.*)/$			$path/index.html	last;

          	autoindex on;
          	autoindex_exact_size on;
          	autoindex_format json;

          	location / {
          		limit_except GET HEAD OPTIONS {
          			deny all;
          		}
          	}
          }
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
            fsGroup = 65532;
          };

          template.spec.containers = [
            {
              name = "git-sync";
              image = "registry.k8s.io/git-sync/git-sync:v4.4.2"; # TODO: is there any way to use latest?
              args = [
                "--repo=${cfg.repo}"
                "--depth=1"
                "--period=300s"
                "--link=current"
                "--root=/srv"
              ];
              volumeMounts = [
                {
                  name = "nginx-srv";
                  mountPath = "/srv";
                }
                {
                  name = "nginx-cm";
                  mountPath = "/etc/nginx/conf.d";
                }
              ];
              securityContext = {
                allowPrivilegeEscalation = false;
                capabilities.drop = ["ALL"];
              };
            }
            {
              name = "nginx";
              image = "nginxinc/nginx-unprivileged";
              volumeMounts = [
                {
                  name = "nginx-srv";
                  mountPath = "/srv";
                  readOnly = true;
                }
                {
                  name = "nginx-cm";
                  mountPath = "/etc/nginx/conf.d";
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
                    key = "default.conf";
                    path = "default.conf";
                  }
                ];
              };
            }
            {
              name = "nginx-srv";
              emptyDir = {};
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
        customCSP = {
          worker-src = ["'self'" "blob:"];
          script-src = ["'self'" "blob:"];
          style-src = ["'self'" "'unsafe-inline'"]; # CSS in JS on a static page, there shouldn't be any XSS attack vectors anyways
        };
        responseHeaders.x-robots-tag = "all";
      }
    ];

    az.svc.rke2.authelia.rules = [
      {
        domain = ["${domain}"];
        methods = ["GET" "HEAD" "OPTIONS"];
        policy = "bypass";
      }
    ];
  };
}
