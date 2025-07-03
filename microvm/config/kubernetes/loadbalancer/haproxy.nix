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
  cfg = top.haproxy;
  server = outputs.servers.${config.az.microvm.serverName}.config;
  cluster = outputs.infra.clusters.${server.networking.domain};
in {
  options.az.microvm.kubernetes.haproxy = with azLib.opt; {
    enable = optBool false;

    servers = mkOption {
      type = with types; listOf str;
      default = lib.lists.flatten (
        lib.attrsets.mapAttrsToList (serverName: serverV: (
          lib.attrsets.mapAttrsToList (baseName: vm: (
            map (i: let
              name = "${baseName}-${toString i}";
              conf = outputs.microvm."${serverName}:${name}".config;
            in
              lib.lists.optional conf.az.microvm.kubernetes.apiserver.enable (
                lib.lists.findFirst (addr: (
                  lib.lists.any (n: n == "${name}.${serverName}.${server.networking.domain}")
                  config.networking.hosts.${addr}
                ))
                null (builtins.attrNames config.networking.hosts)
              ))
            (lib.lists.range 0 (vm.count - 1))
          ))
          serverV.vms
        ))
        cluster.servers
      );
    };
  };

  config = mkIf cfg.enable {
    networking.usePredictableInterfaceNames = false;

    networking.firewall.allowedTCPPorts = [443];

    services.haproxy = {
      enable = true;
      config = ''
        defaults
        	timeout connect 5s
        	timeout client 10s
        	timeout server 10s

        frontend api.${server.networking.domain}
        	mode tcp
        	bind :::443
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
