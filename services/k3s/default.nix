{
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.k3s;
in {
  imports = azLib.scanPath ./.;

  options.az.k3s = {
    # options used by microvms for services.k3s.autoDeployCharts and .manifests
    charts = mkOption {
      type = types.attrs;
      default = {};
    };
    manifests = mkOption {
      type = types.attrs;
      default = {};
    };

    # converted into .manifests
    namespaces = mkOption {
      type = with types; listOf str;
      default = [];
    };
  };

  config.az.k3s.manifests = builtins.listToAttrs (map (name: {
      inherit name;
      value = {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = name;
      };
    })
    cfg.namespaces);
}
