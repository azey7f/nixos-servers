{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  domains = lib.filterAttrs (_: v: v.enable) config.az.cluster.domainSpecific.forgejo;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.domainSpecific.forgejo = lib.mkOption {
    type = with lib.types;
      attrsOf (submodule {
        options = with azLib.opt; {
          enable = optBool false;
          themes = {
            url = optStr "https://github.com/catppuccin/gitea/releases/download/v1.0.2/catppuccin-gitea.tar.gz";
            hash = optStr "sha256-HP4Ap4l2K1BWP1zWdCKYS5Y5N+JcKAcXi+Hx1g6MVwc=";
          };
        };
      });
    default = {};
  };

  config = lib.mkIf (domains != {}) {
    az.cluster.core.cnpg.enable = true;

    az.server.rke2.namespaces =
      (lib.mapAttrs' (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in
        lib.nameValuePair "app-forgejo-${id}" {
          networkPolicy = {
            fromNamespaces = ["envoy-gateway"];
            toNamespaces = ["app-mail" "envoy-gateway"];
            /*
            toDomains = [
              "auth.${domain}" # OIDC auto-discovery
              "codeberg.org" # push mirrors

              # pull mirroring
              "github.com"
              "*.github.com"
            ];
            */
            toWAN = true;
          };
        })
      domains)
      // {
        "app-mail".networkPolicy.fromNamespaces =
          lib.mapAttrsToList (domain: cfg: "app-forgejo-${builtins.replaceStrings ["."] ["-"] domain}") domains;
      };

    services.rke2.autoDeployCharts = lib.mapAttrs' (domain: cfg: let
      id = builtins.replaceStrings ["."] ["-"] domain;
    in
      lib.nameValuePair "forgejo-${id}" {
        repo = "oci://code.forgejo.org/forgejo-helm/forgejo";
        version = "15.0.3";
        hash = "sha256-eScJZeziZnY5GxFnBAJCsglrGwJtkkH82nP7rYM63IM="; # renovate: code.forgejo.org/forgejo-helm/forgejo 15.0.3

        targetNamespace = "app-forgejo-${id}";

        values = {
          strategy.type = "Recreate"; # TODO: remove w RWM storage
          podSecurityContext.fsGroup = 1000; # can't push to mirrors w/ 65534
          containerSecurityContext = {
            allowPrivilegeEscalation = false;
            capabilities.drop = ["ALL"];
            runAsUser = 1000;
            runAsGroup = 1000;
            runAsNonRoot = true;
            fsGroup = 1000;
            seccompProfile.type = "RuntimeDefault";
          };

          global.namespaceOverride = "app-forgejo-${id}";
          clusterDomain = config.networking.domain;
          persistence.enabled = true;
          persistence.size = "1Ti";

          httpRoute.enabled = false; # created manually

          gitea.admin.username = "";
          gitea.additionalConfigSources = [{secret.secretName = "forgejo-db-config";}];
          gitea.config = {
            indexer = {
              ISSUE_INDEXER_TYPE = "bleve";
              REPO_INDEXER_ENABLED = true;
            };

            session.COOKIE_SECURE = true;

            admin.SEND_NOTIFICATION_EMAIL_ON_NEW_USER = true;
            service = {
              ENABLE_NOTIFY_MAIL = true;

              REGISTER_EMAIL_CONFIRM = true;
              #DISABLE_REGISTRATION = true;
              ENABLE_INTERNAL_SIGNIN = false;
              REQUIRE_EXTERNAL_REGISTRATION_PASSWORD = false;
            };

            server = rec {
              DOMAIN = "git.${domain}";
              ROOT_URL = "https://git.${domain}/";
            };

            actions = {
              ENABLED = false;
              DEFAULT_ACTIONS_URL = "https://code.forgejo.org";
            };

            "git.timeout" = {
              # nixpkgs b big
              MIGRATE = 3600;
            };

            ui = {
              DEFAULT_THEME = "catppuccin-macchiato-mauve";
              THEMES = "forgejo-light,forgejo-dark,catppuccin-latte-rosewater,catppuccin-latte-flamingo,catppuccin-latte-pink,catppuccin-latte-mauve,catppuccin-latte-red,catppuccin-latte-maroon,catppuccin-latte-peach,catppuccin-latte-yellow,catppuccin-latte-green,catppuccin-latte-teal,catppuccin-latte-sky,catppuccin-latte-sapphire,catppuccin-latte-blue,catppuccin-latte-lavender,catppuccin-frappe-rosewater,catppuccin-frappe-flamingo,catppuccin-frappe-pink,catppuccin-frappe-mauve,catppuccin-frappe-red,catppuccin-frappe-maroon,catppuccin-frappe-peach,catppuccin-frappe-yellow,catppuccin-frappe-green,catppuccin-frappe-teal,catppuccin-frappe-sky,catppuccin-frappe-sapphire,catppuccin-frappe-blue,catppuccin-frappe-lavender,catppuccin-macchiato-rosewater,catppuccin-macchiato-flamingo,catppuccin-macchiato-pink,catppuccin-macchiato-mauve,catppuccin-macchiato-red,catppuccin-macchiato-maroon,catppuccin-macchiato-peach,catppuccin-macchiato-yellow,catppuccin-macchiato-green,catppuccin-macchiato-teal,catppuccin-macchiato-sky,catppuccin-macchiato-sapphire,catppuccin-macchiato-blue,catppuccin-macchiato-lavender,catppuccin-mocha-rosewater,catppuccin-mocha-flamingo,catppuccin-mocha-pink,catppuccin-mocha-mauve,catppuccin-mocha-red,catppuccin-mocha-maroon,catppuccin-mocha-peach,catppuccin-mocha-yellow,catppuccin-mocha-green,catppuccin-mocha-teal,catppuccin-mocha-sky,catppuccin-mocha-sapphire,catppuccin-mocha-blue,catppuccin-mocha-lavender";
            };

            repository = {
              ENABLE_PUSH_CREATE_USER = true;
              ENABLE_PUSH_CREATE_ORG = true;
            };

            mailer = {
              ENABLED = true;
              SMTP_ADDR = "mail.app-mail.svc";
              SMTP_PORT = 587;
              FORCE_TRUST_SERVER_CERT = true;
              FROM = "git@${domain}";
              SEND_AS_PLAIN_TEXT = true;
            };
          };

          extraVolumes = [
            {
              name = "forgejo-themes";
              emptyDir = {};
            }
            {
              name = "forgejo-themes-src";
              configMap = {
                name = "forgejo-themes";
                items = [
                  {
                    key = "themes.tar.gz";
                    path = "themes.tar.gz";
                  }
                ];
              };
            }
          ];
          extraContainerVolumeMounts = [
            {
              name = "forgejo-themes";
              readOnly = true;
              mountPath = "/data/gitea/public/assets/css";
            }
          ];
          extraInitVolumeMounts = [
            {
              name = "forgejo-themes";
              mountPath = "/themes";
            }
            {
              name = "forgejo-themes-src";
              mountPath = "/themes-src";
              readOnly = true;
            }
          ];
          initPreScript = ''
            tar -xzvf /themes-src/themes.tar.gz -C /themes
          '';
        };

        extraDeploy = [
          {
            apiVersion = "v1";
            kind = "ConfigMap";
            metadata = {
              name = "forgejo-themes";
              namespace = "app-forgejo-${id}";
            };
            binaryData."themes.tar.gz" = builtins.readFile (
              pkgs.runCommand "forgejo-themes-base64" {nativeBuildInputs = [pkgs.coreutils];} ''
                base64 -w0 ${toString (pkgs.fetchurl {inherit (cfg.themes) url hash;})} > $out
              ''
            );
          }

          {
            apiVersion = "postgresql.cnpg.io/v1";
            kind = "Cluster";
            metadata = {
              name = "forgejo-cnpg";
              namespace = "app-forgejo-${id}";
            };
            spec = {
              instances = 1; # TODO: HA

              imageCatalogRef = {
                apiGroup = "postgresql.cnpg.io";
                kind = "ClusterImageCatalog";
                name = "postgresql";
                major = 17;
              };

              bootstrap.initdb = {
                database = "forgejo";
                owner = "forgejo";
                secret.name = "forgejo-cnpg-user";
              };

              storage.size = "100Gi";
            };
          }
        ];
      })
    domains;
    az.server.rke2.secrets = lib.flatten (lib.mapAttrsToList (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in [
        {
          apiVersion = "v1";
          kind = "Secret";
          type = "kubernetes.io/basic-auth";
          metadata = {
            name = "forgejo-cnpg-user";
            namespace = "app-forgejo-${id}";
          };
          stringData = {
            username = "forgejo";
            password = config.sops.placeholder."rke2/forgejo-${domain}/cnpg-passwd";
          };
        }

        {
          apiVersion = "v1";
          kind = "Secret";
          metadata = {
            name = "forgejo-db-config";
            namespace = "app-forgejo-${id}";
          };
          stringData.database = ''
            DB_TYPE=postgres
            HOST=forgejo-cnpg-rw.app-forgejo-${id}.svc
            NAME=forgejo
            USER=forgejo
            PASSWD=${config.sops.placeholder."rke2/forgejo-${domain}/cnpg-passwd"}
          '';
        }
      ])
      domains);

    az.cluster.core.envoyGateway.httpRoutes =
      lib.mapAttrsToList (
        domain: cfg: let
          id = builtins.replaceStrings ["."] ["-"] domain;
        in {
          name = "forgejo";
          namespace = "app-forgejo-${id}";
          hostnames = ["git.${domain}"];
          rules = [
            {
              backendRefs = [
                {
                  name = "forgejo-${id}-http";
                  port = 3000;
                }
              ];
              # nixpkgs b *big*
              timeouts.request = "1200s";
              timeouts.backendRequest = "1200s";
            }
          ];
        }
      )
      domains;

    az.cluster.core.auth.authelia.rules =
      lib.mapAttrsToList (domain: cfg: {
        domain = ["git.${domain}"];
        policy = "bypass";
      })
      domains;

    az.cluster.core.auth.authelia.oidcClientSecrets =
      lib.mapAttrs' (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in {
        name = "forgejo-${id}";
        value = "rke2/forgejo-${domain}/oidc-secret-digest";
      })
      domains;

    az.cluster.core.auth.authelia.oidcClients = lib.mapAttrs' (domain: cfg: let
      id = builtins.replaceStrings ["."] ["-"] domain;
    in
      lib.nameValuePair "forgejo-${id}" {
        client_id = config.sops.placeholder."rke2/forgejo-${domain}/oidc-id";

        require_pkce = true;
        pkce_challenge_method = "S256";

        redirect_uris = ["https://git.${domain}/user/oauth2/authelia/callback"];
        scopes = ["openid" "email" "profile" "groups"];
      })
    domains;

    az.server.rke2.clusterWideSecrets =
      lib.concatMapAttrs (domain: cfg: {
        "rke2/forgejo-${domain}/oidc-id" = {};
        "rke2/forgejo-${domain}/oidc-secret-digest" = {};
        "rke2/forgejo-${domain}/cnpg-passwd" = {};
      })
      domains;
  };
}
