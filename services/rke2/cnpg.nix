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
        imageDigest = "sha256:bdc36b98eb96d0f613fb4570460c57ee27114d2bbfe126d9f29b51766b9ca37e";
        hash = "sha256-H/iNhEy/rIRXId7jDXCtYOcpy0lFRX4ma6uC4UUHqpM="; # renovate: ghcr.io/cloudnative-pg/postgresql 14.19
      };
      pg-15 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "15.14";
        imageDigest = "sha256:15661a17359d2ff46961e03a2a6593d58c779624ba5e684780111c09291b49c8";
        hash = "sha256-f/bQTdODWj2dPGvkDim/llIbTu5dhQn40oDkx+T+lcI="; # renovate: ghcr.io/cloudnative-pg/postgresql 15.14
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
