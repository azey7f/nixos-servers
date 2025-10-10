{pkgs, ...}: {
  # args: oci://docker.io/envoyproxy/gateway-helm --version 1.5.3
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/envoyproxy/gateway";
      imageDigest = "sha256:96ce3e4b7cc6bfd8666e31ed74266ecba708e1c74f29a561aeb650bbc76e1b03";
      hash = "sha256-MfsxBwf6OQu8wdkuBzFGgeuVQQSw8mLi3pqfgSrpGZg=";
      finalImageTag = "v1.5.3";
    }
  ];
}
