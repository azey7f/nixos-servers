{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.metrics;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.metrics = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.server.rke2.manifests."metrics" = [
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "grafana-env";
          namespace = "kube-system";
        };
        stringData = {
          GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = config.sops.placeholder."rke2/metrics/oidc-secret";
          GF_SECURITY_ADMIN_PASSWORD = config.sops.placeholder."rke2/metrics/admin-passwd"; # unused, user should be deleted after first start
        };
      }
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "metrics";
          namespace = "kube-system";
        };
        spec = {
          targetNamespace = "kube-system";
          #createNamespace = true;

          chart = "oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack";
          version = "76.2.0";

          valuesContent = builtins.toJSON {
            namespaceOverride = "kube-system";

            grafana.envFromSecret = "grafana-env";
            grafana."grafana.ini" = {
              server.root_url = "https://metrics.${domain}";

              #security.disable_initial_admin_creation = true; # FIXME: for some reason, this makes no data sources appear
              #auth.disable_login_form = true;

              #"auth.basic".enabled = false; # same problem as fixme
              "auth.generic_oauth" = {
                enabled = true;
                auto_login = true;
                name = "authelia";

                client_id = config.sops.placeholder."rke2/metrics/oidc-id";
                # client_secret = config.sops.placeholder."rke2/metrics/oidc-secret";

                auth_url = "https://auth.${domain}/api/oidc/authorization";
                token_url = "https://auth.${domain}/api/oidc/token";
                api_url = "https://auth.${domain}/api/oidc/userinfo";
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

            # https://github.com/prometheus-community/helm-charts/issues/3800
            grafana.serviceMonitor.labels.release = "metrics";

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
          };
        };
      }
      {
        apiVersion = "networking.k8s.io/v1";
        kind = "NetworkPolicy";
        metadata = {
          name = "metrics-grafana-allow-envoy";
          namespace = "kube-system";
        };
        spec = {
          podSelector.matchLabels."app.kubernetes.io/name" = "grafana";
          policyTypes = ["Ingress"];
          ingress = [
            {
              from = [{namespaceSelector.matchLabels.name = "envoy-gateway";}];
            }
          ];
        };
      }
      {
        apiVersion = "monitoring.coreos.com/v1alpha1";
        kind = "AlertmanagerConfig";
        metadata = {
          name = "mail-alerts";
          namespace = "kube-system";
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
                  to = "alerts@${domain}";
                  from = "metrics@${domain}";
                  smarthost = "mail.kube-system.svc:587";
                  tlsConfig.insecureSkipVerify = true;
                }
              ];
            }
          ];
        };
      }
    ];

    az.svc.rke2.envoyGateway.httpRoutes = [
      {
        name = "metrics";
        namespace = "kube-system";
        hostnames = ["metrics.${domain}"];
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
    ];

    az.svc.rke2.authelia.rules = [
      {
        domain = ["metrics.${domain}"];
        subject = "group:admin";
        policy = "two_factor";
      }
    ];

    # https://www.authelia.com/integration/openid-connect/clients/grafana/#configuration-escape-hatch
    az.svc.rke2.authelia.oidcClaims."grafana" = {
      id_token = ["email" "name" "groups" "preferred_username"];
    };
    az.svc.rke2.authelia.oidcClients."grafana" = {
      client_id = config.sops.placeholder."rke2/metrics/oidc-id";
      client_secret = config.sops.placeholder."rke2/metrics/oidc-secret-digest";

      require_pkce = true;
      pkce_challenge_method = "S256";
      #access_token_signed_response_alg = "RS256"; # msg="Error retrieving access token payload" error="token is not in JWT format: ..."

      redirect_uris = ["https://metrics.${domain}/login/generic_oauth"];
      scopes = ["openid" "email" "profile" "groups"];
      claims_policy = "grafana";
    };

    az.server.rke2.clusterWideSecrets."rke2/metrics/oidc-id" = {};
    az.server.rke2.clusterWideSecrets."rke2/metrics/oidc-secret" = {};
    az.server.rke2.clusterWideSecrets."rke2/metrics/oidc-secret-digest" = {};
    az.server.rke2.clusterWideSecrets."rke2/metrics/admin-passwd" = {};
  };
}
