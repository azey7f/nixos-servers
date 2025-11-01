# unused, likely doesn't work as-is
{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  cfg = config.az.cluster.core.frp;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.core.frp = with azLib.opt; {
    enable = optBool false;
    sopsPath = optStr "rke2/frp";

    remotes = lib.mkOption {
      type = with lib.types; listOf types.str;
      default =
        lib.mapAttrsToList (_: v: v.ipv4) config.az.cluster.meta.vps; # rTODO: ipv6
    };

    localIP = optStr (
      if config.az.cluster.core.envoyGateway.gateway.enable
      then config.az.cluster.core.envoyGateway.gateway.addresses.ipv4 # rTODO: ipv6
      else ""
    );
  };

  config = lib.mkIf cfg.enable {
    az.server.rke2.clusterWideSecrets."${cfg.sopsPath}/token" = {};

    az.server.rke2.namespaces."app-frp" = {
      networkPolicy.toNamespaces = ["envoy-gateway" "app-nameserver"];
      networkPolicy.extraEgress = [
        {toCIDR = builtins.map (v: "${v}/32") cfg.remotes;} # rTODO: /128
      ];
    };
    az.server.rke2.namespaces."app-nameserver".networkPolicy.fromNamespaces = ["app-frp"];

    az.server.rke2.images = {
      frpc = {
        imageName = "snowdreamtech/frpc";
        finalImageTag = "0.64";
        imageDigest = "sha256:ad5419c376c38e74fa5e58e65aeff09f1d3c75f65116833ef0901b3026b14e4e";
        hash = "sha256-CC4VaPaLtz0uZxgOIvXbznAZW9af9gsf6hFNm6pirHM="; # renovate: snowdreamtech/frpc 0.64
      };
    };

    az.server.rke2.secrets = [
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "frp-config";
          namespace = "app-frp";
        };
        stringData = builtins.listToAttrs (
          lib.imap0 (i: addr: {
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
                  localIP = "knot-external.app-nameserver.svc";
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
      }
    ];
    services.rke2.manifests."frp".content = [
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
          serviceName = "none";

          template.spec.securityContext = {
            runAsNonRoot = true;
            seccompProfile.type = "RuntimeDefault";
            runAsUser = 65534;
            runAsGroup = 65534;
          };

          template.spec.containers = [
            {
              name = "frp";
              image = images.frpc.imageString;
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
