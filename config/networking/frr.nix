{
  config,
  azLib,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.az.server.net.frr;
in {
  options.az.server.net.frr = with azLib.opt; {
    enable = optBool false;
    interfaces = mkOption {
      type = with types; listOf str;
      default = [];
    };
    extraConfig = mkOption {
      type = types.lines;
      default = "";
    };

    ospf = {
      enable = optBool false;
      routerId = mkOption {
        type = types.str;
        default = config.az.server.net.interfaces.${builtins.elemAt cfg.interfaces 0}.ipv4.addr;
      };
      redistribute = mkOption {type = with types; listOf str;};
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.ospf-key = {};

    az.server.net.frr.ospf.redistribute = ["static" "kernel" "connected"]; # defaults set here, so adding something doesn't override everything else
    sops.templates."frr.conf" = {
      content = ''
        ! FRR Configuration
        !
        hostname ${config.networking.hostName}
        	log syslog
        	service password-encryption
        	service integrated-vtysh-config
        !
        ${
          if cfg.ospf.enable
          then ''
            ! OSPF
            !
            key chain lan
            	key 0
            	key-string ${config.sops.placeholder.ospf-key}
            	cryptographic-algorithm hmac-sha-256
            !
            ${lib.strings.concatMapStrings (iface: ''
                interface ${iface}
                	ip ospf area 0.0.0.0
                	ip ospf authentication key-chain lan
                	ipv6 ospf6 area 0.0.0.0
                	ipv6 ospf6 authentication keychain lan
                !
              '')
              cfg.interfaces}
            router ospf
            	ospf router-id ${cfg.ospf.routerId}
            	${lib.strings.concatMapStrings (n: "	redistribute ${n}\n") cfg.ospf.redistribute}
            !
            router ospf6
            	ospf6 router-id ${cfg.ospf.routerId}
            	${lib.strings.concatMapStrings (n: "	redistribute ${n}\n") cfg.ospf.redistribute}
            !
          ''
          else ""
        }
        ${cfg.extraConfig}
        end
      '';
      owner = "frr";
    };

    services.frr.configFile = config.sops.templates."frr.conf".path;
    services.frr.ospfd.enable = cfg.ospf.enable;
    services.frr.ospf6d.enable = cfg.ospf.enable;
  };
}
