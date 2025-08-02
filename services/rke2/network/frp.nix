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

    remotes = mkOption {
      type = with types; listOf types.str;
      default =
        builtins.map (
          v: v.ipv4
          /*
          # TODO: ipv6
          */
        )
        outputs.infra.domains.${config.az.server.rke2.baseDomain}.vps;
    };

    localIP = optStr config.az.svc.rke2.envoyGateway.addresses.ipv6;
  };

  config = mkIf cfg.enable {
    sops.secrets."${cfg.sopsPath}/token" = {
      # cluster-wide
      sopsFile = "${config.az.server.sops.path}/${azLib.reverseFQDN config.networking.domain}/default.yaml";
    };

    az.server.rke2.manifests."frp" = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "app-frp";
        metadata.labels.name = "app-frp";
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "frp-config";
          namespace = "app-frp";
        };
        stringData = builtins.listToAttrs (
          lib.lists.imap0 (i: addr: {
            name = "frp-${toString i}.json";
            value = builtins.toJSON {
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
                  localPort = 8080;
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

          template.spec.securityContext = {
            runAsNonRoot = true;
            seccompProfile.type = "RuntimeDefault";
            runAsUser = 65532;
            runAsGroup = 65532;
          };

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
              args = ["-c" "/config/frp-$(POD_INDEX).json"];
              volumeMounts = [
                {
                  name = "frp-config";
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
              name = "frp-config";
              secret.secretName = "frp-config";
            }
          ];
        };
      }
    ];
  };
}
