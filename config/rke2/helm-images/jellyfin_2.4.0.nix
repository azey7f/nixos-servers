{pkgs, ...}: {
  # args: --repo https://jellyfin.github.io/jellyfin-helm jellyfin --version 2.4.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/jellyfin/jellyfin";
      imageDigest = "sha256:59417f441213e236a9f907d4e71a13472042409d85f9e9310dbdd87ee33d7bd4";
      hash = "sha256-BA9bQ3LW6+DQTyk0DpgLz2bdBZ+ps6/IC+Oy/+wKeHU=";
      finalImageTag = "10.11.0";
    }
  ];
}
