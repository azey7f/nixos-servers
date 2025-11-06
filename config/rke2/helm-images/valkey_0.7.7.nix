{pkgs, ...}: {
  # args: --repo https://valkey.io/valkey-helm valkey --version 0.7.7
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/valkey/valkey";
      imageDigest = "sha256:81db6d39e1bba3b3ff32bd3a1b19a6d69690f94a3954ec131277b9a26b95b3aa";
      hash = "sha256-PotKDvZKJIxd1zXlBkM3lwHq44f0ZKaEqk1TlQP26mU=";
      finalImageTag = "8.1.4";
    }
  ];
}
