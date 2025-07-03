{
  config,
  azLib,
  lib,
  pkgs,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.microvm;
in {
  imports = azLib.scanPath ./.;

  options.az.microvm = with azLib.opt; {
    enable = optBool false;

    # name without the trailing -${index}, set in flake.nix
    name = mkOption {type = types.str;};
    # index used in hostname, also set in flake.nix
    index = mkOption {type = types.ints.unsigned;};
    # server hostName, also^2 set in flake.nix
    serverName = mkOption {type = types.str;};

    # index in outputs.microvm
    id = mkOption {
      type = types.ints.unsigned;
      default = lists.findFirstIndex (name: name == "${cfg.serverName}:${config.networking.hostName}") null (builtins.attrNames outputs.microvm);
    };

    mem = mkOpt types.numbers.positive 512;
    # shared vcpus
    vcpu = mkOpt types.numbers.positive 2;

    #hypervisor = optStr "cloud-hypervisor";
    hypervisor = optStr "qemu";

    shares = mkOption {
      type = with types; listOf attrs;
      default = [];
    };
    dataShare = optBool false;
  };

  config = let
    hexId = lib.strings.fixedWidthNumber 2 (azLib.math.decToHex cfg.id "");
  in
    mkIf cfg.enable {
      networking.hostId = lib.mkForce "a11c1a${hexId}";
      system.stateVersion = lib.mkForce config.system.nixos.release; # VMs are ephemeral, so stateVersion should always be latest

      microvm = {
        guest.enable = lib.mkForce true;

        inherit (cfg) mem vcpu hypervisor;

        virtiofsd.extraArgs = ["--cache=metadata" "--allow-mmap"];
        #virtiofsd.inodeFileHandles = "prefer";
        virtiofsd.threadPoolSize = "0";

        interfaces = [
          {
            #type = "bridge";
            #bridge = "virbr0";

            type = "tap";

            id = "vmtap${toString cfg.id}";
            mac = "02:00:00:00:00:${hexId}";
          }
        ];

        shares =
          cfg.shares
          ++ [
            {
              proto = "virtiofs";
              tag = "ro-store";
              source = "/nix/store"; # the entire store is world-readable and this config is
              mountPoint = "/nix/.ro-store"; # public, so there's no risk in exposing it to VMs
            }
          ]
          ++ (lib.lists.optional cfg.dataShare {
            proto = "virtiofs";
            tag = "data";
            source = "/vm/${config.networking.hostName}";
            mountPoint = "/data";
          });
      };
    };
}
