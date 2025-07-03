{
  pkgs,
  lib,
  azLib,
  ...
}: {
  imports = azLib.scanPath ./.;

  az.microvm.kubernetes = {
    enable = true;

    etcd.enable = true;

    keepalived.enable = true;
    haproxy.enable = true;

    apiserver.enable = true;
    controllerManager.enable = true;
    scheduler.enable = true;
  };

  environment.systemPackages = with pkgs; [step-cli];
}
