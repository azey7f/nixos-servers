# NOTE: this whole dir is currently unused, because weird bs I can't seem to fix after days of banging my head against a wall. ../k3s is in use instead
{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.microvm.kubernetes;
in {
  imports = azLib.scanPath ./.;

  options.az.microvm.kubernetes = with azLib.opt; {
    enable = optBool false;

    podsSubnet = optStr "fd01::/48"; # TODO
    servicesSubnet = optStr "fd98::/108"; # TODO
  };

  config = mkIf cfg.enable {
    services.kubernetes.caFile = "/etc/ssl/domain-ca.crt";
    environment.systemPackages = with pkgs; [kubectl];
  };
}
