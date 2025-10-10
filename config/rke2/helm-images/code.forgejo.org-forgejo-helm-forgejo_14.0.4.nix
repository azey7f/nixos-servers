{pkgs, ...}: {
  # args: oci://code.forgejo.org/forgejo-helm/forgejo --version 14.0.4
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "busybox";
      imageDigest = "sha256:d82f458899c9696cb26a7c02d5568f81c8c8223f8661bb2a7988b269c8b9051e";
      hash = "sha256-njWKOv+If4dqiRTyg3qoFD6RPBWncFUCWtvULWnaeoI=";
      finalImageTag = "latest";
    }
    {
      imageName = "code.forgejo.org/forgejo/forgejo";
      imageDigest = "sha256:ee7f9392f5ea0b12466269a51116f83a923baea0ec86989d6feb5857f9591a33";
      hash = "sha256-aifgRAc72d8Ms5JsSw4+hU69jZqc4iXVT474AXfCGXQ=";
      finalImageTag = "12.0.4-rootless";
    }
  ];
}
