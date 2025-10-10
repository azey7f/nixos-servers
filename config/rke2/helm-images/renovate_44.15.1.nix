{pkgs, ...}: {
  # args: --repo https://docs.renovatebot.com/helm-charts renovate --version 44.15.1
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
  ];
}
