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
  cfg = top.coredns;
  server = outputs.servers.${config.az.microvm.serverName}.config;
in {
  options.az.microvm.kubernetes.coredns = with azLib.opt; {
    enable = optBool false;
    upstreams = mkOption {
      type = with types; listOf str;
      default = [
        "[2606:4700:4700::64]:53" # TODO
      ];
    };
  };

  config = mkIf cfg.enable {
    az.core.net.dns = {
      enable = true;
      nameservers = ["::1"];
    };

    systemd.services.coredns = {
      serviceConfig.LoadCredential = [
        "coredns.pem:/certs/coredns.pem"
        "coredns.key.pem:/certs/coredns.key.pem"
      ];
    };

    services.coredns = let
      certFile = "/run/credentials/coredns.service/coredns.pem";
      keyFile = "/run/credentials/coredns.service/coredns.key.pem";
    in {
      enable = true;
      config = ''
        .:53 {
          kubernetes cluster.local {
            endpoint https://api.${server.networking.domain}
            tls ${certFile} ${keyFile} /etc/ssl/domain-ca.crt
            pods verified
          }
          forward . ${lib.strings.concatStringsSep " " cfg.upstreams}
        }
      '';
    };

    services.kubernetes.kubelet.clusterDns = [top.vmAddr];
  };
}
