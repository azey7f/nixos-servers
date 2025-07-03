# TODO: https://docs.k3s.io/cli/certificate#using-custom-ca-certificates
# TODO: NAT64
{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.microvm.k3s;
  server = outputs.servers.${config.az.microvm.serverName}.config;
  cluster = outputs.infra.clusters.${server.networking.domain};
in {
  imports = azLib.scanPath ./.;

  options.az.microvm.k3s = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    # TODO: wireguard-native transport, whenever I get more than just 1 physical server
    # TODO: https://distribution.github.io/distribution/about/deploying/#run-an-externally-accessible-registry, https://docs.k3s.io/installation/airgap
    networking.firewall.allowedTCPPorts = [10250 7946]; # 7946 for metallb
    networking.firewall.allowedUDPPorts = [8472 7946];
    networking.firewall.enable = mkForce false; # CRITICAL TODO

    systemd.services.k3s.serviceConfig = {
      preStart = "${pkgs.kmod}/bin/modprobe br_netfilter vxlan";
    };

    services.k3s = {
      enable = true;
      tokenFile = "/secrets/k3s/token";
      serverAddr = "https://api.${server.networking.domain}";

      extraFlags = [
        "--node-name=${config.networking.fqdn}"
        "--data-dir=/var/lib/rancher/k3s"
        "--snapshotter=native" # containerd data on virtiofs
        #"--kubelet-arg=resolv-conf=/etc/resolv.conf" # TODO: DNS64
        #"--debug"
      ];
      #extraKubeProxyConfig.mode = "nftables";

      gracefulNodeShutdown.enable = true;
    };

    az.microvm.sops.mountSecrets = mkDefault false; # token is cluster-wide
    az.microvm.sops.secrets."k3s/token" = {sopsFile = "../${azLib.reverseFQDN server.networking.domain}/default.yaml";};
    microvm.shares = [
      {
        proto = "virtiofs";
        tag = "k3s-secrets";
        source = "/run/secrets/k3s";
        mountPoint = "/secrets/k3s";
      }
      {
        proto = "virtiofs";
        tag = "k3s-secrets-rendered";
        source = "/run/secrets/rendered/k3s";
        mountPoint = "/secrets/rendered/k3s";
      }
      {
        proto = "virtiofs";
        tag = "k3s-data";
        source = "/vm/${config.networking.hostName}";
        mountPoint = "/var/lib/rancher/k3s"; # autoDeployCharts are statically put into this dir
      }
    ];
  };
}
