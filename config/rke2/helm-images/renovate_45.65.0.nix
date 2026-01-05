{pkgs, ...}: {
  # args: --repo https://docs.renovatebot.com/helm-charts renovate --version 45.65.0 --set renovate.config="{}"
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "ghcr.io/renovatebot/renovate";
      imageDigest = "sha256:00b07c100a298085126b9e59f0d0004edb0cf827c22b59f18dd7385399482e9d";
      hash = "sha256-gk2ezYIVI+qUXEOlXDMOR/tvQhQ51qaf4EHUG0zTHEc=";
      finalImageTag = "42.71.0";
    }
  ];
}
