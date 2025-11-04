{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  cfg = config.az.cluster.core.cnpg;
in {
  options.az.cluster.core.cnpg = with azLib.opt; {
    enable = optBool false;
  };

  config = lib.mkIf cfg.enable {
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
            name = "cnpg-instance";
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
            name = "cnpg-initdb";
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
            name = "cnpg-import";
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
        imageDigest = "sha256:4be85e17083d2d4e7a72b3e21589e2755154d5a95ca0c814a9e88696f2731996";
        hash = "sha256-bFJIAxGVy1zp/STgWropR9BAFG1cUxY+rfKxwOVHn18="; # renovate: ghcr.io/cloudnative-pg/postgresql 14.19
      };
      pg-15 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "15.14";
        imageDigest = "sha256:3dfa1cd4b2ea13470c103b5417e0be3fd1f60f9fcc81935fac9f9965349a6762";
        hash = "sha256-rNvyGJdxmhICiiWy8KWnCB5M8vZfQC71jEI2pjSVBVY="; # renovate: ghcr.io/cloudnative-pg/postgresql 15.14
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
        imageDigest = "sha256:b7f2855c5a419249e30d64616da38cbb7ed3397a21cb115a581a02da8cb21ee0";
        hash = "sha256-2cU3nSSi+lQIHXlS3t3TLqyytFv6dq3kWP4+gA4ie3k="; # renovate: ghcr.io/cloudnative-pg/postgresql 17.6
      };
      pg-18 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "18.0";
        imageDigest = "sha256:5f67a8c8ae429c8af5692024ad58408a3f70223bf5d1cb9f9dbc36dcead88919";
        hash = "sha256-sNqekaRSdOHQK/UNqToBpzh/SXqLpJGL6z1XMlAwY6o="; # renovate: ghcr.io/cloudnative-pg/postgresql 18.0
      };
    };
  };
}
