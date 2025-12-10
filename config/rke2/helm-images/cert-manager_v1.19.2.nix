{pkgs, ...}: {
  # args: --repo https://charts.jetstack.io cert-manager --version v1.19.2
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "quay.io/jetstack/cert-manager-cainjector";
      imageDigest = "sha256:1a24f9848e7ae83a787187f4e75fdf5e9adf401f44de2f156c09c6fae1bf046e";
      hash = "sha256-0GlvEwZk6iJLB54RiwOcSjWtSOHW6kKT0ZtJobGdlSQ=";
      finalImageTag = "v1.19.2";
    }
    {
      imageName = "quay.io/jetstack/cert-manager-controller";
      imageDigest = "sha256:d4ffb81a6d89a0e690ee80d07fcdcb6cccb99118010e3eb0808442e506e18ab0";
      hash = "sha256-n9r+5uugx9+/+JncKX98vw/Q8sGjo6yUTa9wgVqATxM=";
      finalImageTag = "v1.19.2";
    }
    {
      imageName = "quay.io/jetstack/cert-manager-startupapicheck";
      imageDigest = "sha256:677a064065a4809bb1efbd0f160d86fd07a37d72a4c2ec469dac62f663e6d610";
      hash = "sha256-pdr1q3SLR6vDmQ2+vZ7pEBY/PoTEZp+cFAM/SAH6Y+U=";
      finalImageTag = "v1.19.2";
    }
    {
      imageName = "quay.io/jetstack/cert-manager-webhook";
      imageDigest = "sha256:2ba4918d1581ed29bd5d68a017244560b353bcaf9932c814a8713887589bda6c";
      hash = "sha256-6jEKcmDfig+dncGJNBopenCJaUMvS1GfuZ7B5XPJxSY=";
      finalImageTag = "v1.19.2";
    }
  ];
}
