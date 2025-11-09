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
      networkPolicy.toCluster = true; # apiserver
    };

    services.rke2.autoDeployCharts."cnpg" = {
      repo = "https://cloudnative-pg.github.io/charts";
      name = "cloudnative-pg";
      version = "0.26.1";
      hash = "sha256-hkaaSse56AZgLX4ORajhfwjXyifMVbRdWwhOCE6koHU="; # renovate: https://cloudnative-pg.github.io/charts cloudnative-pg 0.26.1

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
          apiVersion = "projectcalico.org/v3";
          kind = "GlobalNetworkPolicy";
          metadata = {
            name = "cnpg";
          };
          spec = {
            selector = "cnpg.io/podRole == 'instance' || cnpg.io/jobRole in { 'initdb', 'import' }";
            egress = [
              # only needs access to the apiserver, but generic
              # access to the cluster subnet is much easier to manage
              {
                action = "Allow";
                destination.nets = ["${config.az.cluster.net.prefix}::/${config.az.cluster.net.prefix}"];
              }
            ];
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
        imageDigest = "sha256:5a0fadda518f766688123a5fcf7d79381f1e1362a571f022827617016aa48db3";
        hash = "sha256-mMltMdsngyz+ir1HVXefRdg7DG81eyLauc6Ihp0eebs="; # renovate: ghcr.io/cloudnative-pg/postgresql 16.10
      };
      pg-17 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "17.6";
        imageDigest = "sha256:fabacad3b63ef8c83117d43b9083aba00a95ae8e42ad5f74c6a10e5e5b057ecf";
        hash = "sha256-0IeaqwKD/b0IaGeiN148W3C3KPlVNT46EKpTCP1/TUo="; # renovate: ghcr.io/cloudnative-pg/postgresql 17.6
      };
      pg-18 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "18.0";
        imageDigest = "sha256:94582762716f62588f3a4e9ca0dea2d73acf4c3f8b1686aa185c35f542c951db";
        hash = "sha256-BxMwnLqoPmbzy7JfO7gab1HkcMGe6qaEei79OrVVSFs="; # renovate: ghcr.io/cloudnative-pg/postgresql 18.0
      };
    };
  };
}
