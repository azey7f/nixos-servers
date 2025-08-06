# TODO: docs - knotc status cert-key, keymgr <zone> ds
{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
} @ args:
with lib; let
  cfg = config.az.svc.rke2.nameserver;
  domain = config.az.server.rke2.baseDomain;
  revDomain = azLib.reverseFQDN domain;
in {
  imports = [./networking.nix];

  options.az.svc.rke2.nameserver = with azLib.opt; {
    enable = optBool false;
    secondaryServers = mkOption {
      type = with types; listOf attrs;
      default = builtins.filter (remote: remote ? knotPubkey) outputs.infra.domains.${domain}.vps;
    };
  };

  config = mkIf cfg.enable {
    az.server.rke2.manifests."app-nameserver" = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "app-nameserver";
        metadata.labels.name = "app-nameserver";
      }
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "knot-data";
          namespace = "app-nameserver";
        };
        spec = {
          accessModes = ["ReadWriteOnce"];
          resources.requests.storage = "10Mi"; # just keys & journal
        };
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "knot-config";
          namespace = "app-nameserver";
        };
        stringData = {
          "${revDomain}.zone" = import ./zones/${revDomain}.nix args;
          "knot.conf" = import ./config.nix args;
        };
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "rfc2136-tsig";
          namespace = "cert-manager";
        };
        stringData.secret = config.sops.placeholder."rke2/nameserver/tsig-secret";
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "knot";
          namespace = "app-nameserver";
        };
        spec = {
          replicas = 1; # hidden master, doesn't need HA
          selector.matchLabels.app = "knot";
          template.metadata.labels.app = "knot";

          template.spec.securityContext = {
            runAsNonRoot = true;
            seccompProfile.type = "RuntimeDefault";
            runAsUser = 65532;
            runAsGroup = 65532;
            fsGroup = 65532;
          };
          template.spec.containers = [
            {
              name = "knot";
              image = "cznic/knot";
              command = ["knotd" "-c" "/config/knot.conf"];
              volumeMounts = [
                {
                  name = "knot-rundir";
                  mountPath = "/rundir";
                }
                {
                  name = "knot-data";
                  mountPath = "/storage";
                }
                {
                  name = "knot-config";
                  mountPath = "/config";
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
              name = "knot-rundir";
              emptyDir.sizeLimit = "100Mi";
            }
            {
              name = "knot-data";
              persistentVolumeClaim.claimName = "knot-data";
            }
            {
              name = "knot-config";
              secret.secretName = "knot-config";
            }
          ];
        };
      }
    ];

    # ACME
    az.server.rke2.clusterWideSecrets."rke2/nameserver/tsig-secret" = {};
  };
}
