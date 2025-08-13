{
  lib,
  config,
  ...
}:
with lib; {
  az.core = {
    firmware.enable = mkDefault true;
    firmware.allowUnfree = mkDefault false;
    boot.loader.grub.enable = mkDefault true;

    hardening.allowForwarding = mkDefault true;

    libvirt.enable = mkDefault true;

    net = {
      dns.enable = mkDefault true;
      /*
        dns.nameservers = let
        vms = config.az.server.microvm.vms;
        inherit (config.az.server.net) ipv4 ipv6;
      in
        mkDefault [
          "${ipv6.subnet.microvm}::${toString vms.unbound.id}"
          "${ipv4.subnet.microvm}.${toString vms.unbound.id}"
        ];
      */
    };
  };

  az.server = {
    disks.zfs.enable = mkDefault true;
    disks.sataMaxPerf = mkDefault true; #hotswap

    net = {
      enable = mkDefault true;
      frr.enable = mkDefault true;
      remoteUnlock = {
        enable = mkDefault true;
        sshPort = mkDefault 33;
      };
    };

    programs.enable = mkDefault true;

    sops = {
      enable = mkDefault true;
      path = mkDefault ./sops; # private submodule
    };
  };

  az.svc = {
    ssh.enable = mkDefault true;
    ssh.openFirewall = mkDefault false;
    ssh.ports = mkDefault [33];
    endlessh.enable = mkDefault true;

    cron.enable = mkDefault true;
    mail.enable = mkDefault true;
  };
}
