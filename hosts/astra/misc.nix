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

  networking.firewall.enable = false;

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

  /*
  services.rke2.images = [
    (pkgs.dockerTools.pullImage {
      imageName = "nginx";
      imageDigest = "sha256:3b4019335070fb6445987c8dd72cf18dec2cbc63b3575581eb66469c8173cd4f";
      finalImageTag = "1.28.0";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # renovate: nginx
    })
  ];
  services.rke2.autoDeployCharts = {
    test = {
      repo = "https://helm.github.io/examples";
      name = "hello-world";
      version = "0.0.9";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # renovate: https://helm.github.io/examples hello-world
    };
  };
  services.rke2.autoDeployCharts = {
    test = {
      repo = "oci://tccr.io/truecharts/endlessh";
      version = "12.0.0";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # renovate: tccr.io/truecharts/endlessh
    };
  };
  */
}
