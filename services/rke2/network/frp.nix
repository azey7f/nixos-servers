{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.frp;
in {
  options.az.svc.rke2.frp = with azLib.opt; {
    enable = optBool false;
    sopsPath = optStr "rke2/frp";
    sopsUid = mkOption {
      type = types.ints.positive;
      default = 2119299456; # random number 0-2147483647 - hopefully shouldn't conflict with anything
    };

    remotes = mkOption {
      type = with types; listOf types.str;
      default = builtins.map (v: v.ipv6) outputs.infra.domains.${config.az.server.rke2.baseDomain}.vps;
    };

    localIP = optStr config.az.svc.rke2.envoyGateway.addresses.ipv6;
  };

  config = mkIf cfg.enable {
    sops.secrets."${cfg.sopsPath}/token" = {
      # cluster-wide
      sopsFile = "${config.az.server.sops.path}/${azLib.reverseFQDN config.networking.domain}/default.yaml";
    };
    sops.templates = builtins.listToAttrs (
      lib.lists.imap0 (i: addr: {
        name = "${cfg.sopsPath}/frp-${toString i}.toml";
        value.uid = cfg.sopsUid;
        value.file = (pkgs.formats.toml {}).generate "frp-${toString i}.toml" {
          auth.token = config.sops.placeholder."${cfg.sopsPath}/token";

          serverAddr = addr;
          serverPort = 444;

          loginFailExit = false;
          log.disablePrintColor = true;
          transport.tls.enable = false;

          proxies = [
            {
              name = "doq";
              type = "udp";
              localIP = "knot.app-nameserver.svc";
              localPort = 853;
              remotePort = 8853;
            }
            {
              name = "http";
              type = "tcp";
              localIP = cfg.localIP;
              localPort = 80;
              remotePort = 80;
            }
            {
              name = "https";
              type = "tcp";
              localIP = cfg.localIP;
              localPort = 443;
              remotePort = 443;
            }
            {
              name = "http3";
              type = "udp";
              localIP = cfg.localIP;
              localPort = 443;
              remotePort = 443;
            }
          ];
        };
      })
      cfg.remotes
    );

    az.server.rke2.manifests."frp" = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "app-frp";
        metadata.labels.name = "app-frp";
      }
      {
        apiVersion = "apps/v1";
        kind = "StatefulSet";
        metadata = {
          name = "frp";
          namespace = "app-frp";
        };
        spec = {
          replicas = builtins.length cfg.remotes;
          selector.matchLabels.app = "frp";
          template.metadata.labels.app = "frp";

          template.spec.securityContext.runAsUser = cfg.sopsUid;
          template.spec.containers = [
            {
              name = "frp";
              image = "snowdreamtech/frpc";
              env = [
                {
                  name = "POD_INDEX";
                  valueFrom.fieldRef.fieldPath = "metadata.labels['apps.kubernetes.io/pod-index']";
                }
              ];
              args = ["-c" "/secrets/frp-$(POD_INDEX).toml"];
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
