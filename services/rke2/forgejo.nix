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
  };

  config = mkIf cfg.enable {
    az.server.rke2.manifests."app-forgejo" = [
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "forgejo";
          namespace = "kube-system";
        };
        spec = {
          targetNamespace = "app-forgejo";
          createNamespace = true;

          chart = "oci://code.forgejo.org/forgejo-helm/forgejo";

          valuesContent = builtins.toJSON {
            podSecurityContext.fsGroup = 1000; # can't push to mirrors w/ 65532
            containerSecurityContext = {
              allowPrivilegeEscalation = false;
              capabilities.drop = ["ALL"];
              runAsUser = 1000;
              runAsGroup = 1000;
              runAsNonRoot = true;
              seccompProfile.type = "RuntimeDefault";
            };

            redis-cluster.enabled = false;
            postgresql-ha.enabled = false;
            redis.enabled = true;
            postgresql.enabled = true;

            global.namespaceOverride = "app-forgejo";
            clusterDomain = config.networking.domain;
            persistence.enabled = true;

            httpRoute.enabled = false; # created manually

            gitea.admin = {
              username = "";
              password = "";
            };
            gitea.config = {
              database.DB_TYPE = "postgres";
              indexer = {
                ISSUE_INDEXER_TYPE = "bleve";
                REPO_INDEXER_ENABLED = true;
              };

              session.COOKIE_SECURE = true;
              service.DISABLE_REGISTRATION = true;

              server = rec {
                DOMAIN = "git.${domain}";
                ROOT_URL = "https://git.${domain}/";
              };

              actions = {
                ENABLED = true;
                DEFAULT_ACTIONS_URL = "https://code.forgejo.org";
              };

              ui = {
                DEFAULT_THEME = "forgejo-dark";
              };

              repository = {
                ENABLE_PUSH_CREATE_USER = true;
                ENABLE_PUSH_CREATE_ORG = true;
              };

              /*
              mailer = { # TODO
                ENABLED = true;
                SMTP_ADDR = "mail.${domain}";
                FROM = "git@${domain}";
                USER = "git@${domain}";
              };
              */
            };
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
  };
}
