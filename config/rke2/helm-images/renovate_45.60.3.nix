{pkgs, ...}: {
  # args: --repo https://docs.renovatebot.com/helm-charts renovate --version 45.60.3 --set renovate.config="{}"
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "ghcr.io/renovatebot/renovate";
      imageDigest = "sha256:f9d9851b3e98590c133279488b66895f3cc550408d9b525d8fa43828419e80d7";
      hash = "sha256-vsh0W4dqJoMoHx9iHPJ/TWDthYFrSrc5LB3sBvBWraA=";
      finalImageTag = "42.66.3";
    }
  ];
}
