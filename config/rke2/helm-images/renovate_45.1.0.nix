{pkgs, ...}: {
  # args: --repo https://docs.renovatebot.com/helm-charts renovate --version 45.1.0 --set renovate.config="{}"
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "ghcr.io/renovatebot/renovate";
      imageDigest = "sha256:b2041aef89449c8a2fe184bcd4443e036362d4405ce4993a52b893140776fdd1";
      hash = "sha256-q9iZ+nYxgwa8X+zpIL8cCxBlZAGs946z2hrBxSvf4vI=";
      finalImageTag = "42.2.0";
    }
  ];
}
