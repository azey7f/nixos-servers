{pkgs, ...}: {
  # args: oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack --version 78.5.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/bats/bats";
      imageDigest = "sha256:f9e5272f8ccd9a21554e461c596b08553d052af78e509b8dffbd80ba89a34164";
      hash = "sha256-7lwKAAaviV6ooSFlA6N+6iKJw7gu3mEE33PX7qU38mM=";
      finalImageTag = "v1.4.1";
    }
    {
      imageName = "docker.io/grafana/grafana";
      imageDigest = "sha256:74144189b38447facf737dfd0f3906e42e0776212bf575dc3334c3609183adf7";
      hash = "sha256-MwW7RazW0GBJe2mg5/KGp+kcMmHKe2orlIWxKarPzvU=";
      finalImageTag = "12.2.0";
    }
    {
      imageName = "quay.io/kiwigrid/k8s-sidecar";
      imageDigest = "sha256:835d79d8fbae62e42d8a86929d4e3c5eec2e869255dd37756b5a3166c2f22309";
      hash = "sha256-ANZagFsIAerqFLeRFL6JC1gt7O2GpxYd0Ym61uIYDSc=";
      finalImageTag = "1.30.10";
    }
    {
      imageName = "quay.io/prometheus-operator/prometheus-operator";
      imageDigest = "sha256:8f132dc8c2e8a5c852e864231fc85bcb8edecea184dfff34c77593f8f454cb06";
      hash = "sha256-4lH/u6Ipg7rEhNbJgs17oy3lXmgPdUCZstIm9VY3w5g=";
      finalImageTag = "v0.86.1";
    }
    {
      imageName = "quay.io/prometheus/alertmanager";
      imageDigest = "sha256:27c475db5fb156cab31d5c18a4251ac7ed567746a2483ff264516437a39b15ba";
      hash = "sha256-8ZuCk3GSdCgcWGkOm1lvVeCVywCmW3yFy2F4lkGczZM=";
      finalImageTag = "v0.28.1";
    }
    {
      imageName = "quay.io/prometheus/node-exporter";
      imageDigest = "sha256:d00a542e409ee618a4edc67da14dd48c5da66726bbd5537ab2af9c1dfc442c8a";
      hash = "sha256-ERdH5bx6U8vljQXiNTHFC4Xq+7SQmldZxmnj/7kJOIE=";
      finalImageTag = "v1.9.1";
    }
    {
      imageName = "quay.io/prometheus/prometheus";
      imageDigest = "sha256:23031bfe0e74a13004252caaa74eccd0d62b6c6e7a04711d5b8bf5b7e113adc7";
      hash = "sha256-kzwA60kxbPozU4hynDHIM+JcmlA8hIz++v97uiRynRY=";
      finalImageTag = "v3.7.2";
    }
    {
      imageName = "registry.k8s.io/ingress-nginx/kube-webhook-certgen";
      imageDigest = "sha256:3d671cf20a35cd94efc5dcd484970779eb21e7938c98fbc3673693b8a117cf39";
      hash = "sha256-RRbAmdQNFTyW3BAvYpBN0wB+zBoDPfzL9HGguDEvV3c=";
      finalImageTag = "v1.6.3";
    }
    {
      imageName = "registry.k8s.io/kube-state-metrics/kube-state-metrics";
      imageDigest = "sha256:2bbc915567334b13632bf62c0a97084aff72a36e13c4dabd5f2f11c898c5bacd";
      hash = "sha256-EbPn31gp0JHBWR+0tRj8RxOrzwn9k9VC4ECYAipYCbg=";
      finalImageTag = "v2.17.0";
    }
  ];
}
