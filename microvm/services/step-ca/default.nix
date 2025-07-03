# TODO: declarative setup via PreExecStart
# SETUP:
#   mkdir ${dataPath}/{pub,db}
#
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
  imports = azLib.scanPath ./.;

  options.az.svc.step-ca = with azLib.opt; {
    enable = optBool false;
    sopsPrefix = optStr "vm/${config.networking.hostName}/step-ca";

    kubernetes = {
      enable = optBool false;
      jwk.x = mkOption {type = types.str;};
      jwk.y = mkOption {type = types.str;};
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      step-cli
    ];

    networking.firewall.allowedTCPPorts = [443];

    # override module settings
    environment.etc."smallstep/ca.json".source = mkForce "/secrets/rendered/step-ca/ca.json";
    systemd.services."step-ca".serviceConfig = {
      # access to settings
      User = mkForce "root";
      Group = mkForce "root";
      ReadWritePaths = mkForce [];
      # TODO: force use of the local source-of-truth DNS resolver
      /*
        ExecStart = mkForce [
        "" # override upstream
        "${pkgs.step-ca}/bin/step-ca /etc/smallstep/ca.json --password-file \${CREDENTIALS_DIRECTORY}/intermediate_password --resolver [${ipv6.subnet.microvm}::${toString vms.nameserver.id}]:53"
      ];
      */
    };

    services.step-ca = {
      enable = true;
      intermediatePasswordFile = "/secrets/step-ca/intermediate_password";
      # dummy values, overriden above
      settings = {};
      address = "";
      port = 0;
    };

    az.microvm.shares = [
      {
        proto = "virtiofs";
        tag = "step-ca";
        source = "/vm/${config.networking.hostName}/step-ca";
        mountPoint = "/etc/step-ca/db"; # hardcoded, system hardening stuff
      }
    ];
  };
}
