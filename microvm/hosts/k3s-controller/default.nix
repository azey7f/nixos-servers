{
  pkgs,
  lib,
  azLib,
  ...
}: {
  imports = azLib.scanPath ./.;

  az.microvm.k3s = {
    enable = true;

    server.enable = true;
    #server.clusterInit = false;

    keepalived.enable = true;
    haproxy.enable = true;
  };
}
