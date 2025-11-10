{pkgs, ...}: {
  # args: --repo https://docs.renovatebot.com/helm-charts renovate --version 45.3.0 --set renovate.config="{}"
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "ghcr.io/renovatebot/renovate";
      imageDigest = "sha256:2e23cd3d7a140439afd720fe01fef17b2f182cacedb62ff73d2cd3ffd0d5c808";
      hash = "sha256-DY5p9B7uN/jLT6kpjKAl6kNhd/BVG6AMMVmF6lP5Kg8=";
      finalImageTag = "42.4.0";
    }
  ];
}
