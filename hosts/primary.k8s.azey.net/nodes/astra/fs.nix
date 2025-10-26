{
  lib,
  config,
  ...
}:
with lib; {
  boot = {
    # Mirror to /boot-fallback
    loader.grub.mirroredBoots = [
      {
        devices = [
          /*
          "/dev/disk/by-uuid/A871-4F42"
          */
          "nodev"
        ];
        path = "/boot-fallback";
      }
    ];

    ### ZFS CONFIG ###
    zfs.extraPools = ["hdd"];
    zfs.requestEncryptionCredentials = [
      "nvme"
      "hdd"
      #"archive"
    ];
    kernelParams = ["zfs.zfs_arc_max=34359738368"]; # 32Gi
  };

  ### SANOID ###
  az.server.disks.sanoid = {
    enable = false; # CRITICAL TODO
    datasets = {
      "nvme" = {};
      "hdd/openebs" = {};
    };

    syncoid.commands."nvme" = {
      target = "hdd/backup-nvme";
      recursive = false;
      sendOptions = "Rw"; # recursive, raw
    };
  };

  ### MOUNTS ###
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=24G"
      "mode=755"
    ];
  };

  fileSystems."/var/lib/libvirt" = {
    device = "nvme/libvirt";
    fsType = "zfs";
    #options = ["noexec"];
  };

  fileSystems."/var/lib/rancher/rke2" = {
    device = "nvme/rke2";
    fsType = "zfs";
    #options = ["noexec" "nodev"];
  };

  fileSystems."/etc/nixos" = {
    device = "nvme/nix/nixos";
    fsType = "zfs";
    neededForBoot = true;
    #options = ["noexec" "nodev"];
  };

  fileSystems."/nix" = {
    device = "nvme/nix";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/var/log" = {
    device = "nvme/nix/log";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A7FB-24B0";
    fsType = "vfat";
    #options = ["noexec" "nodev"];
  };

  fileSystems."/boot-fallback" = {
    device = "/dev/disk/by-uuid/A871-4F42";
    fsType = "vfat";
    #options = ["noexec" "nodev"];
  };
}
