{
  config,
  lib,
  azLib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.az.svc.step-ca;
in {
  config = mkIf cfg.enable {
    az.microvm.sops.secrets = {
      "${cfg.sopsPrefix}/intermediate_password" = {};
      "${cfg.sopsPrefix}/intermediate_key" = {
        format = "binary";
        sopsFile = "../certs/${cfg.intermediateKey}";
      };
    };
  };
}
