{pkgs, ...}: {
  # args: --repo https://charts.jetstack.io cert-manager --version v1.19.1
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "quay.io/jetstack/cert-manager-cainjector";
      imageDigest = "sha256:c7898aece8fb08102fca0b37683e37cb94e0a77c0d15b8e3c9128f6c04c868e0";
      hash = "sha256-og2C+PkWQM6iO8Ju6SwzwQHOlL1N2GeLzaA0SYyuNE0=";
      finalImageTag = "v1.19.1";
    }
    {
      imageName = "quay.io/jetstack/cert-manager-controller";
      imageDigest = "sha256:cd49e769e18ada1fd7b9a9bacc87c90db24c65cbfd4bf71694dda7ed40e91187";
      hash = "sha256-3eqdevADxKwGxJSzfIslJdg8jTEE5633W5R6vg64j9I=";
      finalImageTag = "v1.19.1";
    }
    {
      imageName = "quay.io/jetstack/cert-manager-startupapicheck";
      imageDigest = "sha256:96a82fa28b14fa0307377111f17adeb5888e313c60445074a775b495dbb07d08";
      hash = "sha256-sGc1JuGeZzfZssnn95fbH9W0o3zMJs5Uv/e7WYIQsts=";
      finalImageTag = "v1.19.1";
    }
    {
      imageName = "quay.io/jetstack/cert-manager-webhook";
      imageDigest = "sha256:f5bfe77541e38978aec53cc6eb924d190e1fe923c98b2582e6ccf5edf6c02cce";
      hash = "sha256-/9SgAhaSpsZOA2uMdIDfdPhSC/PXJW1pl0LBniyg3h8=";
      finalImageTag = "v1.19.1";
    }
  ];
}
