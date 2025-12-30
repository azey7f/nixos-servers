{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  domains = lib.filterAttrs (_: v: v.enable) config.az.cluster.domainSpecific.searxng;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.domainSpecific.searxng = lib.mkOption {
    type = with lib.types;
      attrsOf (submodule {
        options = with azLib.opt; {
          enable = optBool false;
        };
      });
    default = {};
  };

  config = lib.mkIf (domains != {}) {
    az.server.rke2.namespaces."app-searxng" = {
      mullvadRouted = true;
      networkPolicy.fromNamespaces = ["envoy-gateway"];
      networkPolicy.toWAN = true; # default engines could change at any time, so this is safer than toDomains
    };

    az.server.rke2.images = {
      searxng = {
        imageName = "searxng/searxng";
        finalImageTag = "2025.10.13-c34bb6128"; # versioning: regex:^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+).*$
        imageDigest = "sha256:d69b566421b494c0680adf2f78d757184abb2d3fd655a2f0e008b3b8d901bae7";
        hash = "sha256-D2h0fqD3E7zR8pc04jQ6c/8Y/yYi0TITtY/J/5Ss5u8="; # renovate: searxng/searxng 2025.10.13-c34bb6128
      };
    };
    services.rke2.autoDeployCharts."searxng-valkey" = {
      repo = "https://valkey.io/valkey-helm";
      name = "valkey";
      version = "0.9.2";
      hash = "sha256-JjgpTqibG1LLDv36fLMVnGXkYcS83z7HeW79j44K+HY="; # renovate: https://valkey.io/valkey-helm valkey 0.9.2

      targetNamespace = "app-searxng";
      values = {
        auth.enabled = false; # TODO?
        podSecurityContext.seccompProfile.type = "RuntimeDefault";
        securityContext.allowPrivilegeEscalation = false;
        valkeyConfig = ''
          bind * -::*
        ''; # TODO: github.com/valkey-io/valkey-helm/pull/68
      };
    };
    az.server.rke2.secrets =
      lib.mapAttrsToList (
        domain: cfg: let
          id = builtins.replaceStrings ["."] ["-"] domain;
        in {
          apiVersion = "v1";
          kind = "Secret";
          metadata = {
            name = "searxng-${id}-config";
            namespace = "app-searxng";
          };
          stringData = {
            "settings.yml" = builtins.toJSON {
              use_default_settings = true;
              server = {
                base_url = "https://search.${domain}";

                bind_address = "[::]";
                secret_key = config.sops.placeholder."rke2/searxng/secret-key";

                limiter = true;
                public_instance = true;
                image_proxy = false; # TODO - shitty uplink speed
              };
              general = {
                instance_name = "search.${domain}";
                contact_url = "mailto:me@${domain}";
              };
              ui.theme_args.simple_style = "dark";
              valkey.url = "valkey://searxng-valkey.app-searxng.svc"; # TODO: is it fine to have 1 valkey instance or does there need to be 1 per-domain?
              outgoing = {
                request_timeout = 5;
                max_request_timeout = 15;
                pool_connections = 10000;
                pool_maxsize = 1000;
              };
            };
          };
        }
      )
      domains;

    services.rke2.manifests."searxng".content = lib.flatten (
      lib.mapAttrsToList (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in [
        {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            name = "searxng-${id}";
            namespace = "app-searxng";
          };
          spec = {
            selector.matchLabels.app = "searxng-${id}";
            template.metadata.labels.app = "searxng-${id}";

            template.spec.securityContext = {
              runAsNonRoot = true;
              seccompProfile.type = "RuntimeDefault";
              runAsUser = 65534;
              runAsGroup = 65534;
            };

            template.spec.containers = [
              {
                name = "searxng";
                image = images.searxng.imageString;
                volumeMounts = [
                  {
                    name = "searxng-config";
                    mountPath = "/etc/searxng";
                    readOnly = true;
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
                name = "searxng-config";
                secret.secretName = "searxng-${id}-config";
              }
            ];
          };
        }

        {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            name = "searxng-${id}";
            namespace = "app-searxng";
          };
          spec = {
            selector.app = "searxng-${id}";
            ipFamilyPolicy = "SingleStack";
            ipFamilies = ["IPv6"];
            ports = [
              {
                name = "searxng";
                port = 8080;
                protocol = "TCP";
              }
            ];
          };
        }
      ])
      domains
    );

    az.cluster.core.envoyGateway.httpRoutes =
      lib.mapAttrsToList (
        domain: cfg: let
          id = builtins.replaceStrings ["."] ["-"] domain;
        in {
          name = "searxng-${id}";
          namespace = "app-searxng";
          hostnames = ["search.${domain}"];
          rules = [
            {
              backendRefs = [
                {
                  name = "searxng-${id}";
                  port = 8080;
                }
              ];
            }
          ];
          csp = "strict";
          customCSP.img-src = ["'self' data: blob: http: https:"];
          responseHeaders.cross-origin-embedder-policy = "credentialless";
        }
      )
      domains;

    az.cluster.core.auth.authelia.rules =
      lib.mapAttrsToList (
        domain: cfg: let
          id = builtins.replaceStrings ["."] ["-"] domain;
        in {
          domain = ["search.${domain}"];
          methods = ["GET" "HEAD" "POST"];
          policy = "bypass";
        }
      )
      domains;

    # https://github.com/searxng/searxng/discussions/3114
    # not like reusing it matters anyways
    az.server.rke2.clusterWideSecrets."rke2/searxng/secret-key" = {};
  };
}
