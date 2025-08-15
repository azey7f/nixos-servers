{
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.music;
in {
  imports = azLib.scanPath ./.;

  options.az.svc.rke2.music = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.server.rke2.namespaces."app-music" = {
      networkPolicy.fromNamespaces = ["envoy-gateway"];
    };

    az.server.rke2.manifests."app-music" = [
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "music";
          namespace = "app-music";
        };
        spec = {
          accessModes = ["ReadWriteOnce"];
          resources.requests.storage = "10Ti"; # FLACs be big
        };
      }
    ];
  };
}
