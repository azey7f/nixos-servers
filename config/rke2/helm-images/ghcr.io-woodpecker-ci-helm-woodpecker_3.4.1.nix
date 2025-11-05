{pkgs, ...}: {
  # args: oci://ghcr.io/woodpecker-ci/helm/woodpecker --version 3.4.1
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/woodpeckerci/woodpecker-agent";
      imageDigest = "sha256:01850e45a126cb369551b9aa78ffc7d612896d28c6dc1b647c7cfaf0fde76474";
      hash = "sha256-GnPyd+nvkRd+38XQUTy1Xl4P65rwa/7NhHQsN+royjY=";
      finalImageTag = "v3.11.0";
    }
    {
      imageName = "docker.io/woodpeckerci/woodpecker-server";
      imageDigest = "sha256:014af3abed4b44db3284ba257409812a53b7085336511d1d298f7e69b22b2857";
      hash = "sha256-E3+yH8IDgG1Up9bkPGNvJJi4c73x4rQkVtXTyawfZVs=";
      finalImageTag = "v3.11.0";
    }
  ];
}
