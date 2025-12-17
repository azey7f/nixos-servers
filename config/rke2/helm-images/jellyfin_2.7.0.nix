{pkgs, ...}: {
  # args: --repo https://jellyfin.github.io/jellyfin-helm jellyfin --version 2.7.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/jellyfin/jellyfin";
      imageDigest = "sha256:6d819e9ab067efcf712993b23455cc100ee5585919bb297ea5a109ac00cb626e";
      hash = "sha256-FFLvz0G6I4nFqBDJmKsVm9G8AiMnGZ3EjFVbfUyUInI=";
      finalImageTag = "10.11.5";
    }
  ];
}
