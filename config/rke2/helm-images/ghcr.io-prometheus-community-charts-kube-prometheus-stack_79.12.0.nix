{pkgs, ...}: {
  # args: oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack --version 79.12.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/bats/bats";
      imageDigest = "sha256:f9e5272f8ccd9a21554e461c596b08553d052af78e509b8dffbd80ba89a34164";
      hash = "sha256-7lwKAAaviV6ooSFlA6N+6iKJw7gu3mEE33PX7qU38mM=";
      finalImageTag = "v1.4.1";
    }
    {
      imageName = "docker.io/grafana/grafana";
      imageDigest = "sha256:70d9599b186ce287be0d2c5ba9a78acb2e86c1a68c9c41449454d0fc3eeb84e8";
      hash = "sha256-Xb2w+84hqftHblYYEVW0BOwtTK2dADf2+SHhVV8kU6w=";
      finalImageTag = "12.3.0";
    }
    {
      imageName = "quay.io/kiwigrid/k8s-sidecar";
      imageDigest = "sha256:716b0b33ff2dc938a3f2bc64e5ea791d81fb09760bcd27cec1eb896968d6e134";
      hash = "sha256-RtpisI0+q+mon7mBXB0f1U2lI6usv87kK7X1ZBbamJQ=";
      finalImageTag = "2.1.2";
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
      imageDigest = "sha256:d936808bdea528155c0154a922cd42fd75716b8bb7ba302641350f9f3eaeba09";
      hash = "sha256-KF83v0OoDEnwzUdTNpd3092Rkk94IG/57ehr8jAMKZ0=";
      finalImageTag = "v3.8.0";
    }
    {
      imageName = "registry.k8s.io/ingress-nginx/kube-webhook-certgen";
      imageDigest = "sha256:03a00eb0e255e8a25fa49926c24cde0f7e12e8d072c445cdf5136ec78b546285";
      hash = "sha256-7uy74L/+RtE3cRjPPl0cE7/FEe1yL7zTrlMv7JyUCrA=";
      finalImageTag = "v1.6.5";
    }
    {
      imageName = "registry.k8s.io/kube-state-metrics/kube-state-metrics";
      imageDigest = "sha256:2bbc915567334b13632bf62c0a97084aff72a36e13c4dabd5f2f11c898c5bacd";
      hash = "sha256-EbPn31gp0JHBWR+0tRj8RxOrzwn9k9VC4ECYAipYCbg=";
      finalImageTag = "v2.17.0";
    }
  ];
}
