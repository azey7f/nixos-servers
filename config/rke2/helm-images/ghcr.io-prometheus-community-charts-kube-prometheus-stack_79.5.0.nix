{pkgs, ...}: {
  # args: oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack --version 79.5.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/bats/bats";
      imageDigest = "sha256:f9e5272f8ccd9a21554e461c596b08553d052af78e509b8dffbd80ba89a34164";
      hash = "sha256-7lwKAAaviV6ooSFlA6N+6iKJw7gu3mEE33PX7qU38mM=";
      finalImageTag = "v1.4.1";
    }
    {
      imageName = "docker.io/grafana/grafana";
      imageDigest = "sha256:35c41e0fd0295f5d0ee5db7e780cf33506abfaf47686196f825364889dee878b";
      hash = "sha256-W1UMbHsxfDTdPlEm5ecksfMgWsBP+DNhY7cHDA4ymLY=";
      finalImageTag = "12.2.1";
    }
    {
      imageName = "quay.io/kiwigrid/k8s-sidecar";
      imageDigest = "sha256:835d79d8fbae62e42d8a86929d4e3c5eec2e869255dd37756b5a3166c2f22309";
      hash = "sha256-ANZagFsIAerqFLeRFL6JC1gt7O2GpxYd0Ym61uIYDSc=";
      finalImageTag = "1.30.10";
    }
    {
      imageName = "quay.io/prometheus-operator/prometheus-operator";
      imageDigest = "sha256:92757e4b90027e153dc09f2e01254c8402fd5268827d95532760836c2a117062";
      hash = "sha256-UhHDtvBTzVC+x4g5XcWYyxwidxKPOoTv7hO5vW3co/4=";
      finalImageTag = "v0.86.2";
    }
    {
      imageName = "quay.io/prometheus/alertmanager";
      imageDigest = "sha256:88743b63b3e09ea6e31e140ced5bf45f4a8e82c617c2a963f78841f4995ad1d7";
      hash = "sha256-J/Fw7l/bI1OOrzyj/pKMTGe3qZ6DKZ77CjyBjNZxW5Q=";
      finalImageTag = "v0.29.0";
    }
    {
      imageName = "quay.io/prometheus/node-exporter";
      imageDigest = "sha256:337ff1d356b68d39cef853e8c6345de11ce7556bb34cda8bd205bcf2ed30b565";
      hash = "sha256-Us01w7MzoSLV6441UT+TqTZ7pyZubg1KpTi/qfXFQ/o=";
      finalImageTag = "v1.10.2";
    }
    {
      imageName = "quay.io/prometheus/prometheus";
      imageDigest = "sha256:49214755b6153f90a597adcbff0252cc61069f8ab69ce8411285cd4a560e8038";
      hash = "sha256-FiRygVk9FRRKsHA4kpkiDre2ORLYI7CSkV7+odUcBSw=";
      finalImageTag = "v3.7.3";
    }
    {
      imageName = "registry.k8s.io/ingress-nginx/kube-webhook-certgen";
      imageDigest = "sha256:bcfc926ed57831edf102d62c5c0e259572591df4796ef1420b87f9cf6092497f";
      hash = "sha256-UupAvyZMUlJQMZnAMe4QKxPZUw9ejpZ4FQQ57FvmyT0=";
      finalImageTag = "v1.6.4";
    }
    {
      imageName = "registry.k8s.io/kube-state-metrics/kube-state-metrics";
      imageDigest = "sha256:2bbc915567334b13632bf62c0a97084aff72a36e13c4dabd5f2f11c898c5bacd";
      hash = "sha256-EbPn31gp0JHBWR+0tRj8RxOrzwn9k9VC4ECYAipYCbg=";
      finalImageTag = "v2.17.0";
    }
  ];
}
