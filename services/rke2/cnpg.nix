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
              image = "${image.imageName}:${image.finalTag}@${image.imageDigest}";
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
        finalImageTag = "14.0";
        imageDigest = "sha256:0000000000000000000000000000000000000000000000000000000000000000";
        hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # renovate: ghcr.io/cloudnative-pg/postgresql 14.0
      };
      pg-15 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "15.0";
        imageDigest = "sha256:b17624c2185567f4caca2f847e7a000b38ecac932e05851888a5738aa0a37725";
        hash = "sha256-hHADHlwMDh17Gil30HcTxaziwXtdDDhctMLIPwplqdI="; # renovate: ghcr.io/cloudnative-pg/postgresql 15.0
      };
      pg-16 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "16.0";
        imageDigest = "sha256:5baf99e0fb30a051d8e108eeecb558af65a7119e068a280641873a2b98e35457";
        hash = "sha256-4mYlCGKPh67Xy53slBKOtCJau4KJKln/ku7S0DuQcxk="; # renovate: ghcr.io/cloudnative-pg/postgresql 16.0
      };
      pg-17 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "17.0";
        imageDigest = "sha256:0a198589e4edca8f169399dd4d082e18de47d289c5f2b7670c9d7bbd9e6f323b";
        hash = "sha256-oDAbcaSFY6IFLeG8ikLA0PuIC4Sw+fFpoK8RkogQU68="; # renovate: ghcr.io/cloudnative-pg/postgresql 17.0
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
