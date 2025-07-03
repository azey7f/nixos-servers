# TODO: IPv6
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
  net = config.az.server.net;
  inherit (net) ipv4 ipv6;
in {
  options.az.server.net.remoteUnlock = with azLib.opt; {
    enable = optBool false;
    sshPort = mkOpt types.port 22;
    dns = optStr "9.9.9.9";
  };

  config = mkIf cfg.enable {
    boot.kernelParams = [
      "ip=${ipv4.address}::${ipv4.gateway}:${azLib.math.subnet.lengthToMask ipv4.subnetSize}:${config.networking.hostName}:${net.interface}:off:${cfg.dns}::"
    ];

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
