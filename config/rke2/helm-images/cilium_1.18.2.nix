{pkgs, ...}: {
  # args: --repo https://helm.cilium.io cilium --version 1.18.2 --set authentication.mutual.spire.enabled=true --set authentication.mutual.spire.install.enabled=true
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/library/busybox";
      imageDigest = "sha256:ab33eacc8251e3807b85bb6dba570e4698c3998eca6f0fc2ccb60575a563ea74";
      hash = "sha256-O+GkFMTRxfRWI6qcvdYMosRa7U/ZM5iaQsxBOiL5OIk=";
      finalImageTag = "1.37.0";
    }
    {
      imageName = "ghcr.io/spiffe/spire-agent";
      imageDigest = "sha256:163970884fba18860cac93655dc32b6af85a5dcf2ebb7e3e119a10888eff8fcd";
      hash = "sha256-Sec7Ht9t3Rd9yPrEYFOdlBS/SPGzfCcTZ7WNjsPB8xQ=";
      finalImageTag = "1.12.4";
    }
    {
      imageName = "ghcr.io/spiffe/spire-server";
      imageDigest = "sha256:34147f27066ab2be5cc10ca1d4bfd361144196467155d46c45f3519f41596e49";
      hash = "sha256-N2Fqn5Ih2Y0OZLK9EpoAy2yqU5axcKbLeu1Ls3Bv47c=";
      finalImageTag = "1.12.4";
    }
    {
      imageName = "quay.io/cilium/cilium-envoy";
      imageDigest = "sha256:7932d656b63f6f866b6732099d33355184322123cfe1182e6f05175a3bc2e0e0";
      hash = "sha256-pYsNIhi5+/wmOu+lHBHEy18AfBbTNIwJnDYAItvnYvA=";
      finalImageTag = "v1.34.7-1757592137-1a52bb680a956879722f48c591a2ca90f7791324";
    }
    {
      imageName = "quay.io/cilium/cilium";
      imageDigest = "sha256:858f807ea4e20e85e3ea3240a762e1f4b29f1cb5bbd0463b8aa77e7b097c0667";
      hash = "sha256-ceTrgHYFk0nAhGRdZEkmEPgbTx8gO4DG6X+OySNbDC4=";
      finalImageTag = "v1.18.2";
    }
    {
      imageName = "quay.io/cilium/operator-generic";
      imageDigest = "sha256:cb4e4ffc5789fd5ff6a534e3b1460623df61cba00f5ea1c7b40153b5efb81805";
      hash = "sha256-ya87PbZaRmgLajp79jA+xbJGk04L5+4yWSqCYVhr/Aw=";
      finalImageTag = "v1.18.2";
    }
  ];
}
