{
  config,
  lib,
  azLib,
  ...
}: let
  cfg = config.az.cluster.core.resolver;
in {
  imports = azLib.scanPath ./.;

  options.az.cluster.core.resolver = with azLib.opt; {
    enable = optBool false;
  };
}
