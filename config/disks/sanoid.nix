{
  config,
  azLib,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.az.server.disks.sanoid;
in {
  options.az.server.disks.sanoid = with azLib.opt; {
    enable = optBool false;
    datasets = mkOption {
      type = with types;
        attrsOf (submodule ({name, ...}: {
          freeformType = with types; attrsOf anything;
          options = {
            autoprune = optBool true;
            autosnap = optBool true;

            recursive = mkOption {
              type = oneOf [bool (enum ["zfs"])];
              default = "zfs";
            };

            frequent_period = mkOpt ints.positive 6;

            frequently = mkOpt ints.unsigned 10;
            hourly = mkOpt ints.unsigned 24;
            daily = mkOpt ints.unsigned 30;
            monthly = mkOpt ints.unsigned 12;
            yearly = mkOpt ints.unsigned 3;
          };
        }));
      default = [];
    };

    syncoid = {
      enable = optBool true;
      commands = mkOption {
        type = with types;
          attrsOf (submodule ({name, ...}: {
            freeformType = with types; attrsOf anything;
            options = {
              recursive = optBool true;
            };
          }));
        default = [];
      };
    };
  };

  config = mkIf cfg.enable {
    services.sanoid = {
      enable = true;
      interval = "6m";
      datasets = cfg.datasets;
    };

    services.syncoid = mkIf cfg.syncoid.enable {
      enable = true;
      commands = cfg.syncoid.commands;
      commonArgs = [
        "--force-delete"
        "--delete-target-snapshots"
      ];

      localTargetAllow = [
	# defaults
        "compression"
        "create"
        "mount"
        "mountpoint"
        "receive"
        "rollback"

	# custom
	"userprop"
        "canmount"
        "xattr"
        "dnodesize"
        "acltype"
        "relatime"
        "copies"
      ];
    };
  };
}
