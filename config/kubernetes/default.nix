{
  config,
  azLib,
  lib,
  outputs,
  ...
} @ args:
with lib; let
  cfg = config.az.server.kubernetes;
in {
  options.az.server.kubernetes = with azLib.opt; {
    enable = optBool false;

    # used in ../microvm/services/step-ca
    ca.jwk = {
      x = mkOption {type = types.str;};
      y = mkOption {type = types.str;};
      kid = mkOption {type = types.str;};
    };
  };
}
