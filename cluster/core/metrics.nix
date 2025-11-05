{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  cfg = config.az.cluster.core.metrics;
  images = config.az.server.rke2.images;

  auth = config.az.cluster.core.auth;
in {
  options.az.cluster.core.metrics = with azLib.opt; {
    enable = optBool false;

    webuiDomain = lib.mkOption {
      type = lib.types.str;
      # must be set
    };

    mailDomain = lib.mkOption {
      type = with lib.types; nullOr str;
      default =
        if config.az.cluster.core.mail.enable
        then cfg.webuiDomain
        else null;
    };
  };

  config = lib.mkIf cfg.enable {
    az.server.rke2.namespaces."metrics-system" = {
      podSecurity = "privileged"; # https://github.com/prometheus-community/helm-charts/issues/4837
      networkPolicy.fromNamespaces = ["envoy-gateway"];
      networkPolicy.extraEgress = [{toEntities = ["cluster"];}];

      networkPolicy.toNamespaces = lib.optional (cfg.mailDomain != null) "app-mail";
      networkPolicy.toDomains =
        lib.optional auth.enable "auth.${auth.domain}"; # grafana OIDC
    };

    az.server.rke2.images = {
      prometheus-config-reloader = {
        imageName = "quay.io/prometheus-operator/prometheus-config-reloader";
        finalImageTag = "v0.86.0";
        imageDigest = "sha256:5dcc707d52334e3493fa311816b03f9a9e3ecd3b275d7a3fe2f38c80d63e5d18";
        hash = "sha256-U+IFa29QbqUinlZ3l3TV83o5RS7R0bwcjp10nQ8jKEs="; # renovate: quay.io/prometheus-operator/prometheus-config-reloader 0.86.0
      };
      curl = {
        imageName = "curlimages/curl";
        finalImageTag = "8.17.0";
        imageDigest = "sha256:1e809b44e4cdf8a64a1bfe37875d4758a39454d686c2ff3c4a0fbeda93aae519";
        hash = "sha256-7cyXb3brqgtGLOm3nssW+Fyk8OGUThVAyBX3LMinj5c="; # renovate: curlimages/curl 8.17.0
      };
    };
    services.rke2.autoDeployCharts."metrics" = {
      repo = "oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack";
      version = "78.3.0";
      hash = "sha256-w6U4FhVD+BYFYB0CvzL3oQDHQmi+DoIo/+JUMspll7Y="; # renovate: ghcr.io/prometheus-community/charts/kube-prometheus-stack 78.3.0

      targetNamespace = "metrics-system";
      values = {
        prometheusOperator.prometheusConfigReloader.image.tag = images.prometheus-config-reloader.finalImageTag;
        grafana.downloadDashboardsImage.tag = images.curl.finalImageTag;

        alertmanager.alertmanagerSpec.externalUrl = "https://alerts.${cfg.webuiDomain}";
        prometheus.prometheusSpec.externalUrl = "https://prometheus.${cfg.webuiDomain}";

        grafana.envFromSecret = "grafana-env";
        grafana."grafana.ini" = {
          server.root_url = "https://metrics.${cfg.webuiDomain}";

          dashboards.default_home_dashboard_path = "/var/lib/grafana/dashboards/default/k8s-dashboard.json";

          #security.disable_initial_admin_creation = true; # FIXME: for some reason, this makes no data sources appear
          #auth.disable_login_form = true;

          #"auth.basic".enabled = false; # same problem as fixme
          "auth.generic_oauth" = lib.optionalAttrs auth.enable {
            enabled = true;
            auto_login = true;
            name = "authelia";

            # client_id = config.sops.placeholder."rke2/metrics/oidc-id";
            # client_secret = config.sops.placeholder."rke2/metrics/oidc-secret";

            auth_url = "https://auth.${auth.domain}/api/oidc/authorization";
            token_url = "https://auth.${auth.domain}/api/oidc/token";
            api_url = "https://auth.${auth.domain}/api/oidc/userinfo";
            scopes = "openid profile email groups";
            use_pkce = true;
            auth_style = "InHeader";

            login_attribute_path = "preferred_username";
            name_attribute_path = "name";
            groups_attribute_path = "groups";

            role_attribute_path = "contains(groups[*], 'admin') && 'GrafanaAdmin' || 'Viewer'";
            role_attribute_strict = true;
            allow_assign_grafana_admin = true;
          };
        };

        grafana.dashboardProviders."dashboardproviders.yaml" = {
          # https://github.com/grafana/helm-charts/blob/0af99fac51424d0e5bb19e0da25a7750d3062f42/charts/grafana/values.yaml#L738
          apiVersion = 1;
          providers = [
            {
              name = "default";
              orgId = 1;
              folder = "";
              type = "file";
              disableDeletion = false;
              editable = true;
              options.path = "/var/lib/grafana/dashboards/default";
            }
          ];
        };
        grafana.dashboards.default = {
          k8s-dashboard = {
            json = builtins.replaceStrings ["\${DS__VICTORIAMETRICS-PROD-ALL}"] ["prometheus"] (
              builtins.readFile (pkgs.fetchurl {
                name = "k8s-dashboard";
                url = "https://grafana.com/api/dashboards/15661/revisions/2/download";
                hash = "sha256-2bMb41nbqXLhkHdWOyM4ZCdvTaOqWdr7YlYJnM0q7s0="; # renovate: k8s-dashboard 2
              })
            );
          };
          cert-manager = {
            json = builtins.readFile (pkgs.fetchurl {
              name = "cert-manager";
              url = "https://grafana.com/api/dashboards/20842/revisions/3/download";
              hash = "sha256-p2OqJExFbOCHrCda9PqXBDlHxjCELo+mzE3+glFV+eI="; # renovate: cert-manager 3
            });
          };
        };

        # https://github.com/prometheus-community/helm-charts/issues/3800
        grafana.extraLabels.release = "metrics";

        # https://stackoverflow.com/questions/73031228/getting-kubecontrollermanager-kubeproxy-kubescheduler-down-alert-in-kube-prome/73181797#73181797
        kubeControllerManager = {
          service = {
            enabled = true;
            ports.http = 10257;
            targetPorts.http = 10257;
          };
          serviceMonitor = {
            https = true;
            insecureSkipVerify = "true";
          };
        };
        kubeScheduler = {
          service = {
            enabled = true;
            ports.http = 10259;
            targetPorts.http = 10259;
          };
          serviceMonitor = {
            https = true;
            insecureSkipVerify = "true";
          };
        };
        kubeProxy.enabled = false; # replaced w/ cilium

        # https://github.com/prometheus-community/helm-charts/issues/2816
        prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec = {
          storageClassName = "default";
          accessModes = ["ReadWriteOnce"];
          resources.requests.storage = "50Gi";
        };
        alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec = {
          storageClassName = "default";
          accessModes = ["ReadWriteOnce"];
          resources.requests.storage = "10Gi";
        };
      };

      extraDeploy = lib.optionals (cfg.mailDomain != null) [
        {
          apiVersion = "monitoring.coreos.com/v1alpha1";
          kind = "AlertmanagerConfig";
          metadata = {
            name = "mail-alerts";
            namespace = "metrics-system";
          };
          spec = {
            route = {
              groupBy = ["namespace" "severity"];
              groupWait = "5s";
              groupInterval = "5m";
              repeatInterval = "8h";
              receiver = "mail-alerts";
            };
            receivers = [
              {
                name = "mail-alerts";
                emailConfigs = [
                  {
                    to = "alerts@${cfg.mailDomain}";
                    from = "metrics@${cfg.mailDomain}";
                    smarthost = "mail.app-mail.svc:587";
                    tlsConfig.insecureSkipVerify = true;
                  }
                ];
              }
            ];
          };
        }
      ];
    };
    az.server.rke2.secrets = [
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "grafana-env";
          namespace = "metrics-system";
        };
        stringData = {
          GF_AUTH_GENERIC_OAUTH_CLIENT_ID = config.sops.placeholder."rke2/metrics/oidc-id";
          GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = config.sops.placeholder."rke2/metrics/oidc-secret";
          GF_SECURITY_ADMIN_PASSWORD = config.sops.placeholder."rke2/metrics/admin-passwd"; # unused, user should be deleted after first start
        };
      }
    ];

    az.cluster.core.envoyGateway.httpRoutes = [
      {
        name = "metrics";
        namespace = "metrics-system";
        hostnames = ["metrics.${cfg.webuiDomain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "metrics-grafana";
                port = 80;
              }
            ];
          }
        ];
      }
      {
        name = "alerts";
        namespace = "metrics-system";
        hostnames = ["alerts.${cfg.webuiDomain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "metrics-kube-prometheus-st-alertmanager";
                port = 9093;
              }
            ];
          }
        ];
      }
      {
        name = "prometheus";
        namespace = "metrics-system";
        hostnames = ["prometheus.${cfg.webuiDomain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "metrics-kube-prometheus-st-prometheus";
                port = 9090;
              }
            ];
          }
        ];
      }
    ];

    az.cluster.core.auth.authelia.rules = [
      {
        domain = ["metrics.${cfg.webuiDomain}" "alerts.${cfg.webuiDomain}" "prometheus.${cfg.webuiDomain}"];
        subject = "group:admin";
        policy = "two_factor";
      }
    ];

    # https://www.authelia.com/integration/openid-connect/clients/grafana/#configuration-escape-hatch
    az.cluster.core.auth.authelia.oidcClaims."grafana" = {
      id_token = ["email" "name" "groups" "preferred_username"];
    };
    az.cluster.core.auth.authelia.oidcClients."grafana" = {
      client_id = config.sops.placeholder."rke2/metrics/oidc-id";
      client_secret = config.sops.placeholder."rke2/metrics/oidc-secret-digest";

      require_pkce = true;
      pkce_challenge_method = "S256";
      #access_token_signed_response_alg = "RS256"; # msg="Error retrieving access token payload" error="token is not in JWT format: ..."

      redirect_uris = ["https://metrics.${cfg.webuiDomain}/login/generic_oauth"];
      scopes = ["openid" "email" "profile" "groups"];
      claims_policy = "grafana";
    };

    az.server.rke2.clusterWideSecrets."rke2/metrics/oidc-id" = {};
    az.server.rke2.clusterWideSecrets."rke2/metrics/oidc-secret" = {};
    az.server.rke2.clusterWideSecrets."rke2/metrics/oidc-secret-digest" = {};
    az.server.rke2.clusterWideSecrets."rke2/metrics/admin-passwd" = {};
  };
}
