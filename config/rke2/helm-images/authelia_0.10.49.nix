{pkgs, ...}: {
  # args: --repo https://charts.authelia.com authelia --version 0.10.49
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "ghcr.io/authelia/authelia";
      imageDigest = "sha256:7adc2a95b6a4be9332f6a420fdf59c7031bff203d1046ab80d8fbd66f5b1095f";
      hash = "sha256-oMsovNl2ovpsNDbpMxULUaFL/KROJYQ6HJkeVMA4U+s=";
      finalImageTag = "4.39.13";
    }
  ];
}
