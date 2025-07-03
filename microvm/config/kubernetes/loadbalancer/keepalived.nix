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
  cfg = top.keepalived;
  server = outputs.servers.${config.az.microvm.serverName}.config;
  cluster = outputs.infra.clusters.${server.networking.domain};
in {
  options.az.microvm.kubernetes.keepalived = with azLib.opt; {
    enable = optBool false;
    interface = optStr "eth0";
    sopsPrefix = optStr "vm/${config.networking.hostName}";
  };

  config = mkIf cfg.enable {
    networking.usePredictableInterfaceNames = false;

    networking.firewall.extraInputRules = ''
      meta l4proto vrrp counter accept
      meta l4proto ospfigp counter accept
    '';
    boot.kernel.sysctl."net.ipv6.ip_nonlocal_bind" = true;

    services.keepalived = {
      enable = true;
      vrrpInstances.k8s = {
        interface = cfg.interface;
        priority = 200 + config.az.microvm.id;
        virtualRouterId = 1;
        virtualIps = [
          {
            addr = let
              # ${subnet}::fffe, see ../../../config/microvm.nix
              name = "api.${server.networking.domain}";
            in
              lib.lists.findFirst (addr: (
                lib.lists.any (n: n == name) config.networking.hosts.${addr}
              ))
              null (builtins.attrNames config.networking.hosts);
          }
        ];
        unicastSrcIp = top.vmAddr;
        unicastPeers = lib.lists.flatten (
          lib.attrsets.mapAttrsToList (serverName: serverV: (
            lib.attrsets.mapAttrsToList (baseName: vm: (
              map (i: let
                name = "${baseName}-${toString i}";
                conf = outputs.microvm."${serverName}:${name}".config;
              in
                lib.lists.optional conf.az.microvm.kubernetes.keepalived.enable (
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

    az.microvm.sops.extraPlaceholders = ["ospf-key"]; # defined on host
    az.microvm.sops.templates."${cfg.sopsPrefix}/frr.conf" = {
      content = ''
        ! FRR Configuration
        !
        hostname ${config.networking.hostName}
               log syslog
               service password-encryption
               service integrated-vtysh-config
        !
        ! OSPF
        !
        key chain lan
        	key 0
               	key-string ${config.sops.placeholder.ospf-key}
               	cryptographic-algorithm hmac-sha-256
        !
        interface ${cfg.interface}
               	ipv6 ospf6 area 0.0.0.0
               	ipv6 ospf6 authentication keychain lan
        !
        router ospf6
               	ospf6 router-id 0.0.0.${toString config.az.microvm.id}
               	redistribute static
               	redistribute kernel
               	redistribute connected
        !
        end
      '';
      owner = "frr";
    };

    services.frr.configFile = "/secrets/rendered/frr.conf";
    services.frr.ospf6d.enable = true;
  };
}
