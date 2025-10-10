{pkgs, ...}: {
  # args: --repo https://bokysan.github.io/docker-postfix mail --version 4.4.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "boky/postfix";
      imageDigest = "sha256:f3f247fd42528b969e2603ac120d5a5b5db7dfe61f4505c49d438b9ba1822999";
      hash = "sha256-GcGJRG6qd0MQ0ONLDzvuE2gctjlSlBigFRMea5hVLJE=";
      finalImageTag = "4.4.0";
    }
  ];
}
