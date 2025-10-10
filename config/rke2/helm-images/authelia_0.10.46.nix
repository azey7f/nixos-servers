{pkgs, ...}: {
  # args: --repo https://charts.authelia.com authelia --version 0.10.46
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "ghcr.io/authelia/authelia";
      imageDigest = "sha256:08776367d54d4482c54ac8ca75b18f7db3287b751106e19736780c5f6811374d";
      hash = "sha256-Lvy85H38O+8tHiwtk+Ai9MhJeQytxvEfhEUsKfh9LGI=";
      finalImageTag = "4.39.6";
    }
  ];
}
