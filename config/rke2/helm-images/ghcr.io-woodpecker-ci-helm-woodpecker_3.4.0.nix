{pkgs, ...}: {
  # args: oci://ghcr.io/woodpecker-ci/helm/woodpecker --version 3.4.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/woodpeckerci/woodpecker-agent";
      imageDigest = "sha256:b93edcd626a2f83a0a76e05373cb948b4026ca16f7d6c0909867269f1c181c35";
      hash = "sha256-xF2ca9YUgWJ53IEHxmuWAn7tewsf73L8dHTSE/RIyvo=";
      finalImageTag = "v3.10.0";
    }
    {
      imageName = "docker.io/woodpeckerci/woodpecker-server";
      imageDigest = "sha256:a9f2f5e82c6cef65856abf28e68afdedb706c8286b603341d94aba169225a656";
      hash = "sha256-uAqOmygAtTlOpDVvARnieXlNSZjdDaXuVieQ+NNffOo=";
      finalImageTag = "v3.10.0";
    }
  ];
}
