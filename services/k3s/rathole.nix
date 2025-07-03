{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.k3s.rathole;
in {
  options.az.svc.k3s.rathole = with azLib.opt; {
    enable = optBool false;
    key = strOpt "k3s/rathole/noise-key";

    replicas = mkOption {
      type = with types;
        listOf (submodule ({name, ...}: {
          options = {
            enable = optBool true;

            addr = mkOption {type = types.str;};
            pubKey = mkOption {type = types.str;};
          };
        }));
      default = [];
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.${cfg.key} = {
      # cluster-wide
      sopsFile = "${config.az.server.sops.path}/${azLib.reverseFQDN config.networking.domain}/default.yaml";
    };
    sops.templates =
      lib.lists.imap0 (i: v: {
        name = "k3s/rathole/rathole-${i}.toml";
        value = (pkgs.formats.toml {}).generate "rathole-${i}.toml" {
          client.remote_addr = v.addr;
          client.transport = {
            type = "noise";
            noise = {
              pattern = "Noise_KK_25519_ChaChaPoly_BLAKE2s";
              local_private_key = config.sops.placeholder."k3s/rathole/noise-key";
              remote_public_key = v.pubKey;
            };
          };
          client.services = {
            doq = {
              type = "udp";
              token = config.sops.placeholder."vm/nginx/rathole/tokens/doq";
              local_addr = "[${ipv6.subnet.microvm}::${toString vms.nameserver.id}]:853";
            };
            http = {
              token = config.sops.placeholder."vm/nginx/rathole/tokens/http";
              local_addr = "[::1]:80";
            };
            https = {
              token = config.sops.placeholder."vm/nginx/rathole/tokens/https";
              local_addr = "[::1]:443";
            };
            http3 = {
              type = "udp";
              token = config.sops.placeholder."vm/nginx/rathole/tokens/http3";
              local_addr = "[::1]:443";
            };
          };
        };
      })
      cfg.replicas;

    az.k3s.namespaces = ["app-rathole"];
    az.k3s.manifests.rathole.content = {
      apiVersion = "apps/v1";
      kind = "StatefulSet";
      metadata = {
        name = "rathole";
        namespace = "app-rathole";
      };
      spec = {
        replicas = lib.lists.length cfg.replicas;
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
            command = ["rathole" "--client" "/config/rathole-$(POD_INDEX).toml"];
            # TODO
          }
        ];
      };
    };
  };
}
