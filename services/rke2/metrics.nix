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
  };
}
