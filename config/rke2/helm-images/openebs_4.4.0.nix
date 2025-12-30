{pkgs, ...}: {
  # args: --repo https://openebs.github.io/openebs openebs --version 4.4.0 --set engines.replicated.mayastor.enabled=false --set engines.local.lvm.enabled=false --set engines.local.zfs.enabled=true --set loki.enabled=false
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/grafana/alloy";
      imageDigest = "sha256:7790f6f7fbd8e4486b4b6c6fc6a7293a73605bb79aaa7f49003cb366943724f6";
      hash = "sha256-VJ0u5mF+3nCWlPngrgpJ8SoKk4RK7hOydB/aJDreCIY=";
      finalImageTag = "v1.8.1";
    }
    {
      imageName = "docker.io/openebs/provisioner-localpv";
      imageDigest = "sha256:a9f0aa574700379fd56f7597be4493fab1bd2423e8a5eaca4eeafd377763e9df";
      hash = "sha256-rdtzRm2+Bh9uwb/vPHpyKdvmLmk8ttGBltgIlypV85Y=";
      finalImageTag = "4.4.0";
    }
    {
      imageName = "docker.io/openebs/zfs-driver";
      imageDigest = "sha256:1f74d09d6e6e2aeb10e048a5214bbadda2bf29602428a534e98bb0a4b1c3be05";
      hash = "sha256-4RWx17eyjG21vrFR1EhqfJF/+ekSc2ypkVCVqRGvyiU=";
      finalImageTag = "2.9.0";
    }
    {
      imageName = "quay.io/prometheus-operator/prometheus-config-reloader";
      imageDigest = "sha256:959d47672fbff2776a04ec62b8afcec89e8c036af84dc5fade50019dab212746";
      hash = "sha256-M6icjqAoMG3v7GjO4pakn1QIj0gwA2m8CROIKJxzSG4=";
      finalImageTag = "v0.81.0";
    }
    {
      imageName = "registry.k8s.io/sig-storage/csi-node-driver-registrar";
      imageDigest = "sha256:d7138bcc3aa5f267403d45ad4292c95397e421ea17a0035888850f424c7de25d";
      hash = "sha256-JVMOQ7ojd0Fv4yTYlnd50reQnrMIotZVqTvISZVQbSs=";
      finalImageTag = "v2.13.0";
    }
    {
      imageName = "registry.k8s.io/sig-storage/csi-provisioner";
      imageDigest = "sha256:d5e46da8aff7d73d6f00c761dae94472bcda6e78f4f17b3802dc89d44de0111b";
      hash = "sha256-XYepSw41itj0ShPRSpgsmaeVuc6Jb+vgNwWVSnrsWn0=";
      finalImageTag = "v5.2.0";
    }
    {
      imageName = "registry.k8s.io/sig-storage/csi-resizer";
      imageDigest = "sha256:8ddd178ba5d08973f1607f9b84619b58320948de494b31c9d7cd5375b316d6d4";
      hash = "sha256-5IXAXQ+7UOis/PaGZ2jnof8i3clPFTSaar1Dvp/LWD8=";
      finalImageTag = "v1.13.2";
    }
    {
      imageName = "registry.k8s.io/sig-storage/csi-snapshotter";
      imageDigest = "sha256:dd788d79cf4c1b8edee6d9b80b8a1ebfc51a38a365c5be656986b129be9ac784";
      hash = "sha256-ACytrb/PAMRNq36uaWMI0XaGBBHfetV5TVzBWNkJuek=";
      finalImageTag = "v8.2.0";
    }
    {
      imageName = "registry.k8s.io/sig-storage/snapshot-controller";
      imageDigest = "sha256:9dade8f2f3ab29e3919c41b343f8d77b12178ac51f25574d7ed2d45a3e3ef69d";
      hash = "sha256-Jw17rGCa16qWnr0h0K3LR0Ol0h1aV5fUr65nFABNIpM=";
      finalImageTag = "v8.2.0";
    }
  ];
}
