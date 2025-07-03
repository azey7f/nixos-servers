{
  config,
  azLib,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.az.server.net.frr;
  inherit (config.az.server) net;
  inherit (net) ipv4 ipv6;
in {
  options.az.server.net.frr = with azLib.opt; {
    enable = optBool false;
    ospf.enable = optBool false;
    extraInterfaces = mkOption {
      type = with types; listOf str;
      default = [];
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.ospf-key = {};

    sops.templates."frr.conf" = {
      content = ''
        ! FRR Configuration
        !
        hostname ${config.networking.hostName}
        	log syslog
        	service password-encryption
        	service integrated-vtysh-config
        !
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
        '') ([net.interface] ++ cfg.extraInterfaces)}
        router ospf
        	ospf router-id ${ipv4.address}
        	redistribute static
        	redistribute kernel
        	redistribute connected
        !
        router ospf6
        	ospf6 router-id ${ipv4.address}
        	redistribute static
        	redistribute kernel
        	redistribute connected
        !
        end
      '';
      owner = "frr";
    };

    services.frr.configFile = config.sops.templates."frr.conf".path;
    services.frr.ospfd.enable = cfg.ospf.enable;
    services.frr.ospf6d.enable = cfg.ospf.enable;
  };
}
