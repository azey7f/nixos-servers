{pkgs, ...}: {
  # args: --repo https://bokysan.github.io/docker-postfix mail --version 5.1.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "boky/postfix";
      imageDigest = "sha256:aafc772384232497bed875e1eb66b4d3e54ba1ebc86e2e185a6dc1dbc48182ef";
      hash = "sha256-TeClfWRs/1hnA9Mh361eNwQaf2oDwGe3Ulsg6HOUBhU=";
      finalImageTag = "5.1.0";
    }
  ];
}
