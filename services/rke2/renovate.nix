{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.renovate;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.renovate = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    /*
    az.svc.cron.jobs = [
      "30 5 * * *  fish -c 'for f in /var/lib/rancher/rke2/server/manifests/*'; kubectl apply -f $f; end"
    ];
    */
    az.server.rke2.manifests."app-renovate" = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "app-renovate";
        metadata.labels.name = "app-renovate";
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "renovate-env";
          namespace = "app-renovate";
        };
        stringData = {
          RENOVATE_TOKEN = config.sops.placeholder."rke2/renovate/forgejo-pat";
          RENOVATE_GITHUB_COM_TOKEN = config.sops.placeholder."rke2/renovate/github-ro-pat";
        };
      }
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "renovate";
          namespace = "kube-system";
        };
        spec = {
          targetNamespace = "app-renovate";
          #createNamespace = true;

          repo = "https://docs.renovatebot.com/helm-charts";
          chart = "renovate";
          version = "43.6.1";

          valuesContent = builtins.toJSON {
            renovate.securityContext = {
              privileged = false;
              allowPrivilegeEscalation = false;
              capabilities.drop = ["ALL"];
              runAsUser = 65534;
              runAsGroup = 65534;
              runAsNonRoot = true;
              fsGroup = 65534;
              seccompProfile.type = "RuntimeDefault";
            };

            cronjob.schedule = "0 4 * * *"; # 4AM daily

            existingSecret = "renovate-env";
            #envFrom = [{secretRef.name = "renovate-env";}];
            renovate.config = builtins.toJSON {
              platform = "forgejo";
              endpoint = "https://git.${domain}/api/v1";
              token = "{{ secrets.RENOVATE_TOKEN }}";
              gitAuthor = "renovate-bot <renovate-bot@${domain}>";
              autodiscover = true; # restricted account in forgejo
            };
          };
        };
      }
    ];

    az.server.rke2.clusterWideSecrets."rke2/renovate/forgejo-pat" = {};
    az.server.rke2.clusterWideSecrets."rke2/renovate/github-ro-pat" = {};
  };
}
