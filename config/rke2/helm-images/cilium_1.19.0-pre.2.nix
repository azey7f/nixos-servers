{pkgs, ...}: {
  # args: --repo https://helm.cilium.io cilium --version v1.19.0-pre.2 --set authentication.mutual.spire.enabled=true --set envoy.enabled=false
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/library/busybox";
      imageDigest = "sha256:e3652a00a2fabd16ce889f0aa32c38eec347b997e73bd09e69c962ec7f8732ee";
      hash = "sha256-1TjL/fxdyyDUHHm7ozYztwlAIf9PgoSpoTeA79ybkSU=";
      finalImageTag = "1.37.0";
    }
    {
      imageName = "ghcr.io/spiffe/spire-agent";
      imageDigest = "sha256:5106ac601272a88684db14daf7f54b9a45f31f77bb16a906bd5e87756ee7b97c";
      hash = "sha256-DZ5GxFyp75PbgIIsdOwA5IF1mQgP2qVh4zBrYTl++I4=";
      finalImageTag = "1.9.6";
    }
    {
      imageName = "ghcr.io/spiffe/spire-server";
      imageDigest = "sha256:59a0b92b39773515e25e68a46c40d3b931b9c1860bc445a79ceb45a805cab8b4";
      hash = "sha256-HwPX2v9dMgZvfhT3AFd8gFXcJf21mxeL9dMIXGYU3tc=";
      finalImageTag = "1.9.6";
    }
    {
      imageName = "quay.io/cilium/cilium";
      imageDigest = "sha256:507852b22e347fc1c6c0d2f3bd68096e466cf9022524e5057a648b9505a5e35b";
      hash = "sha256-urN+oEtlVw+kLBCfOLBGoS565Il+CeS9uTOZQNa7cR4=";
      finalImageTag = "v1.19.0-pre.2";
    }
    {
      imageName = "quay.io/cilium/operator-generic";
      imageDigest = "sha256:6da95faf2094a02fd8c0ca023adb3c2a0971f73ca4e365e9b72d005a514609b7";
      hash = "sha256-/iO6S4QGMngQXeOoHeqLknO7tL0daF8sSuim+hu6CWY=";
      finalImageTag = "v1.19.0-pre.2";
    }
  ];
}
