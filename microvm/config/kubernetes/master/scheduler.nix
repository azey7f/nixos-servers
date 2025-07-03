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
  cfg = top.scheduler;
  server = outputs.servers.${config.az.microvm.serverName}.config;
in {
  options.az.microvm.kubernetes.scheduler = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    #TODO: needed? networking.firewall.allowedTCPPorts = [10251];

    systemd.services.kube-scheduler = {
      serviceConfig.LoadCredential = [
        "scheduler.pem:/certs/scheduler.pem"
        "scheduler.key.pem:/certs/scheduler.key.pem"
      ];
    };

    services.kubernetes.scheduler = let
      certFile = "/run/credentials/kube-scheduler.service/scheduler.pem";
      keyFile = "/run/credentials/kube-scheduler.service/scheduler.key.pem";
    in {
      enable = true;

      kubeconfig = {
        inherit certFile keyFile;
        server = "https://api.${server.networking.domain}";
      };
    };
  };
}
