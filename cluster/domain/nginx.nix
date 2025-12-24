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
      attrsOf (submodule ({name, ...}: {
        options = with azLib.opt; {
          enable = optBool false;

          extraNetworkPolicy = lib.mkOption {
            # for cluster-external forges
            type = with lib.types; attrsOf anything;
            default = {};
          };

          # sites by subdomain, e.g. "www"
          # "root" is a special value that means the root site
          sites = lib.mkOption {
            type = attrsOf (submodule ({config, ...}: {
              options = {
                git = {
                  enable = optBool true; # if false, default config is empty

                  forgeDomain = lib.mkOption {
                    # if null, forge is not within cluster & should be set explicitly
                    type = with lib.types; nullOr str;
                    default = name;
                  };
                  forge = let
                    id = builtins.replaceStrings ["."] ["-"] config.git.forgeDomain;
                  in
                    optStr "http://forgejo-${id}-http.app-forgejo-${id}.svc:3000/";

                  repo = lib.mkOption {
                    type = lib.types.str;
                    # must be set
                  };

                  path = optStr ""; # path inside the repo
                };

                index = optStr "index.html";
                content = lib.mkOption {
                  # raw strings to serve
                  type = with lib.types; attrsOf str;
                  default = {};
                };

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
            }));
            default = {};
          };
        };
      }));
    default = {};
  };

  config = lib.mkIf (domains != {}) {
    az.server.rke2.namespaces = let
      namespaces = lib.uniqueStrings (
        lib.concatMap (cfg: (
          builtins.map (site: "app-forgejo-${builtins.replaceStrings ["."] ["-"] site.git.forgeDomain}") (
            builtins.filter (site: site.git.enable && site.git.forgeDomain != null) (builtins.attrValues cfg.sites)
          )
        ))
        (builtins.attrValues domains)
      );
    in
      {
        "app-nginx" = lib.mkMerge ([
            {
              networkPolicy.fromNamespaces = ["envoy-gateway"];
              # source code fetching
              networkPolicy.toNamespaces = namespaces;
            }
          ]
          ++ builtins.map (cfg: {networkPolicy = cfg.extraNetworkPolicy;}) (builtins.attrValues domains));
      }
      // lib.listToAttrs (builtins.map (ns: (
          lib.nameValuePair ns {networkPolicy.fromNamespaces = ["app-nginx"];}
        ))
        namespaces);

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
        imageDigest = "sha256:602df0414a225625456b690e4f4f81e0fc088abcb6b15d986745b0f1c32c9759";
        hash = "sha256-1V0Z7/wKEXufNq9JEvH9UzR1BkymRmxoWxDdGa+Talk="; # renovate: nginxinc/nginx-unprivileged 1.29
      };
    };
    services.rke2.manifests."nginx".content = let
      contentCMs = lib.flatten (
        lib.mapAttrsToList (domain: cfg:
          lib.mapAttrsToList (sub: site:
            if site.content != {}
            then
              if site.git.enable
              then throw "nginx: ${domain}: ${sub}: git.enable and content can't be set at the same time"
              else {
                apiVersion = "v1";
                kind = "ConfigMap";
                metadata = {
                  name = "nginx-content-${builtins.replaceStrings ["."] ["-"] (mkFQDN sub domain)}";
                  namespace = "app-nginx";
                };
                data = site.content;
              }
            else [])
          cfg.sites)
        domains
      );
    in
      contentCMs
      ++ [
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

                  ${
                    if site.git.enable
                    then ''
                      root /srv/git/${sub}/current${site.git.path};
                      index ${site.index};
                    ''
                    else if site.content != {}
                    then ''
                      root /srv/raw/nginx-content-${builtins.replaceStrings ["."] ["-"] (mkFQDN sub domain)};
                      index ${site.index};
                    ''
                    else ""
                  }
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
                  lib.mapAttrsToList (sub: site:
                    lib.optional (site.git.enable) {
                      name = "git-sync-${sub}";
                      image = images.git-sync.imageString;
                      args = [
                        "--repo=${site.git.forge}${site.git.repo}"
                        "--depth=1"
                        "--period=300s"
                        "--link=current"
                        "--root=/srv/git"
                      ];
                      volumeMounts = [
                        {
                          name = "nginx-git";
                          mountPath = "/srv/git";
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
                  volumeMounts =
                    [
                      {
                        name = "nginx-git";
                        mountPath = "/srv/git";
                        readOnly = true;
                      }
                      {
                        name = "nginx-cm";
                        mountPath = "/etc/nginx/conf.d";
                      }
                    ]
                    ++ builtins.map (cm: {
                      name = cm.metadata.name;
                      mountPath = "/srv/raw/${cm.metadata.name}";
                      readOnly = true;
                    })
                    contentCMs;
                  securityContext = {
                    allowPrivilegeEscalation = false;
                    capabilities.drop = ["ALL"];
                  };
                }
              ];

            template.spec.volumes =
              [
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
                  name = "nginx-git";
                  emptyDir = {};
                }
              ]
              ++ builtins.map (cm: {
                name = cm.metadata.name;
                configMap = {
                  name = cm.metadata.name;
                  items =
                    lib.mapAttrsToList (file: _: {
                      key = file;
                      path = file;
                    })
                    cm.data;
                };
              })
              contentCMs;
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
            ipFamilyPolicy = "SingleStack";
            ipFamilies = ["IPv6"];
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
              name = "nginx-${builtins.replaceStrings ["."] ["-"] (mkFQDN sub domain)}";
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
