{pkgs, ...}: {
  # args: oci://ghcr.io/woodpecker-ci/helm/woodpecker --version 3.4.2
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/woodpeckerci/woodpecker-agent";
      imageDigest = "";
      hash = "";
      finalImageTag = "v3.12.0";
    }
    {
      imageName = "docker.io/woodpeckerci/woodpecker-server";
      imageDigest = "";
      hash = "";
      finalImageTag = "v3.12.0";
    }
  ];
}
