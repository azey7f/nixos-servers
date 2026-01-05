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
        imageDigest = "sha256:35f907aa08b6e4574c580e3901df197d420d0ec3081a4f9832fcd5357e4d0ad3";
        hash = "sha256-FlR4M9FcbEYT4hfFKRNtdPZMMsO0kLBvdmDEeymXO+E="; # renovate: ghcr.io/cloudnative-pg/postgresql 14.20
      };
      pg-15 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "15.15";
        imageDigest = "sha256:e85c373e8cdf29a47adfe48e1ea534b20e5dea4b697aad3a0572162b3da43892";
        hash = "sha256-3Kx0TAY0rHpStvC/brPwOeCCgPfmbbqG9rpExTiwaXo="; # renovate: ghcr.io/cloudnative-pg/postgresql 15.15
      };
      pg-16 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "16.11";
        imageDigest = "sha256:368c1a13935ff8850d76cfb427d5c29877a74de0531e198a7a683d4cfb97260b";
        hash = "sha256-d1moKWj8oBYosaBnijo2KhHZZNskTG0g3MxZl6eoZc4="; # renovate: ghcr.io/cloudnative-pg/postgresql 16.11
      };
      pg-17 = {
        imageName = "ghcr.io/cloudnative-pg/postgresql";
        finalImageTag = "17.7";
        imageDigest = "sha256:7e16b46cef57750dccaa68790a0796f58bdcfa26c35775512bb0030452dc2627";
        hash = "sha256-QfQuJqT3EanQt7wny3QQ7x2Oywab4CzncPP5its0tOA="; # renovate: ghcr.io/cloudnative-pg/postgresql 17.7
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
