{pkgs, ...}: {
  # args: --repo https://openebs.github.io/openebs openebs --version 4.3.3
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
      imageName = "docker.io/openebs/alpine-bash";
      imageDigest = "sha256:c79b33e93868ad212f096800e672cca7e704bfb5a14ff8d0267fd856d3f88f74";
      hash = "sha256-I9X+0TjKACODmnHDBU6RieswU1ILqV3XWOqrpPFSDW8=";
      finalImageTag = "4.2.0";
    }
    {
      imageName = "docker.io/openebs/alpine-sh";
      imageDigest = "sha256:8f8c7a823a241adfaf18103703f9d172d70550e26c85b1d7a84abde24c5d8afe";
      hash = "sha256-iulrNj5HztHncirPpaAMf/CrtfAp3Pc9zzm2/5JZi7Y=";
      finalImageTag = "4.2.0";
    }
    {
      imageName = "docker.io/openebs/etcd";
      imageDigest = "sha256:2d7b831769734bb97a5c1cfd2fe46e29f422b70b5ba9f9aedfd91300839ac3ee";
      hash = "sha256-YRqWi47IxwJndPAYnuxEaowubPwDByqDGRc6dOcX8Qc=";
      finalImageTag = "3.5.6-debian-11-r10";
    }
    {
      imageName = "docker.io/openebs/kubectl";
      imageDigest = "sha256:7a8d6955f40da47707896368ec4e7f9029ca643986af4ebcf4cbeb7798f0f896";
      hash = "sha256-nxKZY3srOFu4+WaJgLPrVNPvvUbr5i5gu7ZQ13yZynM=";
      finalImageTag = "1.25.15";
    }
    {
      imageName = "docker.io/openebs/mayastor-agent-core";
      imageDigest = "sha256:9fa90d329a16816bf0b15d6b6ed914282dcc9eeabbf4324b38f1008433ee0d52";
      hash = "sha256-D9U4mrTJFQT2yaJiQdMHNfQCnKuw+m/HHRgw4qjUK10=";
      finalImageTag = "v2.9.2";
    }
    {
      imageName = "docker.io/openebs/mayastor-agent-ha-cluster";
      imageDigest = "sha256:7c982655233630f3b5431a37698249f383e763bc40bd30af650392086f675dd2";
      hash = "sha256-YCh34fjcMp7LxGfyv3lPYwflIC0ROPqPJ77KcR1F3kQ=";
      finalImageTag = "v2.9.2";
    }
    {
      imageName = "docker.io/openebs/mayastor-agent-ha-node";
      imageDigest = "sha256:71ac5afca79d0d307c34d8ad98424125dfb3873d229620b3f21e0d15672a318f";
      hash = "sha256-vSM0BwPfMTQfXMWOhrOLDhA+k8X1nYT09BXAdWzZja0=";
      finalImageTag = "v2.9.2";
    }
    {
      imageName = "docker.io/openebs/mayastor-api-rest";
      imageDigest = "sha256:dc5bfbb23f00fe7424a18044c452129e998900fabf6f20964491dec726099cd5";
      hash = "sha256-/11irWTCIhk6mHuvFgoxeAdngMCkrUlFKCz1HQa6aEs=";
      finalImageTag = "v2.9.2";
    }
    {
      imageName = "docker.io/openebs/mayastor-csi-controller";
      imageDigest = "sha256:5bc8c5e626506ebdaa337844f80070fde8e105b1560cc624933c8f76fc8cdaab";
      hash = "sha256-tHc36jH9GU5zL1TKTpQJ1vAGFs42khHF/EZzgMGn+CU=";
      finalImageTag = "v2.9.2";
    }
    {
      imageName = "docker.io/openebs/mayastor-csi-node";
      imageDigest = "sha256:4208c041a2a1ed97575828196187d62aff0d49b8d98c858472d810b55cf8bcb1";
      hash = "sha256-17CfJzQs0ts9Ww6mhlE38nndeT1PdGU5KGITJPiiayY=";
      finalImageTag = "v2.9.2";
    }
    {
      imageName = "docker.io/openebs/mayastor-io-engine";
      imageDigest = "sha256:0bd02e5b942737c952fe13c4aa3e22b19b0cf1d08bd33cf7e849c755b6b728c9";
      hash = "sha256-1PiP+bfHJrM6CuZNpjc6ZuEjsiZBCgl8NmBb7/cE1mM=";
      finalImageTag = "v2.9.2";
    }
    {
      imageName = "docker.io/openebs/mayastor-metrics-exporter-io-engine";
      imageDigest = "sha256:be68fe8f0dc3e317d7384053156139f36b375ab011d9867782c8786c3d2bd2c8";
      hash = "sha256-lx34Gy9aSWsk7Nu/3DNKuqmvCYS77inYkC4dwg5CHDs=";
      finalImageTag = "v2.9.2";
    }
    {
      imageName = "docker.io/openebs/mayastor-obs-callhome-stats";
      imageDigest = "sha256:c57c59ae5d31c3de619c8761f11fcf9c349c586be0231eec841a06fc1cabc97f";
      hash = "sha256-AFbT5gHTvKFHl4vvMa1ZEmFpTjQvdjUyAqxMH05jC8Y=";
      finalImageTag = "v2.9.2";
    }
    {
      imageName = "docker.io/openebs/mayastor-obs-callhome";
      imageDigest = "sha256:cef66b9c5b60447d5b4c36e5f70d3de4be6f2c1023e4c06f5bd871806f97fea5";
      hash = "sha256-kkccgX5YLmpulj/t9jemU7PTMyrr4gEnEd1DtBv1wcc=";
      finalImageTag = "v2.9.2";
    }
    {
      imageName = "docker.io/openebs/mayastor-operator-diskpool";
      imageDigest = "sha256:361ddf5317c7aa2daaac8e9e97093971c606b74dc243271901bebd1c193c141b";
      hash = "sha256-BQgdFyPCGsNryOFSZVP2N3HKUwLoqV5VG/gElXHXqNs=";
      finalImageTag = "v2.9.2";
    }
    {
      imageName = "kiwigrid/k8s-sidecar";
      imageDigest = "sha256:cdb361e67b1b5c4945b6e943fbf5909badaaeb51595eaf75fb7493b3abbbe10f";
      hash = "sha256-cPS3BL8NxZAMauZobrjYFYyjRWq113hLFHyJGZcNOIY=";
      finalImageTag = "1.30.2";
    }
    {
      imageName = "nats";
      imageDigest = "sha256:1a7b320b294218d11b48ddcd1552a18a74ae8790c80ba5372726c58d0a5ee295";
      hash = "sha256-IXAJUCdKoHjism4cwPjlYYOrjrbkj4ufEzVjJ5WKoQ0=";
      finalImageTag = "2.9.17-alpine";
    }
    {
      imageName = "natsio/nats-box";
      imageDigest = "sha256:5719180ba4114f7ff8fdd1ce724f002b2fdbf50a3222a8574d3a5d5122e6bdaa";
      hash = "sha256-AVT3JJp7cEVtBJI2Yg4h9ZDpUdJ477gQWJsEUoahrVE=";
      finalImageTag = "0.13.8";
    }
    {
      imageName = "natsio/nats-server-config-reloader";
      imageDigest = "sha256:e414cc7e6f59575d4b1001b0cae21286ffb3ae3a5d38a6ae4f74550ea638c82f";
      hash = "sha256-SB8io4jLkcqHBitO3mnqK0Qf/8jDnCaJV3DcrPX96pg=";
      finalImageTag = "0.10.1";
    }
    {
      imageName = "natsio/prometheus-nats-exporter";
      imageDigest = "sha256:31c02aac089a0e9bc5cd9bd1726064f8c6bfa771acbef85a8be88a687e87daba";
      hash = "sha256-aU73mnXMqQdkFfR2FQqyXZUMQaxCbpEKTIYfsWRuuoY=";
      finalImageTag = "0.11.0";
    }
    {
      imageName = "openebs/lvm-driver";
      imageDigest = "sha256:bb1497b2fb65108a51ebc77a12a510bd1506a1a01826dd2f63d7f95f6bfaa0d6";
      hash = "sha256-/5WNZbumVMDYu8eEP8TL+IrL/5n4u0Hjaaj2tHKuX1A=";
      finalImageTag = "1.7.0";
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
      imageName = "registry.k8s.io/sig-storage/csi-attacher";
      imageDigest = "sha256:69888dba58159c8bc0d7c092b9fb97900c9ca8710d088b0b7ea7bd9052df86f6";
      hash = "sha256-VX2R9bNtRCJx6HQOE8cFeoV0kbaQm1qnkiMZdwtyYmw=";
      finalImageTag = "v4.8.1";
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
      imageDigest = "sha256:be6a7de1d43dba90710b61bd3d0d8f568654a6adadaeea9188cf4cd3554cbb87";
      hash = "sha256-IsWvGMtcRagx7vI2VESWanvotM5lltiDDdkiN9mJnys=";
      finalImageTag = "v1.11.2";
    }
    {
      imageName = "registry.k8s.io/sig-storage/csi-resizer";
      imageDigest = "sha256:8ddd178ba5d08973f1607f9b84619b58320948de494b31c9d7cd5375b316d6d4";
      hash = "sha256-5IXAXQ+7UOis/PaGZ2jnof8i3clPFTSaar1Dvp/LWD8=";
      finalImageTag = "v1.13.2";
    }
    {
      imageName = "registry.k8s.io/sig-storage/csi-snapshotter";
      imageDigest = "sha256:682d5015146de0f922def125a3be1e2a29c43a3eb45700600e4e0733ec3f5752";
      hash = "sha256-5Glj9nGo1l2QuT+ZhCeXYY+e0XfcnyZHa6mCBWzGXHE=";
      finalImageTag = "v7.0.0";
    }
    {
      imageName = "registry.k8s.io/sig-storage/csi-snapshotter";
      imageDigest = "sha256:dd788d79cf4c1b8edee6d9b80b8a1ebfc51a38a365c5be656986b129be9ac784";
      hash = "sha256-ACytrb/PAMRNq36uaWMI0XaGBBHfetV5TVzBWNkJuek=";
      finalImageTag = "v8.2.0";
    }
    {
      imageName = "registry.k8s.io/sig-storage/snapshot-controller";
      imageDigest = "sha256:2084f69694f0fae24d1a3039e02102beaef3ae912c10e59094449196a63ffb7e";
      hash = "sha256-w0evL9wenqtIhwGh+UCKD+4/YWWjQNIJHJa8G79cxiM=";
      finalImageTag = "v7.0.0";
    }
    {
      imageName = "registry.k8s.io/sig-storage/snapshot-controller";
      imageDigest = "sha256:9dade8f2f3ab29e3919c41b343f8d77b12178ac51f25574d7ed2d45a3e3ef69d";
      hash = "sha256-Jw17rGCa16qWnr0h0K3LR0Ol0h1aV5fUr65nFABNIpM=";
      finalImageTag = "v8.2.0";
    }
  ];
}
