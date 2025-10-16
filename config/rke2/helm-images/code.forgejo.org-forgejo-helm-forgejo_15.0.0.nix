{pkgs, ...}: {
  # args: oci://code.forgejo.org/forgejo-helm/forgejo --version 15.0.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "busybox";
      imageDigest = "sha256:2f590fc602ce325cbff2ccfc39499014d039546dc400ef8bbf5c6ffb860632e7";
      hash = "sha256-njWKOv+If4dqiRTyg3qoFD6RPBWncFUCWtvULWnaeoI=";
      finalImageTag = "latest";
    }
    {
      imageName = "code.forgejo.org/forgejo/forgejo";
      imageDigest = "sha256:c4dc04d0dfbb21701a045900a1d177047ebb8fb0f0ee75f2be9233616a3160ae";
      hash = "sha256-xdakAxWQ1F+vSqLPv5E5uzygcuVFI2GGzteqFhFH748=";
      finalImageTag = "13.0.0-rootless";
    }
  ];
}
