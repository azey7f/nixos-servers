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
      version = "0.27.0";
      hash = "sha256-ObGgzQzGuWT4VvuMgZzFiI8U+YX/JM868lZpZnrFBGw="; # renovate: https://cloudnative-pg.github.io/charts cloudnative-pg 0.27.0

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
                destination.nets = ["${config.az.cluster.net.prefix}00::/${toString config.az.cluster.net.prefixSize}"];
              }
            ];
          };
        }
      ];
    };

    az.server.rke2.images = {
      pg-14 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "14.20";
        imageDigest = "sha256:3745da250c974e898f3a4fd15f2dd93ccd6b468ae7978f690a18255cc56f7da0";
        hash = "sha256-j49cbKcIUuZPq2tphYetm4zbWe65VASV7c9lPUEAFgE="; # renovate: ghcr.io/cloudnative-pg/postgresql 14.20
      };
      pg-15 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "15.15";
        imageDigest = "sha256:c06035efb7dc46eea28cf0e4770a7043805c9c0f4681e63069929789c83ee89a";
        hash = "sha256-8wFW4hZI4nF3IjEak7c6xkGxQSGtjeJ45OYmh7uynyk="; # renovate: ghcr.io/cloudnative-pg/postgresql 15.15
      };
      pg-16 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "16.11";
        imageDigest = "sha256:2e4d845e4fc5ef8f08d503433139a81cd52277374d93fd20a2166a1dae9e71b1";
        hash = "sha256-+oujBCxo8nqjOEdvIYH4gKdaCgp0luBfDt4mwTOvbmU="; # renovate: ghcr.io/cloudnative-pg/postgresql 16.11
      };
      pg-17 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "17.7";
        imageDigest = "sha256:45f838c60984508f755986642e7108db09d1c4bb6f1bc38186efdb4e003173dc";
        hash = "sha256-o2VvE/e4Iux91iL6gi0RdEr2G8elZrnI2RutGMDgJHk="; # renovate: ghcr.io/cloudnative-pg/postgresql 17.7
      };
      pg-18 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "18.1";
        imageDigest = "sha256:7f374e054e46fdefd64b52904e32362949703a75c05302dca8ffa1eb78d41891";
        hash = "sha256-DlOUjOVyL2/KtWD9fZ2wtBUWkXs08uzCXC28rjS2GtQ="; # renovate: ghcr.io/cloudnative-pg/postgresql 18.1
      };
    };
  };
}
