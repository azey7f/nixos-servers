{pkgs, ...}: {
  # args: --repo https://helm.cilium.io cilium --version 1.17.8 --set authentication.mutual.spire.enabled=true --set envoy.enabled=false
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/library/busybox";
      imageDigest = "sha256:d82f458899c9696cb26a7c02d5568f81c8c8223f8661bb2a7988b269c8b9051e";
      hash = "sha256-O+GkFMTRxfRWI6qcvdYMosRa7U/ZM5iaQsxBOiL5OIk=";
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
      imageDigest = "sha256:6d7ea72ed311eeca4c75a1f17617a3d596fb6038d30d00799090679f82a01636";
      hash = "sha256-w++P9ODN+JI35Lh/q322fI+t4oyY2m7rzpUqqYpcBsQ=";
      finalImageTag = "v1.17.8";
    }
    {
      imageName = "quay.io/cilium/operator-generic";
      imageDigest = "sha256:5468807b9c31997f3a1a14558ec7c20c5b962a2df6db633b7afbe2f45a15da1c";
      hash = "sha256-2IibMIkeX2a7mbQ7FhtyPWVjid+JJr7t3FjnAHsOvX8=";
      finalImageTag = "v1.17.8";
    }
  ];
}
