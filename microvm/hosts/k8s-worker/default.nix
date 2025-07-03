{
  pkgs,
  lib,
  azLib,
  ...
}: {
  imports = azLib.scanPath ./.;

  az.microvm.kubernetes = {
    enable = true;

    proxy.enable = true;
    coredns.enable = true;
    kubelet.enable = true;
    flannel.enable = true;
  };

  environment.systemPackages = with pkgs; [step-cli];
}
