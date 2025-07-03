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
  cfg = top.proxy;
  server = outputs.servers.${config.az.microvm.serverName}.config;
in {
  options.az.microvm.kubernetes.proxy = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [10256];

    systemd.services.kube-proxy = {
      serviceConfig.LoadCredential = [
        "proxy.pem:/certs/proxy.pem"
        "proxy.key.pem:/certs/proxy.key.pem"
      ];
    };

    services.kubernetes.proxy = let
      certFile = "/run/credentials/kube-proxy.service/proxy.pem";
      keyFile = "/run/credentials/kube-proxy.service/proxy.key.pem";
    in {
      enable = true;
      bindAddress = "::";
      kubeconfig = {
        inherit certFile keyFile;
        server = "https://api.${server.networking.domain}";
      };
    };
  };
}
