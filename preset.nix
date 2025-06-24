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
      /*dns.nameservers = let
        vms = config.az.server.microvm.vms;
        inherit (config.az.server.net) ipv4 ipv6;
      in
        mkDefault [
          "${ipv6.subnet.microvm}::${toString vms.unbound.id}"
          "${ipv4.subnet.microvm}.${toString vms.unbound.id}"
        ];*/
    };
  };

  az.server = {
    disks.zfs.enable = mkDefault true;
    disks.sataMaxPerf = mkDefault true; #hotswap

    #microvm.enable = mkDefault true;

    net.enable = mkDefault true;
    net.frr.enable = mkDefault true;
    net.remoteUnlock = {
      enable = mkDefault true;
      sshPort = mkDefault 47;
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
    ssh.ports = mkDefault [47];
    endlessh.enable = mkDefault true;

    #TODO: cron.enable = mkDefault true;
    #TODO: mail.enable = mkDefault true;
  };
}
