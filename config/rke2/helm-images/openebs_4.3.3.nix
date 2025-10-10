{pkgs, ...}: {
  # args: --repo https://openebs.github.io/openebs openebs --version 4.3.3 --set engines.replicated.mayastor.enabled=false --set engines.local.lvm.enabled=false --set engines.local.zfs.enabled=true
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "docker.io/grafana/alloy";
      imageDigest = "sha256:7790f6f7fbd8e4486b4b6c6fc6a7293a73605bb79aaa7f49003cb366943724f6";
      hash = "sha256-VJ0u5mF+3nCWlPngrgpJ8SoKk4RK7hOydB/aJDreCIY=";
      finalImageTag = "v1.8.1";
    }
    {
      imageName = "docker.io/grafana/loki";
      imageDigest = "sha256:58a6c186ce78ba04d58bfe2a927eff296ba733a430df09645d56cdc158f3ba08";
      hash = "sha256-bSG6i2ePbp1X6YdDQFpNMNByCvPOn4jQZbd2KVDzeTY=";
      finalImageTag = "3.4.2";
    }
    {
      imageName = "docker.io/openebs/kubectl";
      imageDigest = "sha256:7a8d6955f40da47707896368ec4e7f9029ca643986af4ebcf4cbeb7798f0f896";
      hash = "sha256-nxKZY3srOFu4+WaJgLPrVNPvvUbr5i5gu7ZQ13yZynM=";
      finalImageTag = "1.25.15";
    }
    {
      imageName = "kiwigrid/k8s-sidecar";
      imageDigest = "sha256:cdb361e67b1b5c4945b6e943fbf5909badaaeb51595eaf75fb7493b3abbbe10f";
      hash = "sha256-cPS3BL8NxZAMauZobrjYFYyjRWq113hLFHyJGZcNOIY=";
      finalImageTag = "1.30.2";
    }
    {
      imageName = "openebs/provisioner-localpv";
      imageDigest = "sha256:e898af5631b64cba55be0d478cee3f422cdaf03e95c55f95d38193cac5dc1fe6";
      hash = "sha256-wGK6l+MU067PygfXkR3ZtFnHKxyM7FsPYiILYlpp7ks=";
      finalImageTag = "4.3.0";
    }
    {
      imageName = "openebs/zfs-driver";
      imageDigest = "sha256:e2284cf97d0c47e79267731bdf9e71f0ca1ae529a6a541f222b66e5d5b794edd";
      hash = "sha256-6PNLwj37Jd1wQ6tC6Blg+9cRZZE4lvooPLSmBojFJ+4=";
      finalImageTag = "2.8.0";
    }
    {
      imageName = "quay.io/minio/mc";
      imageDigest = "sha256:993e8c454a7ec632923f7e3e61adf1d473261da6354cefd641aedd33a2cfe112";
      hash = "sha256-NN72Mn1ssOgycJ0nGtaKCKu7SR6KZC1tSX6S2tVD+pI=";
      finalImageTag = "RELEASE.2024-11-21T17-21-54Z";
    }
    {
      imageName = "quay.io/minio/minio";
      imageDigest = "sha256:1dce27c494a16bae114774f1cec295493f3613142713130c2d22dd5696be6ad3";
      hash = "sha256-YkE+S5AKQIrZwriMnc7btYgyy7dgVZvbHhlSFUp9ywQ=";
      finalImageTag = "RELEASE.2024-12-18T13-15-44Z";
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
