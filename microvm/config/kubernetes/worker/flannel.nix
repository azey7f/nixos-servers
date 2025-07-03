{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  top = config.az.microvm.kubernetes;
  cfg = top.flannel;
  server = outputs.servers.${config.az.microvm.serverName}.config;

  kubeconfig = config.services.kubernetes.lib.mkKubeConfig "flannel" {
    certFile = "/run/credentials/flannel.service/flannel.pem";
    keyFile = "/run/credentials/flannel.service/flannel.key.pem";
    caFile = config.services.kubernetes.caFile;
    server = "https://api.${server.networking.domain}";
  };
in {
  options.az.microvm.kubernetes.flannel = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    boot.kernelModules = ["br_netfilter"];
    networking.firewall.allowedUDPPorts = [8285 8472];

    systemd.services.flannel = {
      serviceConfig = {
        LoadCredential = [
          "flannel.pem:/certs/flannel.pem"
          "flannel.key.pem:/certs/flannel.key.pem"
        ];
        ReadWritePaths = ["/run/flannel"];
        /*
          ExecStart = mkForce [
          "" # override upstream
          "${pkgs.flannel}/bin/flannel -v=10"
        ];
        */
      };

      preStart = "${pkgs.kmod}/bin/modprobe br_netfilter";
      path = with pkgs; [nftables];
    };

    services.flannel = {
      enable = true;
      storageBackend = "kubernetes";

      network = "10.0.0.0/8"; # dummy addr, unused
      extraNetworkConfig = {
        EnableIPv4 = false;

        EnableIPv6 = true;
        IPv6Network = top.podsSubnet;
        EnableNFTables = true;
      };

      inherit kubeconfig;
    };

    services.kubernetes.kubelet.cni.config = [
      {
        name = "pods";
        type = "flannel";
        cniVersion = "0.3.1";
        delegate = {
          isDefaultGateway = true;
          bridge = "pods";
        };
      }
    ];
  };
}
