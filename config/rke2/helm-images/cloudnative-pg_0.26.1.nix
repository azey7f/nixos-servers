{pkgs, ...}: {
  # args: --repo https://cloudnative-pg.github.io/charts cloudnative-pg --version 0.26.1
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "ghcr.io/cloudnative-pg/cloudnative-pg";
      imageDigest = "sha256:cfa380de51377fa61122d43c1214d43d3268c3c17da57612ee8fea1d46b61856";
      hash = "sha256-PQjBRv1str2LIqTpQts6CLFnWxlJaAJF0p9TG1hoRks=";
      finalImageTag = "1.27.1";
    }
  ];
}
