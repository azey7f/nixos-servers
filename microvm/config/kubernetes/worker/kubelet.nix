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
  cfg = top.kubelet;
  server = outputs.servers.${config.az.microvm.serverName}.config;
in {
  options.az.microvm.kubernetes.kubelet = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [10250];

    /*
      # TODO: overlayfs: upper fs does not support tmpfile
      # probably solve this with an external cache of some kind
      microvm.shares = [
      {
        proto = "virtiofs";
        tag = "k8s-containerd";
        source = "/vm/${config.networking.hostName}/containerd";
        mountPoint = "/var/lib/containerd";
      }
    ];
    */

    systemd.services.kubelet.serviceConfig = {
      LoadCredential = [
        "kubelet.pem:/certs/kubelet.pem"
        "kubelet.key.pem:/certs/kubelet.key.pem"
      ];
      ReadWritePaths = lib.lists.optional top.flannel.enable "/run/flannel";
    };

    # core/config/hardening.nix conflicts with the kubelet module
    boot.kernel.sysctl."net.ipv4.ip_forward" = mkForce true;

    services.kubernetes.kubelet = let
      certFile = "/run/credentials/kubelet.service/kubelet.pem";
      keyFile = "/run/credentials/kubelet.service/kubelet.key.pem";
    in {
      enable = true;
      unschedulable = false;

      address = "::";
      hostname = config.networking.fqdn;

      extraOpts = "--v=4";

      tlsCertFile = certFile;
      tlsKeyFile = keyFile;

      kubeconfig = {
        inherit certFile keyFile;
        server = "https://api.${server.networking.domain}";
      };
    };
  };
}
