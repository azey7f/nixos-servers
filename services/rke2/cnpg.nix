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
    az.server.rke2.manifests."cnpg" = [
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "cnpg";
          namespace = "kube-system";
        };
        spec = {
          targetNamespace = "cnpg-system";

          repo = "https://cloudnative-pg.github.io/charts";
          chart = "cloudnative-pg";
          version = "0.26.0";
        };
      }

      # for some reason cnpg pods need access to the apiserver
      {
        apiVersion = "cilium.io/v2";
        kind = "CiliumClusterwideNetworkPolicy";
        metadata = {
          name = "cnpg-allow-kubernetes-default";
          namespace = "app-authelia";
        };
        spec = {
          endpointSelector.matchLabels."cnpg.io/podRole" = "instance";
          egress = [
            {toEntities = ["kube-apiserver"];}
          ];
        };
      }
    ];
  };
}
