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
        finalImageTag = "15.14";
        imageDigest = "sha256:d17bae91908c8a6beeae0feba64d26cc2dbf8b6477db87093ee3de9f05f5ac75";
        hash = "sha256-dOdnH7pgsdnjN+KNf/kqmM+tM2wZyS24JaZJXbwT+Fc="; # renovate: ghcr.io/cloudnative-pg/postgresql 15.14
      };
      pg-16 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "16.10";
        imageDigest = "sha256:6287f6497c8c7495305900b79b7aa8d0c9515fa9d3614eff81650068f4d9bacf";
        hash = "sha256-Jqo4KxJzgHPsImjJDPoRx7c65ICa+Qs/cX5g4vES/KM="; # renovate: ghcr.io/cloudnative-pg/postgresql 16.10
      };
      pg-17 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "17.6";
        imageDigest = "sha256:30b304a2e300ed80b6d1b740e4369e9b0f25599fb518de78c01fd9f25531791b";
        hash = "sha256-YcdgG5p64rDPRrZpctOO0UuiiDMELoPAdKROMtl50n0="; # renovate: ghcr.io/cloudnative-pg/postgresql 17.6
      };
      pg-18 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "18.0";
        imageDigest = "sha256:f06cae6ae14e2f101392130dce800b504bf9c5110b5db5fc0266782464882dbb";
        hash = "sha256-M0q0+WsJv88D93a1VSnS58F8vv6OOQx87qlN1PpLzpo="; # renovate: ghcr.io/cloudnative-pg/postgresql 18.0
      };
    };
  };
}
