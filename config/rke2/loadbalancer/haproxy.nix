{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  top = config.az.server.rke2;
  cfg = top.haproxy;
  cluster = outputs.infra.clusters.${config.networking.domain};
in {
  options.az.server.rke2.haproxy = with azLib.opt; {
    enable = optBool false;

    servers = mkOption {
      type = with types; listOf str;
      default = lib.lists.flatten (
        lib.attrsets.mapAttrsToList (serverName: server: (
          let
            conf = outputs.nixosConfigurations.${serverName}.config;
          in
            lib.lists.optional conf.az.server.rke2.server.enable (
              lib.lists.findFirst (addr: (
                lib.lists.any (n: n == "${serverName}.${config.networking.domain}")
                config.networking.hosts.${addr}
              ))
              null (builtins.attrNames config.networking.hosts)
            )
        ))
        cluster.nodes
      );
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [8443];

    services.haproxy = {
      enable = true;
      #bind ${(builtins.elemAt config.services.keepalived.vrrpInstances.rke2.virtualIps 0).addr}:443
      config = ''
              defaults
              	timeout connect 5s
              	timeout client 10s
              	timeout server 10s

              frontend api.${config.networking.domain}
              	mode tcp
        bind :::8443
              	default_backend kube-apiserver

              backend kube-apiserver
              	mode tcp
              	option tcp-check
              	balance roundrobin

              	default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 65536 maxqueue 256 weight 100

              ${lib.strings.concatStringsSep "\n" (
          lib.lists.imap0 (i: ip: "	server backend-${toString i} ${ip}:6443 check") cfg.servers
        )}
      '';
    };
  };
}
