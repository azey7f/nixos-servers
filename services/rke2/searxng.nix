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
in {
  options.az.svc.rke2.searxng = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.server.rke2.manifests."app-searxng" = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "app-searxng";
        metadata.labels.name = "app-searxng";
      }

      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "valkey";
          namespace = "kube-system";
        };
        spec = {
          targetNamespace = "app-searxng";
          chart = "oci://registry-1.docker.io/bitnamicharts/valkey";
	  valuesContent = builtins.toJSON {
	    auth.enabled = false; # TODO
	  };
        };
      }
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

          template.spec.containers = [
            {
              name = "searxng";
              image = "docker.io/searxng/searxng";
              volumeMounts = [
                {
                  name = "config";
                  mountPath = "/etc/searxng";
                  readOnly = true;
                }
              ];
            }
          ];
          template.spec.volumes = [
            {
              # since all nodes run off the same flake,
              # this is possible (and *should* be safe)
              # TODO: make sure this actually works well with multiple nodes
              name = "config";
              hostPath = {
                path = "/run/secrets/rendered/rke2/searxng";
                type = "Directory";
              };
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

    sops.secrets."rke2/searxng/secret-key" = {
      # cluster-wide
      sopsFile = "${config.az.server.sops.path}/${azLib.reverseFQDN config.networking.domain}/default.yaml";
    };

    sops.templates."rke2/searxng/settings.yml".file = (pkgs.formats.yaml {}).generate "searxng-settings.yaml" {
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
      valkey.url = "valkey://valkey-primary.app-searxng.svc";
      outgoing = {
        request_timeout = 5;
        max_request_timeout = 15;
        pool_connections = 10000;
        pool_maxsize = 1000;
      };
    };
  };
}
