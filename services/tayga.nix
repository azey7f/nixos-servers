{
  config,
  azLib,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.az.svc.tayga;
in {
  options.az.svc.tayga = with azLib.opt; {
    enable = optBool false;
    ipv4.subnet = optStr "10.66.0";
    ipv4.subnetSize = mkOpt types.ints.positive 16;
    ipv6.subnet = mkOption {type = types.str;};
  };

  config = mkIf cfg.enable {
    services.tayga = {
      enable = true;
      ipv6 = rec {
        address = "${cfg.ipv6.subnet}::1";
        router.address = "${cfg.ipv6.subnet}::";
        pool = {
          address = "64:ff9b::";
          prefixLength = 96;
        };
      };
      ipv4 = rec {
        address = "${cfg.ipv4.subnet}.1";
        router.address = "${cfg.ipv4.subnet}.0";
        pool = {
          address = router.address;
          prefixLength = cfg.ipv4.subnetSize;
        };
      };
    };
  };
}
