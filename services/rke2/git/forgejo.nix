{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.forgejo;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.forgejo = with azLib.opt; {
    enable = optBool false;
    themesUrl = optStr "https://github.com/catppuccin/gitea/releases/latest/download/catppuccin-gitea.tar.gz";
  };

  config = mkIf cfg.enable {
    az.svc.rke2.cnpg.enable = true;
    az.server.rke2.namespaces = {
      "app-forgejo".networkPolicy = {
        fromNamespaces = ["envoy-gateway"];
        toNamespaces = ["app-mail"];
        toDomains = [
          "auth.${domain}" # OIDC auto-discovery
          "github.com" # themes dl (#TODO: local mirror), pull mirroring
          "release-assets.githubusercontent.com"
          "codeberg.org" # push mirrors
        ];
      };
      "app-mail".networkPolicy.fromNamespaces = ["app-forgejo"];
    };

    az.server.rke2.manifests."app-forgejo" = [
      {
        apiVersion = "postgresql.cnpg.io/v1";
        kind = "Cluster";
        metadata = {
          name = "forgejo-cnpg";
          namespace = "app-forgejo";
        };
        spec = {
          instances = 1; # TODO: HA

          bootstrap.initdb = {
            database = "forgejo";
            owner = "forgejo";
            secret.name = "forgejo-cnpg-user";
          };

          storage.size = "100Gi";
        };
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        type = "kubernetes.io/basic-auth";
        metadata = {
          name = "forgejo-cnpg-user";
          namespace = "app-forgejo";
        };
        stringData = {
          username = "forgejo";
          password = config.sops.placeholder."rke2/forgejo/cnpg-passwd";
        };
      }

      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "forgejo-db-config";
          namespace = "app-forgejo";
        };
        stringData.database = ''
          DB_TYPE=postgres
          HOST=forgejo-cnpg-rw.app-forgejo.svc
          NAME=forgejo
          USER=forgejo
          PASSWD=${config.sops.placeholder."rke2/forgejo/cnpg-passwd"}
        '';
      }
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "forgejo";
          namespace = "kube-system";
        };
        spec = {
          targetNamespace = "app-forgejo";

          chart = "oci://code.forgejo.org/forgejo-helm/forgejo";
          version = "14.0.2";

          valuesContent = builtins.toJSON {
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

            global.namespaceOverride = "app-forgejo";
            clusterDomain = config.networking.domain;
            persistence.enabled = true;

            httpRoute.enabled = false; # created manually

            gitea.admin = {
              username = "";
              password = "";
            };
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
                ENABLED = true;
                DEFAULT_ACTIONS_URL = "https://code.forgejo.org";
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
              };
            };

            extraVolumes = [
              {
                name = "forgejo-themes";
                emptyDir = {};
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
            ];
            initPreScript = ''
              curl -Lvo /themes/themes.tar.gz ${cfg.themesUrl}
              tar -xzvf /themes/themes.tar.gz -C /themes
              rm /themes/themes.tar.gz
            '';
          };
        };
      }
    ];

    az.svc.rke2.envoyGateway.httpRoutes = [
      {
        name = "forgejo";
        namespace = "app-forgejo";
        hostnames = ["git.${domain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "forgejo-http";
                port = 3000;
              }
            ];
          }
        ];
      }
    ];

    az.svc.rke2.authelia.rules = [
      {
        domain = ["git.${domain}"];
        policy = "bypass";
      }
    ];
    az.svc.rke2.authelia.oidcClients."forgejo" = {
      client_id = config.sops.placeholder."rke2/forgejo/oidc-id";
      client_secret = config.sops.placeholder."rke2/forgejo/oidc-secret-digest";

      require_pkce = true;
      pkce_challenge_method = "S256";

      redirect_uris = ["https://git.${domain}/user/oauth2/authelia/callback"];
      scopes = ["openid" "email" "profile" "groups"];
    };

    az.server.rke2.clusterWideSecrets."rke2/forgejo/oidc-id" = {};
    az.server.rke2.clusterWideSecrets."rke2/forgejo/oidc-secret-digest" = {};
    az.server.rke2.clusterWideSecrets."rke2/forgejo/cnpg-passwd" = {};
  };
}
