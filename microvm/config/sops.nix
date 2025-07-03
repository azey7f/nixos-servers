{
  config,
  azLib,
  lib,
  ...
}:
with lib; let
  cfg = config.az.microvm.sops;
in {
  # only options are defined, which are then read by the host from outputs.microvm
  # corresponds to config.sops on the host, see ../../config/microvm.nix
  # secrets.*.sopsFile is changed to /etc/nixos/sops/${reversed server FQDN}/${sopsFile}
  #  e.g. example/file on vmhost.internal => /etc/nixos/sops/internal.vmhost/example/file
  #  if not defined, ${hostName}/default.yaml is used
  options.az.microvm.sops = with azLib.opt; {
    secrets = mkOpt types.attrs {};
    templates = mkOpt types.attrs {};

    # not read by host, used for config.sops.placeholder
    extraPlaceholders = mkOption {
      type = with types; listOf str;
      default = [];
    };

    mountSecrets = optBool (cfg.secrets != {});
    mountTemplates = optBool (cfg.templates != {});
  };

  # https://github.com/Mic92/sops-nix/blob/77c423a03b9b2b79709ea2cb63336312e78b72e2/modules/sops/templates/default.nix#L132-L134
  # hasn't changed for 2 years now, let's hope this is stable
  options.sops.placeholder = mkOption {
    type = with types; attrsOf str;
    default = builtins.listToAttrs (builtins.map (name: {
      inherit name;
      value = mkDefault "<SOPS:${builtins.hashString "sha256" name}:PLACEHOLDER>";
    }) ((builtins.attrNames cfg.secrets) ++ cfg.extraPlaceholders));
  };

  config = {
    az.microvm.shares =
      (lib.lists.optional cfg.mountSecrets {
        proto = "virtiofs";
        tag = "secrets";
        source = "/run/secrets/vm/${config.networking.hostName}";
        mountPoint = "/secrets";
      })
      ++ (lib.lists.optional cfg.mountTemplates {
        proto = "virtiofs";
        tag = "secrets-rendered";
        source = "/run/secrets/rendered/vm/${config.networking.hostName}";
        mountPoint = "/secrets/rendered";
      });
  };
}
