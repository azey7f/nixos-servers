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
      version = "0.25.0";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # renovate: https://cloudnative-pg.github.io/charts cloudnative-pg

      targetNamespace = "cnpg-system";
    };
    services.rke2.manifests."cnpg-network".content = [
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
}
