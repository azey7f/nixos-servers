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
in {
  options.az.server.rke2.keepalived = with azLib.opt; {
    enable = optBool false;
    interface = mkOption {
      type = types.str;
      default = top.primaryInterface;
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.extraInputRules = ''
      meta l4proto vrrp counter accept
      meta l4proto ospfigp counter accept
    '';
    boot.kernel.sysctl."net.ipv6.ip_nonlocal_bind" = true;

    services.keepalived = {
      enable = true;
      enableScriptSecurity = true;
      extraGlobalDefs = "script_user root";
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
        priority = 200 + config.az.cluster.meta.nodes.${config.networking.hostName}.id;
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
        unicastSrcIp = builtins.elemAt config.az.server.net.interfaces.${cfg.interface}.ipv6.addr 0;
        unicastPeers = lib.lists.flatten (
          lib.attrsets.mapAttrsToList (node: nodeMeta: (
            let
              selfMeta = config.az.cluster.meta.nodes.${config.networking.hostName};
              conf = outputs.nixosConfigurations.${node}.config;
            in
              lib.lists.optional (selfMeta.id != nodeMeta.id && conf.az.server.rke2.keepalived.enable) (
                lib.lists.findFirst (addr: (
                  lib.lists.any (n: n == "${node}.${conf.networking.domain}")
                  config.networking.hosts.${addr}
                ))
                null (builtins.attrNames config.networking.hosts)
              )
          ))
          config.az.cluster.meta.nodes
        );
      };
    };
  };
}
