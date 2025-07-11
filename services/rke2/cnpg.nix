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
          createNamespace = true;

          chart = "cloudnative-pg";
          repo = "https://cloudnative-pg.github.io/charts";

          valuesContent =
            builtins.toJSON {
            };
        };
      }
    ];
  };
}
