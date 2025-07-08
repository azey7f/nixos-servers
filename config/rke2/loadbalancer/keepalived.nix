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
  cfg = top.keepalived;
  cluster = outputs.infra.clusters.${config.networking.domain};
in {
  options.az.server.rke2.keepalived = with azLib.opt; {
    enable = optBool false;
    interface = optStr config.az.server.net.interface;
  };

  config = mkIf cfg.enable {
    networking.firewall.extraInputRules = ''
      meta l4proto vrrp counter accept
      meta l4proto ospfigp counter accept
    '';
    boot.kernel.sysctl."net.ipv6.ip_nonlocal_bind" = true;

    services.keepalived = {
      enable = true;
      vrrpScripts.kube-apiserver = {
        script = "${pkgs.psmisc}/bin/killall -0 kube-apiserver";
        interval = 1;
        timeout = 1;
        fall = 1;
        user = "root";
      };
      vrrpInstances.rke2 = {
        trackScripts = ["kube-apiserver"];
        interface = cfg.interface;
        priority = 200 + config.az.server.id;
        virtualRouterId = 1;
        virtualIps = [
          {
            addr = let
              # ${cluster's /48 subnet}::ffff
              name = "api.${config.networking.domain}";
            in
              lib.lists.findFirst (addr: (
                lib.lists.any (n: n == name) config.networking.hosts.${addr}
              ))
              null (builtins.attrNames config.networking.hosts);
          }
        ];
        unicastSrcIp = builtins.elemAt config.az.server.net.ipv6.address 0;
        unicastPeers = lib.lists.flatten (
          lib.attrsets.mapAttrsToList (serverName: server: (
            let
              conf = outputs.nixosConfigurations.${serverName}.config;
            in
              lib.lists.optional (conf.az.server.id != config.az.server.id && conf.az.server.rke2.keepalived.enable) (
                lib.lists.findFirst (addr: (
                  lib.lists.any (n: n == "${serverName}.${conf.networking.domain}")
                  config.networking.hosts.${addr}
                ))
                null (builtins.attrNames config.networking.hosts)
              )
          ))
          cluster.nodes
        );
      };
    };
  };
}
