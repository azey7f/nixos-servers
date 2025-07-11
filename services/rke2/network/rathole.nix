# doesn't work for some reason, pod exits w/ 0 after attempting to start the config watcher thingy
{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.rathole;
in {
  options.az.svc.rke2.rathole = with azLib.opt; {
    enable = optBool false;
    sopsPath = optStr "rke2/rathole";
    sopsUid = mkOption {
      type = types.ints.positive;
      default = 1885422516; # random number 0-2147483647 - hopefully shouldn't conflict with anything
    };

    remotes = mkOption {
      type = with types;
        listOf (submodule {
          options = {
            enable = optBool true;
            addr = mkOption {type = types.str;};
            pubKey = mkOption {type = types.str;};
          };
        });
      default = [];
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = let
      # cluster-wide
      sopsFile = "${config.az.server.sops.path}/${azLib.reverseFQDN config.networking.domain}/default.yaml";
    in {
      "${cfg.sopsPath}/noise-key" = {inherit sopsFile;};
      "${cfg.sopsPath}/tokens/doq" = {inherit sopsFile;};
      "${cfg.sopsPath}/tokens/http" = {inherit sopsFile;};
      "${cfg.sopsPath}/tokens/https" = {inherit sopsFile;};
      "${cfg.sopsPath}/tokens/http3" = {inherit sopsFile;};
    };
    sops.templates = builtins.listToAttrs (
      lib.lists.imap0 (i: v: {
        name = "${cfg.sopsPath}/rathole-${toString i}.toml";
        value.uid = cfg.sopsUid;
        value.file = (pkgs.formats.toml {}).generate "rathole-${toString i}.toml" {
          client.remote_addr = v.addr;
          client.transport = {
            type = "noise";
            noise = {
              pattern = "Noise_KK_25519_ChaChaPoly_BLAKE2s";
              local_private_key = config.sops.placeholder."${cfg.sopsPath}/noise-key";
              remote_public_key = v.pubKey;
            };
          };
          client.services = {
            doq = {
              type = "udp";
              token = config.sops.placeholder."${cfg.sopsPath}/tokens/doq";
              local_addr = "rathole-doq.app-nameserver.svc:853";
            };
            http = {
              token = config.sops.placeholder."${cfg.sopsPath}/tokens/http";
              local_addr = "[::1]:80";
            };
            https = {
              token = config.sops.placeholder."${cfg.sopsPath}/tokens/https";
              local_addr = "[::1]:443";
            };
            http3 = {
              type = "udp";
              token = config.sops.placeholder."${cfg.sopsPath}/tokens/http3";
              local_addr = "[::1]:443";
            };
          };
        };
      })
      cfg.remotes
    );

    az.server.rke2.manifests."rathole" = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "app-rathole";
        metadata.labels.name = "app-rathole";
      }
      {
        apiVersion = "apps/v1";
        kind = "StatefulSet";
        metadata = {
          name = "rathole";
          namespace = "app-rathole";
        };
        spec = {
          replicas = builtins.length cfg.remotes;
          selector.matchLabels.app = "rathole";
          template.metadata.labels.app = "rathole";

          template.spec.securityContext.runAsUser = cfg.sopsUid;
          template.spec.containers = [
            {
              name = "rathole";
              image = "rapiz1/rathole";
              env = [
                {
                  name = "POD_INDEX";
                  valueFrom.fieldRef.fieldPath = "metadata.labels['apps.kubernetes.io/pod-index']";
                }
              ];
              args = ["--client" "/secrets/rathole-$(POD_INDEX).toml"];
              volumeMounts = [
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
              # since all nodes run off the same flake,
              # this is possible (and *should* be safe)
              # TODO: make sure this actually works well with multiple nodes
              name = "sops-secrets-rendered";
              hostPath = {
                path = "/run/secrets/rendered/${cfg.sopsPath}";
                type = "Directory";
              };
            }
          ];
        };
      }
    ];
  };
}
