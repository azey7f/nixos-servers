{
  config,
  lib,
  azLib,
  pkgs,
  unstable,
  ...
}:
with lib; let
  cfg = config.az.server.programs;
in {
  options.az.server.programs = with azLib.opt; {
    enable = optBool false;
    excludedPackages = mkOption {
      type = with types; listOf package;
      default = [];
    };
  };

  config = mkIf cfg.enable {
    ### PACKAGES ###
    environment.systemPackages = with pkgs;
      lists.subtractLists cfg.excludedPackages [
        # security
        ipset

        # backups
        #TODO: unstable.zfs-autobackup

        # misc
        lm_sensors
        virtiofsd
      ];
  };
}
