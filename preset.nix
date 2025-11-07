{
  lib,
  config,
  ...
}:
with lib; {
  users.users.root.hashedPassword = "*";

  az.core = {
    hardening.virtFlushCache = "never"; # only hosts are desktop VMs, which are mostly trusted
    hardening.lockKmodules = false; # cilium does some iptables magic that needs this
    hardening.extraDisabledWrappers = [
      "sendmail" # non-root users shouldn't be sending mail anyways
      "qemu-bridge-helper" # VMs run as root, unnecessary
    ];
    hardening.allowForwarding = mkDefault true;

    firmware.enable = mkDefault true;
    firmware.allowUnfree = mkDefault false;
    boot.loader.grub.enable = mkDefault true;

    libvirt.enable = mkDefault true;

    net = {
      dns.enable = mkDefault true;
    };
  };

  az.cluster.enable = mkDefault true;

  az.server = {
    disks.zfs.enable = mkDefault true;
    disks.sataMaxPerf = mkDefault true; #hotswap

    net.remoteUnlock = {
      enable = mkDefault true;
      sshPort = mkDefault 33;
    };

    programs.enable = mkDefault true;

    sops = {
      enable = mkDefault true;
      path = mkDefault ./sops; # private submodule
    };
  };

  az.svc = {
    ssh.enable = mkDefault true;
    ssh.openFirewall = mkDefault true;
    ssh.ports = mkDefault [33];
    endlessh.enable = mkDefault true;

    cron.enable = mkDefault true;
    mail.enable = mkDefault true;
  };
}
