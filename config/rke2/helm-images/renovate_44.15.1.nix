{pkgs, ...}: {
  # args: --repo https://docs.renovatebot.com/helm-charts renovate --version 44.15.1 --set renovate.config="{}"
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "ghcr.io/renovatebot/renovate";
      imageDigest = "sha256:9c70b9ee7010e5428710c52c37d6385e6420a1385205bd7e7e2048dafc802404";
      hash = "sha256-32kMMwWb7uOXM5kHAp4ipN3KkZUfdZ2JM1uoYPPnvGA=";
      finalImageTag = "41.140.1";
    }
  ];
}
