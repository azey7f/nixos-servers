{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  domains = lib.filterAttrs (_: v: v.enable) config.az.cluster.domainSpecific.renovate;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.domainSpecific.renovate = lib.mkOption {
    type = with lib.types;
      attrsOf (submodule {
        options = with azLib.opt; {
          enable = optBool false;
          schedule = optStr "*/15 * * * *"; # bi-hourly
        };
      });
    default = {};
  };

  config = lib.mkIf (domains != {}) {
    az.server.rke2.namespaces = lib.mapAttrs' (domain: cfg: let
      id = builtins.replaceStrings ["."] ["-"] domain;
    in
      lib.nameValuePair "app-renovate-${id}" {
        networkPolicy.fromNamespaces = ["envoy-gateway"];
        networkPolicy.toNamespaces = ["envoy-gateway"];
        networkPolicy.toWAN = true;
      })
    domains;

    services.rke2.autoDeployCharts = lib.mapAttrs' (domain: cfg: let
      id = builtins.replaceStrings ["."] ["-"] domain;
    in
      lib.nameValuePair "renovate-${id}" {
        targetNamespace = "app-renovate-${id}";

        repo = "https://docs.renovatebot.com/helm-charts";
        name = "renovate";
        version = "44.15.1";
        hash = "sha256-d0YLoW8mzjLXyRrTbnUrEge88ilpc98sCgeQ03dwHSU="; # renovate: https://docs.renovatebot.com/helm-charts renovate 44.15.1

        # renovate-args: --set renovate.config=\"{}\"
        values = {
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

          extraVolumes = builtins.map (name: {
            inherit name;
            emptyDir = {};
          }) ["home" "nix" "nonexistent"];

          extraVolumeMounts = [
            # Fatal: can't create directory '/home/ubuntu/.gnupg': Permission denied
            {
              name = "home";
              mountPath = "/home/ubuntu";
            }
            # rootless nix in postUpgradeTasks
            {
              name = "nix";
              mountPath = "/nix";
            }
            # warning: $HOME ('/nix') is not owned by you, falling back to the one defined in the 'passwd' file ('/nonexistent')
            # not stupid if it works, right?
            {
              name = "nonexistent";
              mountPath = "/nonexistent";
            }
          ];

          cronjob = {
            schedule = cfg.schedule;
            timeZone = config.az.core.locale.tz;

            concurrencyPolicy = "Forbid";

            # https://github.com/kubernetes/kubernetes/issues/74741
            failedJobsHistoryLimit = 0;
            successfulJobsHistoryLimit = 0;
          };

          existingSecret = "renovate-env";
          #envFrom = [{secretRef.name = "renovate-env";}];
          renovate.config = builtins.toJSON {
            platform = "forgejo";
            endpoint = "https://git.${domain}/api/v1";
            token = "{{ secrets.RENOVATE_TOKEN }}";
            gitAuthor = "renovate-bot <renovate-bot@${domain}>";
            gitPrivateKey = "{{ secrets.RENOVATE_GIT_PRIVATE_KEY }}";
            autodiscover = true; # restricted account in forgejo

            allowedCommands = [
              # too complex to be worth checking.
              "^.*$"
            ];

            # envoy-gateway causes https://codeberg.org/forgejo/forgejo/issues/1929 because it 307s any %2F URIs to / by default
            # TODO: change that behavior for git., maybe?
            branchNameStrict = true;
            branchPrefix = "renovate#";
          };
        };
      })
    domains;
    az.server.rke2.secrets =
      lib.mapAttrsToList (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "renovate-env";
          namespace = "app-renovate-${id}";
        };
        stringData = {
          RENOVATE_TOKEN = config.sops.placeholder."rke2/renovate-${domain}/forgejo-pat";
          RENOVATE_GITHUB_COM_TOKEN = config.sops.placeholder."rke2/renovate-${domain}/github-ro-pat";
          RENOVATE_GIT_PRIVATE_KEY = config.sops.placeholder."rke2/renovate-${domain}/gpg-key";
          RENOVATE_LOG_LEVEL = "debug";
        };
      })
      domains;

    az.server.rke2.clusterWideSecrets =
      lib.concatMapAttrs (domain: cfg: {
        "rke2/renovate-${domain}/forgejo-pat" = {};
        "rke2/renovate-${domain}/github-ro-pat" = {};
        "rke2/renovate-${domain}/gpg-key" = {};
      })
      domains;

    # auto-update
    # TODO: put this somewhere else?
    az.svc.cron = {
      enable = lib.mkDefault true;
      jobs = [
        "0 5 * * *  root  /etc/nixos/scripts/auto-update/auto-update"
      ];
    };
  };
}
