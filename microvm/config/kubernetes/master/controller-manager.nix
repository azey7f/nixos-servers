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
  cfg = top.controllerManager;
  server = outputs.servers.${config.az.microvm.serverName}.config;
in {
  options.az.microvm.kubernetes.controllerManager = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    #TODO: needed? networking.firewall.allowedTCPPorts = [10252];

    systemd.services.kube-controller-manager = {
      serviceConfig.LoadCredential = [
        "kubernetes.pem:/certs/kubernetes.pem"
        "kubernetes.key.pem:/certs/kubernetes.key.pem"
        "service-account.key.pem:/certs/service-account.key.pem"
        "controller-manager.pem:/certs/controller-manager.pem"
        "controller-manager.key.pem:/certs/controller-manager.key.pem"
      ];
    };

    services.kubernetes.controllerManager = {
      enable = true;
      clusterCidr = top.podsSubnet;

      #bindAddress = top.vmAddr;
      bindAddress = "::1";

      serviceAccountKeyFile = "/run/credentials/kube-controller-manager.service/service-account.key.pem";
      #extraOpts = "--service-cluster-ip-range=${top.servicesSubnet} --use-service-account-credentials=true";
      extraOpts = "--service-cluster-ip-range=${top.servicesSubnet} --v=4";

      kubeconfig = {
        certFile = "/run/credentials/kube-controller-manager.service/controller-manager.pem";
        keyFile = "/run/credentials/kube-controller-manager.service/controller-manager.key.pem";
        server = "https://api.${server.networking.domain}";
      };

      tlsCertFile = "/run/credentials/kube-controller-manager.service/kubernetes.pem";
      tlsKeyFile = "/run/credentials/kube-controller-manager.service/kubernetes.key.pem";
    };
  };
}
