{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  az.svc.ssh.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhEXbX8s18h6eUmXh8c7b6zZtUAgZGRrEiFZcLYY8gg grapheneos"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4AA0SE0Q9I8d4U1aXeLcGhp1httDnwdsuRJPiKAi5f main@Apollo"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXOe3PWMsjyWrXBG1hv1YSmNUNGBBLLWOJeqDGXoyhS main@Hyperion"
  ];

  #svc.tor.enable = true;

  az.core.libvirt.hugepages = {
    enable = true;
    count = 48;
  };

  az.server = {
    power.ignoreKeys = true;

    /*
    disks.standbyOnBoot = {
      enable = true;
      disks = [
        "/dev/disk/by-id/ata-WDC_WD102KRYZ-01A5AB0_VCG675TN"
        "/dev/disk/by-id/ata-WDC_WD102KRYZ-01A5AB0_VCG8623N"
        "/dev/disk/by-id/ata-WDC_WD102KRYZ-01A5AB0_VCGEBXPM"
        "/dev/disk/by-id/ata-WDC_WD102KRYZ-01A5AB0_VCGH2EZM"
      ];
    };
    */
  };
}
