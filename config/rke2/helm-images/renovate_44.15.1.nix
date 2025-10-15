{pkgs, ...}: {
  # args: --repo https://docs.renovatebot.com/helm-charts renovate --version 44.15.1 --set renovate.config="{}"
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "ghcr.io/renovatebot/renovate";
      imageDigest = "sha256:a2f87b37f544bc8c29a606e683b02ca14e066ee165ff155831d820e87a748406";
      hash = "sha256-hILDOpiPPVoa//6I/m9O02tnbCwCYRND7mbdT8Nhe28=";
      finalImageTag = "41.140.1-full";
    }
  ];
}
