{
  config,
  azLib,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.az.server.disks;
in {
  options.az.server.disks = with azLib.opt; {
    zfs.enable = optBool false;
    sataMaxPerf = optBool false; # necessary for hotswapping
    standbyOnBoot = {
      enable = optBool false;
      disks = mkOption {
        type = with types; listOf str;
        default = [];
      };
    };
  };

  config = {
    ### ZFS ###
    boot.loader.grub.zfsSupport = mkForce cfg.zfs.enable;
    boot.zfs.package = mkIf cfg.zfs.enable pkgs.zfs_unstable;

    services.zfs = mkIf cfg.zfs.enable {
      trim.enable = mkDefault true;
      autoScrub.enable = mkDefault true;
    };

    ### SATA POWER MODE ###
    systemd.services."set-sata-powermode" = mkIf cfg.sataMaxPerf {
      script = ''
        for policy in /sys/class/scsi_host/host*/link_power_management_policy; do
          echo max_performance > $policy
        done
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      wantedBy = ["default.target"];
    };

    ### DISK STANDBY ###
    systemd.services."set-disks-standby" = mkIf cfg.standbyOnBoot.enable {
      script = ''
        for disk in ${strings.concatStrings (strings.intersperse " " cfg.standbyOnBoot.disks)}; do
          ${pkgs.hdparm}/bin/hdparm -S 6 $disk
          ${pkgs.hdparm}/bin/hdparm -y $disk
        done
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      wantedBy = ["default.target"];
    };
  };
}
