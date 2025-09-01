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
    repos = {
      root = optStr "https://git.${domain}/infra/${domain}"; # TODO: https://ogp.me, also put this TODO in the site's repo
      miku = optStr "https://git.${domain}/mirrors/ooo.eeeee.ooo"; # im thinking miku miku oo eee oo
    };
  };

  config = mkIf cfg.enable {
    az.server.rke2.namespaces."app-nginx" = {
      networkPolicy.fromNamespaces = ["envoy-gateway"];
      networkPolicy.toDomains = ["git.${domain}"]; # source code fetching
    };
    az.server.rke2.manifests."app-nginx" = [
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

          	root /srv/root/current/static;

          	index ________________none;
          	rewrite ^(?<path>.*)/__autoindex\.json$	$path/			last;
          	rewrite ^(?<path>.*)/$			$path/index.html	last;

          	autoindex on;
          	autoindex_exact_size on;
          	autoindex_format json;
          }

          server {
          	listen 8080;
          	listen [::]:8080;
          	server_name miku.${domain};

          	root /srv/miku/current;
          	index index.html;
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
            runAsUser = 65534;
            runAsGroup = 65534;
            fsGroup = 65534;
          };

          template.spec.containers = let
            syncContainer = dir: repo: {
              name = "git-sync-${dir}";
              image = "registry.k8s.io/git-sync/git-sync:v4.4.3";
              args = [
                "--repo=${repo}"
                "--depth=1"
                "--period=300s"
                "--link=current"
                "--root=/srv/${dir}"
              ];
              volumeMounts = [
                {
                  name = "nginx-srv";
                  mountPath = "/srv";
                }
              ];
              securityContext = {
                allowPrivilegeEscalation = false;
                capabilities.drop = ["ALL"];
              };
            };
          in [
            (syncContainer "root" cfg.repos.root)
            (syncContainer "miku" cfg.repos.miku)
            {
              name = "nginx";
              image = "nginxinc/nginx-unprivileged:1.29";
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
        hostnames = ["${domain}"];
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
      {
        name = "nginx-miku";
        namespace = "app-nginx";
        hostnames = ["miku.${domain}"];
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
        csp = "lax";
      }
    ];

    az.svc.rke2.authelia.rules = [
      {
        domain = ["miku.${domain}" "${domain}"];
        methods = ["GET" "HEAD" "OPTIONS"];
        policy = "bypass";
      }
    ];
  };
}
