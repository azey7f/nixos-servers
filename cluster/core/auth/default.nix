{
  config,
  lib,
  azLib,
  ...
}: let
  cfg = config.az.cluster.core.auth;
in {
  imports = azLib.scanPath ./.;

  options.az.cluster.core.auth = with azLib.opt; {
    enable = optBool false;
    domain = lib.mkOption {
      type = lib.types.str;
      # must be set
    };
  };
}
