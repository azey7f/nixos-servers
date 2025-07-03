{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  top = config.az.microvm.k3s;
  cfg = top.agent;
in {
  options.az.microvm.k3s.agent = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    # this is simpler than it feels like it should be
    services.k3s.role = "agent";
  };
}
