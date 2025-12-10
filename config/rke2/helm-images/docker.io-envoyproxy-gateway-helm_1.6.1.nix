{pkgs, ...}: {
  # args: oci://docker.io/envoyproxy/gateway-helm --version 1.6.1
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/envoyproxy/gateway";
      imageDigest = "sha256:5ea6d33ff6952781b18240154f15d2c6c7592144fbfd6457e980da269653837f";
      hash = "sha256-Y5zOE/Td39MzrtltF8p6pzZOFV/5ZizWTcqQ8R5Wkoo=";
      finalImageTag = "v1.6.1";
    }
  ];
}
