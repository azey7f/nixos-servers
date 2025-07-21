{
  config,
  azLib,
  sops,
  lib,
  ...
}:
with lib; let
  cfg = config.az.server.sops;
  #inherit (config.networking) hostName;
in {
  options.az.server.sops = with azLib.opt; {
    enable = optBool false;
    path = mkOption {type = types.path;}; # path to private sops submodule, contains a dir for each host
    keyPath = mkOption {
      type = types.path;
      default = "/etc/nixos/age.key"; # .gitignored, should be chmod 0
    };
  };

  config = mkIf cfg.enable {
    systemd.services."create-sops-symlink" = {
      script = ''
        mkdir -p /root/.config/sops/age
        ln -sf ${config.sops.age.keyFile} /root/.config/sops/age/keys.txt 2>/dev/null
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        LogLevelMax = "emerg";
      };
      wantedBy = ["default.target"];
    };

    #sops.validateSopsFiles = false;
    sops.defaultSopsFile = "${cfg.path}/${azLib.reverseFQDN config.networking.fqdn}/default.yaml";
    sops.age.keyFile = cfg.keyPath;
    sops.keepGenerations = 0; # don't delete old gens on `nixos-rebuild switch`, see https://github.com/astro/microvm.nix/issues/239

    # /etc persistent files
    sops.secrets."etc/machine-id" = {};
    sops.secrets."etc/ssh/ssh_host_ed25519_key.pub" = {};
    sops.secrets."etc/ssh/ssh_host_ed25519_key" = {};
    environment.etc."machine-id".source = "/run/secrets/etc/machine-id";
    environment.etc."ssh/ssh_host_ed25519_key".source = "/run/secrets/etc/ssh/ssh_host_ed25519_key";
    environment.etc."ssh/ssh_host_ed25519_key.pub".source = "/run/secrets/etc/ssh/ssh_host_ed25519_key.pub";
  };
}
