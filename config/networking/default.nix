# TODO: probably rework all of this at some point
{
  config,
  azLib,
  lib,
  unstable,
  ...
}:
with lib;
with lib.strings; let
  cfg = config.az.server.net;
  inherit (cfg) ipv4 ipv6;
in {
  imports = azLib.scanPath ./.;

  options.az.server.net = with azLib.opt; {
    enable = optBool false;

    vlans = mkOption {
      type = with types;
        attrsOf (submodule ({name, ...}: {
          options = {
            enable = mkEnableOption "";
            name = mkOption {
              type = types.str;
              default = name;
            };
            id = mkOption {type = types.int;};
            createBridge = mkEnableOption "";
            addresses = mkOption {
              type = listOf types.str;
              default = [];
            };
          };
        }));
      default = {};
    };

    bridges = mkOption {
      type = with types;
        attrsOf (submodule ({name, ...}: {
          options = {
            enable = mkEnableOption "";
            name = mkOption {
              type = types.str;
              default = name;
            };
            ipv4 = mkOption {type = types.str;};
            ipv6 = mkOption {type = types.str;};
          };
        }));
      default = {};
    };

    interface = mkOption {
      type = types.str;
      default = "eth0";
    };

    # for use with OSPF
    dontSetGateways = mkEnableOption "";

    ipv4 = {
      #publicAddress = mkOption {type = types.str;}; # external addr
      address = mkOption {type = types.str;};
      subnetSize = mkOption {type = types.ints.u8;};
      gateway = mkOption {
        type = types.str;
        default = "";
      };
    };

    ipv6 = {
      publicAddress = mkOption {type = types.str;}; # GUA, only used for internet access
      address = mkOption {type = types.str;}; # ULA, used for LAN communication
      # subnet size always /64
      gateway = mkOption {
        type = types.str;
        default = "";
      };
    };
  };

  config = let
    bridgedVlans = attrsets.filterAttrs (n: v: v.createBridge) cfg.vlans;
  in (mkIf cfg.enable {
    networking.useDHCP = false;

    systemd.network = {
      enable = true;

      links = {
        # non-persistent MAC addrs
        "00-bridges" = {
          matchConfig = {Type = "bridge";};
          linkConfig = {MACAddressPolicy = "none";};
        };
      };

      netdevs = attrsets.mergeAttrsList [
        # Define VLANs
        (attrsets.mapAttrs' (name: vlan:
          nameValuePair "20-vl${toString vlan.id}-${name}" {
            netdevConfig = {
              Kind = "vlan";
              Name = "vl${toString vlan.id}";
            };
            vlanConfig.Id = vlan.id;
          })
        cfg.vlans)

        # Define VLAN bridges
        (attrsets.mapAttrs' (name: vlan:
          nameValuePair "25-vlbr${toString vlan.id}-${name}" {
            netdevConfig = {
              Name = "vlbr${toString vlan.id}";
              Kind = "bridge";
            };
          })
        bridgedVlans)

        # Define virtual bridges
        (attrsets.mapAttrs' (name: value:
          nameValuePair "25-${name}" {
            netdevConfig = {
              Name = name;
              Kind = "bridge";
            };
          })
        cfg.bridges)
      ];

      networks = attrsets.mergeAttrsList [
        {
          # Setup uplink iface
          "10-uplink" = {
            matchConfig.Name = cfg.interface;
            networkConfig.DHCP = "no";
            networkConfig.IPv6AcceptRA = "no";
            address = [
              "${ipv4.address}/${toString ipv4.subnetSize}"
              "${ipv6.address}/64"
              "${ipv6.publicAddress}/64"
            ];
            routes = lists.optionals (!cfg.dontSetGateways) [
              {Gateway = ipv4.gateway;}
              {Gateway = ipv6.gateway;}
            ];
            linkConfig.RequiredForOnline = "routable";

            vlan = attrsets.mapAttrsToList (name: vlan: "vl${toString vlan.id}") cfg.vlans;
          };
        }

        # Setup VLAN addresses
        (lib.attrsets.mapAttrs' (name: vlan:
          nameValuePair "34-vl${toString vlan.id}-${name}" {
            matchConfig.Name = "vl${toString vlan.id}";
            networkConfig.DHCP = "no";
            networkConfig.IPv6AcceptRA = "no";
            address = vlan.addresses;
            linkConfig.RequiredForOnline = "routable";
          })
        (attrsets.filterAttrs (n: v: v.addresses != []) cfg.vlans))

        # Connect VLANs to bridges
        (lib.attrsets.mapAttrs' (name: vlan:
          nameValuePair "30-vl${toString vlan.id}-${name}" {
            matchConfig.Name = "vl${toString vlan.id}";
            networkConfig.Bridge = "vlbr${toString vlan.id}";
            linkConfig.RequiredForOnline = "enslaved";
          })
        bridgedVlans)

        # Setup VLAN bridges
        (lib.attrsets.mapAttrs' (name: vlan:
          nameValuePair "35-vlbr${toString vlan.id}-${name}" {
            matchConfig.Name = "vlbr${toString vlan.id}";
            bridgeConfig = {};
            networkConfig.LinkLocalAddressing = "no";
            linkConfig.RequiredForOnline = "carrier";
          })
        bridgedVlans)

        # Setup virtual bridges
        (lib.attrsets.mapAttrs' (name: value:
          nameValuePair "36-${name}" {
            matchConfig.Name = name;
            bridgeConfig = {};
            networkConfig = {
              DHCP = "no";
              IPv6AcceptRA = "no";
              DHCPServer = "yes";
              IPv6SendRA = "yes";
            };
            dhcpServerConfig = {
              EmitRouter = "yes";
              EmitTimezone = "yes";
              EmitDNS = "yes";
              DNS = ipv4.address;
            };
            ipv6SendRAConfig = {
              EmitDNS = "yes";
              DNS = ipv6.address;
            };
            ipv6Prefixes = [
              {Prefix = value.ipv6;}
            ];
            address = [
              value.ipv4
              value.ipv6
            ];
            linkConfig.RequiredForOnline = "routable";
          })
        cfg.bridges)
      ];
    };
  });
}
