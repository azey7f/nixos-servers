{
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.server.power;
in {
  options.az.server.power = with azLib.opt; {
    ignoreKeys = optBool false;
  };

  config = mkIf cfg.ignoreKeys {
    services.logind = {
      powerKey = "ignore";
      powerKeyLongPress = "ignore";
      rebootKey = "ignore";
      rebootKeyLongPress = "ignore";
    };
  };
}
