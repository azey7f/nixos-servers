{pkgs, ...}: {
  # args: --repo https://docs.renovatebot.com/helm-charts renovate --version 45.52.3 --set renovate.config="{}"
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "ghcr.io/renovatebot/renovate";
      imageDigest = "sha256:c9a185096225e4eaefa2db9095b01b7721f4d2b3a8ad71d8b88804792f676072";
      hash = "sha256-pTRCDEOZqFQuhZlx/wlJ1Sa5Prg/3exBjrbrq9/LHM0=";
      finalImageTag = "42.58.3";
    }
  ];
}
