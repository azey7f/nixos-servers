# TODO: https://docs.k3s.io/cli/certificate#using-custom-ca-certificates
{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  rke2-k3s-merge,
  ...
}:
with lib; let
  cfg = config.az.server.rke2;
in {
  disabledModules = ["services/cluster/rke2/default.nix" "services/cluster/k3s/default.nix"];
  imports = azLib.scanPath ./. ++ ["${rke2-k3s-merge}/nixos/modules/services/cluster/rancher/default.nix"];

  options.az.server.rke2 = with azLib.opt; {
    enable = optBool false;

    primaryInterface = mkOption {
      type = types.str;
      # must be set
    };
  };

  config = mkIf cfg.enable {
    # https://docs.rke2.io/install/requirements?cni-rules=Cilium
    networking.firewall.allowedTCPPorts = [4240 5001 10250 9345];
    networking.firewall.allowedUDPPorts = [51871];
    networking.firewall.checkReversePath = lib.mkForce false; # doesn't play well with cilium

    environment.systemPackages = with pkgs; [kubectl cilium-cli];

    # combined w/ --disable-default-registry-endpoint, this makes RKE2 use only images
    # provided by nix, and pretty much act as if it was airgapped
    environment.etc."rancher/rke2/registries.yaml".text = ''
      mirrors:
        "*":
    '';

    # TODO: https://distribution.github.io/distribution/about/deploying/#run-an-externally-accessible-registry
    # TODO: https://docs.rke2.io/install/airgap
    services.rke2 = {
      enable = true;
      tokenFile = "/run/secrets/rke2/token";
      serverAddr = "https://api.${config.networking.domain}";
      nodeName = config.networking.fqdn;

      package = pkgs.rke2_1_32;

      cisHardening = true;

      extraFlags = [
        "--disable-kube-proxy" # replaced w/ cilium
        "--disable-default-registry-endpoint" # see environment.etc
        #"--snapshotter=native"
        #"--kubelet-arg=resolv-conf=/etc/resolv.conf"
        #"--debug"
      ];

      images = [
        config.services.rke2.package.images-core-linux-amd64-tar-zst
        # config.services.rke2.package.images-cilium-linux-amd64-tar-zst
      ];

      #gracefulNodeShutdown.enable = true; # TODO
    };

    az.server.rke2.clusterWideSecrets."rke2/token" = {};

    boot.kernelModules = [
      "iptable_raw"
      "iptable_mangle"
      "iptable_filter"
      "iptable_nat"
      "ip6table_raw"
      "ip6table_mangle"
      "ip6table_filter"
      "ip6table_nat"
      # https://github.com/NixOS/nixpkgs/issues/242853
      "xt_mark"
      "xt_comment"
      "xt_multiport"
    ];

    # file watch limit sysctls #TODO: is this really the best solution?
    # https://serverfault.com/questions/1137211/failed-to-create-fsnotify-watcher-too-many-open-files
    boot.kernel.sysctl = {
      "fs.inotify.max_user_watches" = 2099999999;
      "fs.inotify.max_user_instances" = 2099999999;
      "fs.inotify.max_queued_events" = 2099999999;
    };

    # networking
    az.server.net.interfaces.${cfg.primaryInterface}.ipv6.addr = [
      "${
        config.az.cluster.publicSubnet
      }${
        config.az.cluster.nodeSubnet
      }::${
        azLib.math.decToHex config.az.cluster.meta.nodes.${config.networking.hostName}.id ""
      }"
    ];
    networking.hosts =
      lib.attrsets.concatMapAttrs (
        node: nodeMeta: let
          conf = outputs.nixosConfigurations.${node}.config;
        in {
          # server
          "${
            config.az.cluster.publicSubnet
          }${
            config.az.cluster.nodeSubnet
          }::${
            azLib.math.decToHex nodeMeta.id ""
          }" = [
            conf.networking.hostName
            conf.networking.fqdn
          ];
          # K8s/RKE2 API virtual IP, see ./loadbalancer/keepalived.nix
          "${config.az.cluster.publicSubnet}::ffff" = ["api.${config.networking.domain}"];
        }
      )
      config.az.cluster.meta.nodes;
  };
}
