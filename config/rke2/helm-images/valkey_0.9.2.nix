{pkgs, ...}: {
  # args: --repo https://valkey.io/valkey-helm valkey --version 0.9.2
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/valkey/valkey";
      imageDigest = "sha256:546304417feac0874c3dd576e0952c6bb8f06bb4093ea0c9ca303c73cf458f63";
      hash = "sha256-Fytwh9dNSRODr0ZsSaqIXGppqVF424C2TW47Uiv0ZWA=";
      finalImageTag = "9.0.1";
    }
  ];
}
