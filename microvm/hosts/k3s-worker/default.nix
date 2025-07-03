{
  pkgs,
  lib,
  azLib,
  ...
}: {
  imports = azLib.scanPath ./.;

  az.microvm.k3s = {
    enable = true;
    agent.enable = true;
  };
}
