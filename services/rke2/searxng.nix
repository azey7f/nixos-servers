{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.searxng;
  domain = config.az.server.rke2.baseDomain;
  images = config.az.server.rke2.images;
in {
  options.az.svc.rke2.searxng = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.server.rke2.namespaces."app-searxng" = {
      networkPolicy.fromNamespaces = ["envoy-gateway"];
      networkPolicy.toWAN = true; # default engines could change at any time, so this is safer functionality-wise than toDomains
    };

    az.server.rke2.images = {
      searxng = {
        imageName = "searxng/searxng";
        finalImageTag = "2025.8.10-6cccb46";
        imageDigest = "sha256:fe702750a9ffbf923533c67c456951a3be77f298915cf632077f3650ed4b5e4b";
        hash = "sha256-RPlb15UHD9mvNdPbSuDpgp3l5f733isxSFP/n97gJuU="; # renovate: searxng/searxng
      };
    };
    services.rke2.autoDeployCharts."searxng-valkey" = {
      repo = "https://valkey.io/valkey-helm";
      name = "valkey";
      version = "0.7.4";
      hash = "sha256-iMXdYlzAJQu4iKTIeRpKvkQnzo5p0Cwi2h8Rfmakuao="; # renovate: https://valkey.io/valkey-helm valkey

      targetNamespace = "app-searxng";
      values = {
        auth.enabled = false; # TODO?
        podSecurityContext.seccompProfile.type = "RuntimeDefault";
        securityContext.allowPrivilegeEscalation = false;
      };
    };
    az.server.rke2.secrets = [
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "searxng-config";
          namespace = "app-searxng";
        };
        stringData = {
          "settings.yml" = builtins.toJSON {
            use_default_settings = true;
            server = {
              base_url = "https://search.${domain}";

              bind_address = "[::]";
              secret_key = config.sops.placeholder."rke2/searxng/secret-key";

              limiter = true; # TODO: frp probably messes this up
              public_instance = true;
              image_proxy = false; # TODO - shitty internet
            };
            general = {
              instance_name = "search.${domain}";
              contact_url = "mailto:me@${domain}";
            };
            ui.theme_args.simple_style = "dark";
            valkey.url = "valkey://searxng-valkey.app-searxng.svc";
            outgoing = {
              request_timeout = 5;
              max_request_timeout = 15;
              pool_connections = 10000;
              pool_maxsize = 1000;
            };
          };
        };
      }
    ];
    services.rke2.manifests."searxng".content = [
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "searxng";
          namespace = "app-searxng";
        };
        spec = {
          selector.matchLabels.app = "searxng";
          template.metadata.labels.app = "searxng";

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
              secret.secretName = "searxng-config";
            }
          ];
        };
      }

      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "searxng";
          namespace = "app-searxng";
        };
        spec = {
          selector.app = "searxng";
          ipFamilyPolicy = "PreferDualStack";
          ipFamilies = ["IPv4" "IPv6"];
          ports = [
            {
              name = "searxng";
              port = 8080;
              protocol = "TCP";
            }
          ];
        };
      }
    ];

    az.svc.rke2.envoyGateway.httpRoutes = [
      {
        name = "searxng";
        namespace = "app-searxng";
        hostnames = ["search.${config.az.server.rke2.baseDomain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "searxng";
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
        domain = ["search.${config.az.server.rke2.baseDomain}"];
        methods = ["GET" "HEAD" "POST"];
        policy = "bypass";
      }
    ];

    az.server.rke2.clusterWideSecrets."rke2/searxng/secret-key" = {};
  };
}
