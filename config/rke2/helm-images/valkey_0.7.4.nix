{pkgs, ...}: {
  # args: --repo https://valkey.io/valkey-helm valkey --version 0.7.4
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/valkey/valkey";
      imageDigest = "sha256:fea8b3e67b15729d4bb70589eb03367bab9ad1ee89c876f54327fc7c6e618571";
      hash = "sha256-YPvl/uWSARX5jSjgUVtjFSiw+UX6Hryvx7W85++jf/I=";
      finalImageTag = "8.1.3";
    }
  ];
}
