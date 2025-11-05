{pkgs, ...}: {
  # args: oci://docker.io/envoyproxy/gateway-helm --version 1.5.4
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/envoyproxy/gateway";
      imageDigest = "sha256:2410bed86cb6e3f1cd6b6ec7a0f357eb0b984d0f72423e5f284fcce0fe303aba";
      hash = "sha256-ZY76S9/DOWmAbPCXSrQyApddcUh1ELe0Ho0GZh4tKfk=";
      finalImageTag = "v1.5.4";
    }
  ];
}
