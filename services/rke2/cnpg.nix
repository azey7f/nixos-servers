{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.cnpg;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.cnpg = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.server.rke2.namespaces."cnpg-system" = {
      networkPolicy.extraEgress = [{toEntities = ["kube-apiserver"];}];
    };

    services.rke2.autoDeployCharts."cnpg" = {
      repo = "https://cloudnative-pg.github.io/charts";
      name = "cloudnative-pg";
      version = "0.26.0";
      hash = "sha256-5Um2iHfHjWRaEITwTbrhV6nNhXeMdHbIegf8nEsTmOI="; # renovate: https://cloudnative-pg.github.io/charts cloudnative-pg 0.26.0

      targetNamespace = "cnpg-system";

      extraDeploy = [
        {
          apiVersion = "postgresql.cnpg.io/v1";
          kind = "ClusterImageCatalog";
          metadata = {
            name = "postgresql";
            labels = {
              "images.cnpg.io/family" = "postgresql";
              "images.cnpg.io/type" = "system";
              "images.cnpg.io/publisher" = "cnpg.io";
            };
          };
          spec = {
            images = builtins.map (major: let
              image = config.az.server.rke2.images."pg-${builtins.toString major}";
            in {
              inherit major;
              image = "${image.imageName}:${image.finalImageTag}";
            }) [14 15 16 17 18];
          };
        }

        {
          apiVersion = "cilium.io/v2";
          kind = "CiliumClusterwideNetworkPolicy";
          metadata = {
            name = "cnpg-allow-kubernetes-default";
          };
          spec = {
            endpointSelector.matchLabels."cnpg.io/podRole" = "instance";
            egress = [{toEntities = ["kube-apiserver"];}];
          };
        }
        {
          apiVersion = "cilium.io/v2";
          kind = "CiliumClusterwideNetworkPolicy";
          metadata = {
            name = "cnpg-initdb-allow-kubernetes-default";
          };
          spec = {
            endpointSelector.matchLabels."cnpg.io/jobRole" = "initdb";
            egress = [{toEntities = ["kube-apiserver"];}];
          };
        }
        {
          apiVersion = "cilium.io/v2";
          kind = "CiliumClusterwideNetworkPolicy";
          metadata = {
            name = "cnpg-import-allow-kubernetes-default";
          };
          spec = {
            endpointSelector.matchLabels."cnpg.io/jobRole" = "import";
            egress = [{toEntities = ["kube-apiserver"];}];
          };
        }
      ];
    };

    az.server.rke2.images = {
      pg-14 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "14.19";
        imageDigest = "sha256:188a1ae91c689be7d0e958bc985647498a84055b5d1c580e96d030b55f68eca7";
        hash = "sha256-oLgdMxDT2t2pPnIuGoAYkLvgyjivqGvrf0i0yX3LG5M="; # renovate: ghcr.io/cloudnative-pg/postgresql 14.19
      };
      pg-15 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "15.14";
        imageDigest = "sha256:1db6ff2e7bbd12dcb77a4e840948cfd17f9e031df6a184151bcbe5f47e15bb43";
        hash = "sha256-ldMQDJJ4FAusk8oI4iihS7Gt1AqwRJ/o5El4NC5pTl0="; # renovate: ghcr.io/cloudnative-pg/postgresql 15.14
      };
      pg-16 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "16.10";
        imageDigest = "sha256:697e6d8e15ace744fe3b0035d4ea633d3a2b2e59138e8a0481014e924dd1b4d4";
        hash = "sha256-bw4D9/gVJ0QA9n5XqLrb/fC1PZphwPEipYCkABK4OXU="; # renovate: ghcr.io/cloudnative-pg/postgresql 16.10
      };
      pg-17 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "17.6";
        imageDigest = "sha256:8d39f0643fef1dacbbc50bf0b26a0b6e8f3bb354e8ac3bfaefb99e2f96027ad8";
        hash = "sha256-AXFGHHB2xajrGPgOd8I79X1OY0kDwdiYF3D09OBAZ2k="; # renovate: ghcr.io/cloudnative-pg/postgresql 17.6
      };
      pg-18 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "18.0";
        imageDigest = "sha256:acf136a97dea92d9121eba67b1ddf5548b7ec0ecab241d74bdb9945808aa8263";
        hash = "sha256-1Dzw1uok+n0AiZ/OYR+y4fap+JGALl1L8gX2pxdRL1w="; # renovate: ghcr.io/cloudnative-pg/postgresql 18.0
      };
    };
  };
}
