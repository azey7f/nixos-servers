{pkgs, ...}: {
  # args: --repo https://cloudnative-pg.github.io/charts cloudnative-pg --version 0.26.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "ghcr.io/cloudnative-pg/cloudnative-pg";
      imageDigest = "sha256:9e5633b36f1f3ff0bb28b434ce51c95fbb8428a4ab47bc738ea403eb09dbf945";
      hash = "sha256-urcMBhBEH9+USWQnUP5xERr45iBOjhdZs8zrErBtOK4=";
      finalImageTag = "1.27.0";
    }
  ];
}
