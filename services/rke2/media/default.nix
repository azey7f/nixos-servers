{
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.media;
in {
  imports = azLib.scanPath ./.;

  options.az.svc.rke2.media = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.server.rke2.namespaces."app-media" = {
      networkPolicy.fromNamespaces = ["envoy-gateway"];
    };

    services.rke2.manifests."media".content = [
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "media";
          namespace = "app-media";
        };
        spec = {
          accessModes = ["ReadWriteOnce"];
          resources.requests.storage = "10Ti"; # media be big
        };
      }
    ];
  };
}
