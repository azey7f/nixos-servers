# CRITICAL TODO: the big rewrite
{
  config,
  azLib,
  pkgs,
  lib,
  sops,
  ...
}:
with lib; let
  cfg = config.az.server.net.remoteUnlock;
in {
  options.az.server.net.remoteUnlock = with azLib.opt; {
    enable = optBool false;
    sshPort = mkOpt types.port 22;
    dns = optStr "9.9.9.9";
  };

  config = mkIf cfg.enable {
    boot.kernelParams = [
      "ip=192.168.0.254::192.168.0.1:255.255.255.0:${config.networking.hostName}:eno1:off:${cfg.dns}::"
    ];

    /*
      boot.initrd.systemd = {
      enable = true;
      network = {
        enable = true;
        networks
      };
    };
    */

    sops.secrets."etc/ssh/ssh_host_ed25519_key.pub.initrd" = {};
    sops.secrets."etc/ssh/ssh_host_ed25519_key.initrd" = {};

    boot.initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        hostKeys = ["/run/secrets/etc/ssh/ssh_host_ed25519_key.initrd"];
        authorizedKeys = config.az.svc.ssh.keys;
        port = cfg.sshPort;
      };
    };

    boot.initrd.network.postCommands = strings.concatStrings [
      # zfs
      (
        if config.az.server.disks.zfs.enable
        then ''
          echo 'zfs load-key -a; zfs mount -a; killall zfs; rm -r /run/secrets' >> /root/.profile
        ''
        else ""
      )

      # TODO: tor for remote access
    ];
  };
}
