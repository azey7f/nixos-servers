{pkgs, ...}: {
  # args: oci://docker.io/envoyproxy/gateway-helm --version 1.6.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/envoyproxy/gateway";
      imageDigest = "sha256:b3039fac0a6db481554db18ec953ee6736844935ec89385fac933b275afd3636";
      hash = "sha256-2qSUHYWidrhmUufOvpP+BdTFW7VOTnlds6V6iZ/CCS8=";
      finalImageTag = "v1.6.0";
    }
  ];
}
