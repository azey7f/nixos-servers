{pkgs, ...}: {
  # args: --repo https://cloudnative-pg.github.io/charts cloudnative-pg --version 0.27.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "ghcr.io/cloudnative-pg/cloudnative-pg";
      imageDigest = "sha256:34198e85b6e6dd81471cb1c3ee222ca5231b685220e7ae38a634d35ed4826a40";
      hash = "sha256-xgZUWm5QdDsyjQwHQ4DWH1bpGSYUM0z17XKjR9WErHc=";
      finalImageTag = "1.28.0";
    }
  ];
}
