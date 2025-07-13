# TODO: https://docs.k3s.io/cli/certificate#using-custom-ca-certificates
{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.server.rke2;
  cluster = outputs.infra.clusters.${config.networking.domain};
in {
  imports = azLib.scanPath ./.;

  options.az.server.rke2 = with azLib.opt; {
    enable = optBool false;

    baseDomain = mkOption {
      type = types.str;
      default = lib.lists.findFirst (domain:
        outputs.infra.domains.${
          domain
        }.clusters ? "${
          lib.strings.removeSuffix ".${domain}" config.networking.domain
        }") ""
      (builtins.attrNames outputs.infra.domains);
    };

    # openssl rand -hex goes brr
    clusterCidr = optStr "10.42.0.0/16,fd01::/48"; # TODO: https://github.com/cilium/cilium/issues/28985
    serviceCidr = optStr "10.43.0.0/16,fd98::/108";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [10250 7946]; # 7946 for metallb
    networking.firewall.allowedUDPPorts = [8472 7946];

    environment.systemPackages = with pkgs; [kubectl cilium-cli];

    # TODO: wireguard-native transport, whenever I get more than just 1 node
    # TODO: https://distribution.github.io/distribution/about/deploying/#run-an-externally-accessible-registry
    # TODO: https://docs.k3s.io/installation/airgap
    services.rke2 = {
      enable = true;
      tokenFile = "/run/secrets/rke2/token";
      serverAddr = "https://api.${config.networking.domain}";

      cisHardening = false; # configured manually

      extraFlags = [
        "--node-name=${config.networking.fqdn}"
        "--disable-kube-proxy" # replaced w/ cilium
        #"--snapshotter=native"
        #"--kubelet-arg=resolv-conf=/etc/resolv.conf"
        #"--debug"
      ];

      #gracefulNodeShutdown.enable = true; # TODO
    };

    sops.secrets."rke2/token" = {
      # cluster-wide
      sopsFile = "${config.az.server.sops.path}/${azLib.reverseFQDN config.networking.domain}/default.yaml";
    };

    # networking
    az.server.net.ipv6.address = [
      "${
        cluster.publicSubnet
      }${
        cluster.nodeSubnet
      }::${
        azLib.math.decToHex (config.az.server.id + 2) ""
      }"
    ];
    networking.hosts =
      lib.attrsets.concatMapAttrs (
        serverName: server: let
          conf = outputs.nixosConfigurations.${serverName}.config;
        in {
          # server
          "${
            cluster.publicSubnet
          }${
            cluster.nodeSubnet
          }::${
            azLib.math.decToHex (conf.az.server.id + 2) ""
          }" = [
            conf.networking.hostName
            conf.networking.fqdn
          ];
          # K8s/K3s API virtual IP, see ./loadbalancer/keepalived.nix
          "${cluster.publicSubnet}::ffff" = ["api.${config.networking.domain}"];
        }
      )
      cluster.nodes;
  };
}
