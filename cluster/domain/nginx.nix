{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  domains = lib.filterAttrs (_: v: v.enable) config.az.cluster.domainSpecific.nginx;
  images = config.az.server.rke2.images;
  mkFQDN = sub: domain: "${lib.optionalString (sub != "root") "${sub}."}${domain}";
in {
  options.az.cluster.domainSpecific.nginx = lib.mkOption {
    type = with lib.types;
      attrsOf (submodule ({name, ...}: let
        id = builtins.replaceStrings ["."] ["-"] name;
      in {
        options = with azLib.opt; {
          enable = optBool false;

          # sites by subdomain, e.g. "www"
          # "root" is a special value that means the root site
          sites = lib.mkOption {
            type = attrsOf (submodule {
              options = {
                forge = optStr "http://forgejo-${id}-http.app-forgejo-${id}.svc:3000/";
                repo = lib.mkOption {
                  type = lib.types.str;
                  # must be set
                };

                path = optStr ""; # path inside the repo
                index = optStr "index.html";

                nginxExtraConfig = lib.mkOption {
                  # extra nginx config
                  type = lib.types.lines;
                  default = "";
                };
                envoyExtraConfig = lib.mkOption {
                  type = attrsOf anything;
                  default = {};
                };
              };
            });
            default = {};
          };
        };
      }));
    default = {};
  };

  config = lib.mkIf (domains != {}) {
    az.server.rke2.namespaces =
      {
        "app-nginx" = {
          networkPolicy.fromNamespaces = ["envoy-gateway"];
          networkPolicy.toNamespaces = lib.mapAttrsToList (domain: cfg: "app-forgejo-${builtins.replaceStrings ["."] ["-"] domain}") domains; # source code fetching
        };
      }
      // lib.mapAttrs' (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in
        lib.nameValuePair "app-forgejo-${id}" {
          networkPolicy.fromNamespaces = ["app-nginx"];
        })
      domains;

    az.server.rke2.images = {
      git-sync = {
        imageName = "registry.k8s.io/git-sync/git-sync";
        finalImageTag = "v4.5.0";
        imageDigest = "sha256:0e64aedb0d0ae0a3bab880349a5109b2a31891d646dd61e433ca36ed220dff1f";
        hash = "sha256-G4vi0NiCPc4+AyvY1S5Wf3tCBq2u9V+AhVwgvZTFIZ0="; # renovate: registry.k8s.io/git-sync/git-sync v4.5.0
      };
      nginx = {
        imageName = "nginxinc/nginx-unprivileged";
        finalImageTag = "1.29";
        imageDigest = "sha256:5faa8648305e93ff7b562a7a576d9f8ef8f5ed78d9c28765bb6551fe461f2606";
        hash = "sha256-EFyOgYFa7mloFEu2vnJlSv3PRDIUHqEEJUADDvxHj/U="; # renovate: nginxinc/nginx-unprivileged 1.29
      };
    };
    services.rke2.manifests."nginx".content = [
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "nginx-cm";
          namespace = "app-nginx";
        };
        data =
          lib.mapAttrs' (domain: cfg: {
            name = "${domain}.conf";
            value = lib.concatStringsSep "\n\n" (
              lib.mapAttrsToList (sub: site: ''
                server {
                	listen 8080;
                	listen [::]:8080;
                	server_name ${mkFQDN sub domain};

                	root /srv/${sub}/current${site.path};
                	index ${site.index};
                ${builtins.replaceStrings ["\n"] ["\n\t"] site.nginxExtraConfig}
                }
              '')
              cfg.sites
            );
          })
          domains;
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

          template.spec.containers =
            lib.flatten (
              lib.mapAttrsToList (domain: cfg: (
                lib.mapAttrsToList (sub: site: {
                  name = "git-sync-${sub}";
                  image = images.git-sync.imageString;
                  args = [
                    "--repo=${site.forge}${site.repo}"
                    "--depth=1"
                    "--period=300s"
                    "--link=current"
                    "--root=/srv"
                  ];
                  volumeMounts = [
                    {
                      name = "nginx-srv";
                      mountPath = "/srv";
                      subPath = sub;
                    }
                  ];
                  securityContext = {
                    allowPrivilegeEscalation = false;
                    capabilities.drop = ["ALL"];
                  };
                })
                cfg.sites
              ))
              domains
            )
            ++ [
              {
                name = "nginx";
                image = images.nginx.imageString;
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
                items =
                  lib.mapAttrsToList (domain: cfg: {
                    key = "${domain}.conf";
                    path = "${domain}.conf";
                  })
                  domains;
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

    az.cluster.core.envoyGateway.httpRoutes = lib.flatten (
      lib.mapAttrsToList (domain: cfg: (
        lib.mapAttrsToList (
          sub: site:
            {
              name = "nginx";
              namespace = "app-nginx";
              hostnames = [(mkFQDN sub domain)];
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
            }
            // site.envoyExtraConfig
        )
        cfg.sites
      ))
      domains
    );

    az.cluster.core.auth.authelia.rules = [
      {
        domain = lib.flatten (
          lib.mapAttrsToList (domain: cfg: (
            lib.mapAttrsToList (sub: site: mkFQDN sub domain) cfg.sites
          ))
          domains
        );
        methods = ["GET" "HEAD" "OPTIONS"];
        policy = "bypass";
      }
    ];
  };
}
