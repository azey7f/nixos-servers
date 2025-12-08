{pkgs, ...}: {
  # args: oci://code.forgejo.org/forgejo-helm/forgejo --version 15.0.3
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "busybox";
      imageDigest = "sha256:e3652a00a2fabd16ce889f0aa32c38eec347b997e73bd09e69c962ec7f8732ee";
      hash = "sha256-ZWoPx67YwxgpquWt3YSLNi1sBqwdypeINcJkoYpwoXk=";
      finalImageTag = "latest";
    }
    {
      imageName = "code.forgejo.org/forgejo/forgejo";
      imageDigest = "sha256:d47936012f3bd7beca375af625d8c65580f9b781fde63893579a258d5c18f966";
      hash = "sha256-XP/QGaLIDio9DV+cWm5GyaT/nd3iE3r0HS1hqFd09Ng=";
      finalImageTag = "13.0.3-rootless";
    }
  ];
}
