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
        kind = "ConfigMap";
        metadata = {
          name = "knot-cm";
          namespace = "app-nameserver";
        };
        data = {
          "${revDomain}.zone" = import ./zones/${revDomain}.nix args;
          "knot.conf" = import ./config.nix args;
        };
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
          template.spec.containers = [
            {
              name = "knot";
              image = "cznic/knot";
              command = ["knotd" "-c" "/config/knot.conf"];
              volumeMounts = [
                {
                  name = "knot-data";
                  mountPath = "/storage";
                }
                {
                  name = "knot-cm";
                  mountPath = "/config";
                }
                {
                  name = "sops-secrets-rendered";
                  mountPath = "/secrets";
                  readOnly = true;
                }
              ];
            }
          ];
          template.spec.volumes = [
            {
              name = "knot-data";
              persistentVolumeClaim.claimName = "knot-data";
            }
            {
              name = "knot-cm";
              configMap = {
                name = "knot-cm";
                items = [
                  {
                    key = "${revDomain}.zone";
                    path = "${revDomain}.zone";
                  }
                  {
                    key = "knot.conf";
                    path = "knot.conf";
                  }
                ];
              };
            }
            {
              # since all nodes run off the same flake,
              # this is possible (and *should* be safe)
              # TODO: make sure this actually works well with multiple nodes
              name = "sops-secrets-rendered";
              hostPath = {
                path = "/run/secrets/rendered/rke2/nameserver";
                type = "Directory";
              };
            }
          ];
        };
      }
    ];

    sops.secrets."rke2/nameserver/tsig-secret" = {
      # cluster-wide
      sopsFile = "${config.az.server.sops.path}/${azLib.reverseFQDN config.networking.domain}/default.yaml";
    };
    sops.templates."rke2/nameserver/acme.conf".content = ''
      key:
        - id: acme
          algorithm: hmac-sha256
          secret: ${config.sops.placeholder."rke2/nameserver/tsig-secret"}
    '';

    sops.templates."rke2/nameserver/tsig-secret.yaml".file = (pkgs.formats.yaml {}).generate "tsig-secret.yaml" {
      apiVersion = "v1";
      kind = "Secret";
      metadata = {
        name = "rfc2136-tsig";
        namespace = "cert-manager";
      };
      data.secret = config.sops.placeholder."rke2/nameserver/tsig-secret";
    };

    systemd.tmpfiles.settings."10-rke2"."${config.az.server.rke2.manifestDir}/app-nameserver-tsig-secret.yaml"."L+".argument = "/run/secrets/rendered/rke2/nameserver/tsig-secret.yaml";
  };
}
