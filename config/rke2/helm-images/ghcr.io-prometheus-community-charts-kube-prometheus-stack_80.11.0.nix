{pkgs, ...}: {
  # args: oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack --version 80.11.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/bats/bats";
      imageDigest = "sha256:f9e5272f8ccd9a21554e461c596b08553d052af78e509b8dffbd80ba89a34164";
      hash = "sha256-7lwKAAaviV6ooSFlA6N+6iKJw7gu3mEE33PX7qU38mM=";
      finalImageTag = "v1.4.1";
    }
    {
      imageName = "docker.io/grafana/grafana";
      imageDigest = "sha256:2175aaa91c96733d86d31cf270d5310b278654b03f5718c59de12a865380a31f";
      hash = "sha256-ooY4rnnQPMUc/Xs5A0t3OO9AhC4PE0f5X3B0jCyXq88=";
      finalImageTag = "12.3.1";
    }
    {
      imageName = "ghcr.io/jkroepke/kube-webhook-certgen";
      imageDigest = "sha256:7a62bba56a7cef38c78ed5eaf62f7feaef5a50460fe5517d120cd402d62fee9c";
      hash = "sha256-54qQlQ6Gf3WPQCDuSzZM4V62YFldU72G2FinD0kKhXI=";
      finalImageTag = "1.7.4";
    }
    {
      imageName = "quay.io/kiwigrid/k8s-sidecar";
      imageDigest = "sha256:a36a5946ea215ca6435a2a7e155a17cc360ac35664ad33fa8f640a1d6786100e";
      hash = "sha256-y22p4nvhNch3J0asAYU+NhssIpyZVS3EdGjuyOGYJAw=";
      finalImageTag = "2.2.1";
    }
    {
      imageName = "quay.io/prometheus-operator/prometheus-operator";
      imageDigest = "sha256:6dbbbbeca6d7b94aa30723bfaa55262e41b9f8c15304c484611c696503840aac";
      hash = "sha256-TT9gW5F4DBn3nGZcediylfnX95WHMh8fK5V0LnPTaC0=";
      finalImageTag = "v0.87.1";
    }
    {
      imageName = "quay.io/prometheus/alertmanager";
      imageDigest = "sha256:abb750ac7b63116761c16dd481ae92496fbe04721686c0920f0fa4d0728cd4a6";
      hash = "sha256-xnwPfU02ier9QoWQWhx7/14GsvZZHxTItFlO5TaX5i4=";
      finalImageTag = "v0.30.0";
    }
    {
      imageName = "quay.io/prometheus/node-exporter";
      imageDigest = "sha256:337ff1d356b68d39cef853e8c6345de11ce7556bb34cda8bd205bcf2ed30b565";
      hash = "sha256-Us01w7MzoSLV6441UT+TqTZ7pyZubg1KpTi/qfXFQ/o=";
      finalImageTag = "v1.10.2";
    }
    {
      imageName = "quay.io/prometheus/prometheus";
      imageDigest = "sha256:2b6f734e372c1b4717008f7d0a0152316aedd4d13ae17ef1e3268dbfaf68041b";
      hash = "sha256-6RtLr0YKkwLJlZCp8PVSjhPXk9XOwZsCv03NLxycv3E=";
      finalImageTag = "v3.8.1";
    }
    {
      imageName = "registry.k8s.io/kube-state-metrics/kube-state-metrics";
      imageDigest = "sha256:2bbc915567334b13632bf62c0a97084aff72a36e13c4dabd5f2f11c898c5bacd";
      hash = "sha256-EbPn31gp0JHBWR+0tRj8RxOrzwn9k9VC4ECYAipYCbg=";
      finalImageTag = "v2.17.0";
    }
  ];
}
