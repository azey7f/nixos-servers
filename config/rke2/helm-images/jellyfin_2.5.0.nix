{pkgs, ...}: {
  # args: --repo https://jellyfin.github.io/jellyfin-helm jellyfin --version 2.5.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/jellyfin/jellyfin";
      imageDigest = "sha256:d43a8878689311f841a1967f899f54db56877bf6b426fd7ff870ac1a6fd1dce4";
      hash = "sha256-n4NM1z+oC9Z3bmvkLquNCW8LB6lUP5gpQ9/4au7I6wE=";
      finalImageTag = "10.11.2";
    }
  ];
}
