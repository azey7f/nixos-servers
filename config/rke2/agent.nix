# TODO - UNTESTED
{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  top = config.az.server.rke2;
  cfg = top.agent;
in {
  options.az.server.rke2.agent = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    services.rke2.role = "agent";
  };
}
