{pkgs, ...}: {
  # args: oci://ghcr.io/woodpecker-ci/helm/woodpecker --version 3.4.2
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/woodpeckerci/woodpecker-agent";
      imageDigest = "sha256:db9d81027e876412703782136591df85efa887c9fafd62b69e4f2d666ea56a7e";
      hash = "sha256-op/uQN6a7sNDZMBeZKHX3bmmYifpJuIpKpaHSP9EVjI=";
      finalImageTag = "v3.12.0";
    }
    {
      imageName = "docker.io/woodpeckerci/woodpecker-server";
      imageDigest = "sha256:0b8e96d89d96aa71b95487e4be84e9dbcd86d89d2e89b3a8de24360510063b4e";
      hash = "sha256-y6iv9fSpf024xCvWQOUgiqDc/l3YB6h9Oa7Im1Nujj8=";
      finalImageTag = "v3.12.0";
    }
  ];
}
