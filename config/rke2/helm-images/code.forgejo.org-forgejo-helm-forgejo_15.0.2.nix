{pkgs, ...}: {
  # args: oci://code.forgejo.org/forgejo-helm/forgejo --version 15.0.2
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "busybox";
      imageDigest = "sha256:e3652a00a2fabd16ce889f0aa32c38eec347b997e73bd09e69c962ec7f8732ee";
      hash = "sha256-ZWoPx67YwxgpquWt3YSLNi1sBqwdypeINcJkoYpwoXk=";
      finalImageTag = "latest";
    }
    {
      imageName = "code.forgejo.org/forgejo/forgejo";
      imageDigest = "sha256:a704cc203d78a854e0887e08fcbd7a45f9bc2b5fd8551c88b914b044792c4b1b";
      hash = "sha256-7iGiNhq4cbb9AxuUiEv9oxQBwPoOVNYedHDHW757a2c=";
      finalImageTag = "13.0.2-rootless";
    }
  ];
}
