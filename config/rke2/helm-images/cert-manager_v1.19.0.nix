{pkgs, ...}: {
  # args: --repo https://charts.jetstack.io cert-manager --version v1.19.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "quay.io/jetstack/cert-manager-cainjector";
      imageDigest = "sha256:6d9f11f592e44056ba094ab5fcf4ae784da409cc05b50fe1d97fb6cbcdbb7f3d";
      hash = "sha256-+jOgoBWyvOToftb7RJXFXRWFNMOm/8I/ieNxQ/j276o=";
      finalImageTag = "v1.19.0";
    }
    {
      imageName = "quay.io/jetstack/cert-manager-controller";
      imageDigest = "sha256:f9d0d0d8179da47417d2637f4f42070973d7b49d6efa04600cdcf53c5e695074";
      hash = "sha256-m6APwaybH0uhxLmY9CRwmwAI4Wdd5U6kaoj+Roykkio=";
      finalImageTag = "v1.19.0";
    }
    {
      imageName = "quay.io/jetstack/cert-manager-startupapicheck";
      imageDigest = "sha256:9d5a3ab678ad87dfbf87eb14613477bb95b2ac044bd92c2b5acd4ef93c5eb845";
      hash = "sha256-ptWF5eLGfHLuCYZ2BgJ+nhNIiSb7+nDKCFs/8n7+Em8=";
      finalImageTag = "v1.19.0";
    }
    {
      imageName = "quay.io/jetstack/cert-manager-webhook";
      imageDigest = "sha256:2dd540213f4ae8c4f2b5fdac8678fb60e8325420b6dbfb2ab04e2453cbaeb613";
      hash = "sha256-hkJI7TdYLnu64TA6ppiETZqgLieN+KAcJzcO5rX+zzs=";
      finalImageTag = "v1.19.0";
    }
  ];
}
