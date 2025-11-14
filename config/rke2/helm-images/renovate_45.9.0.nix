{pkgs, ...}: {
  # args: --repo https://docs.renovatebot.com/helm-charts renovate --version 45.9.0 --set renovate.config="{}"
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "ghcr.io/renovatebot/renovate";
      imageDigest = "sha256:c6950364d634f956a88238f46510f6a9a77809f3d4427c68110b7bd750afc759";
      hash = "sha256-SaVG6CWzu+zPhSAMXwewTbJPpgn/fdhLEyJnZldJGuk=";
      finalImageTag = "42.11.0";
    }
  ];
}
