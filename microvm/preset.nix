{
  lib,
  config,
  ...
}:
with lib; {
  az.core.home.enable = false;

  az.microvm = {
    enable = true;
    net.enable = mkDefault true;
  };

  az.svc = {
    ssh.enable = mkDefault true;
    ssh.openFirewall = mkDefault true;
  };
}
