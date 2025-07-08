# TODO: probably rework all of this at some point
{
  config,
  azLib,
  lib,
  outputs,
  ...
}:
with lib;
with lib.strings; let
  cfg = config.az.server.net;
  inherit (cfg) ipv4 ipv6;
  cluster = outputs.infra.clusters.${config.networking.domain};
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

            ipv4 = mkOption {
              type = with types; nullOr str;
              default = null;
            };
            ipv6 = mkOption {
              type = with types; listOf str;
              default = [];
            };

            interfaces = mkOption {
              type = with types; listOf str;
              default = [];
            };

            mac = mkOption {
              type = with types; nullOr str;
              default = null;
            };
          };
        }));
      default = {};
    };

    interface = mkOption {
      type = types.str;
      default = "eth0";
    };

    # for use with OSPF
    dontSetGateways = optBool false;

    ipv4 = {
      address = mkOption {type = types.str;};
      subnetSize = mkOption {type = types.ints.u8;};
      gateway = mkOption {type = types.str;};
    };

    ipv6 = {
      address = mkOption {
        type = with types; listOf str;
        default = [];
      };
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

    networking.interfaces = lib.mkForce {};

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
        {
          # Define nat64 tun
          "20-${config.services.tayga.tunDevice}" = mkIf config.az.svc.tayga.enable {
            netdevConfig = {
              Kind = "tun";
              Name = config.services.tayga.tunDevice;
            };
          };
        }

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
          nameValuePair "26-${name}" {
            netdevConfig =
              {
                Name = name;
                Kind = "bridge";
              }
              // (lib.attrsets.optionalAttrs (value.mac != null) {MACAddress = value.mac;});
          })
        cfg.bridges)
      ];

      networks = lib.attrsets.mergeAttrsList [
        {
          # Setup uplink iface
          "10-uplink" = {
            matchConfig.Name = cfg.interface;
            networkConfig.DHCP = "no";
            networkConfig.IPv6AcceptRA = "no";
            address =
              [
                "${ipv4.address}/${toString ipv4.subnetSize}"
              ]
              ++ (map (addr: "${addr}/64") ipv6.address);
            routes = lists.optionals (!cfg.dontSetGateways) [
              {Gateway = ipv4.gateway or "";}
              {Gateway = ipv6.gateway;}
            ];
            linkConfig.RequiredForOnline = "routable";

            vlan = attrsets.mapAttrsToList (name: vlan: "vl${toString vlan.id}") cfg.vlans;
          };

          # Define nat64 tun
          "15-${config.services.tayga.tunDevice}" = let
            svc = config.services.tayga;
          in
            mkIf config.az.svc.tayga.enable {
              matchConfig.Name = svc.tunDevice;
              networkConfig = {
                DHCP = "no";
                IPv6AcceptRA = "no";
                LinkLocalAddressing = "no";
                ConfigureWithoutCarrier = "yes";
              };
              /*
              address = [
                "${svc.ipv4.pool.address}/${toString svc.ipv4.pool.prefixLength}"
                "${svc.ipv6.pool.address}/${toString svc.ipv6.pool.prefixLength}"
                #"${svc.ipv4.router.address}/32"
                #"${svc.ipv6.router.address}/128"
              ];
              */
              routes = [
                {Destination = "${svc.ipv4.pool.address}/${toString svc.ipv4.pool.prefixLength}";}
                {Destination = "${svc.ipv6.pool.address}/${toString svc.ipv6.pool.prefixLength}";}
              ];
              linkConfig.RequiredForOnline = "no-carrier";
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
          nameValuePair "30-${toString vlan.id}-${name}" {
            matchConfig.Name = "vl${toString vlan.id}";
            networkConfig.Bridge = "vlbr${toString vlan.id}";
            linkConfig.RequiredForOnline = "enslaved";
          })
        bridgedVlans)

        # Connect networks to misc bridges
        (lib.attrsets.mergeAttrsList (
          lib.lists.flatten
          (lib.attrsets.mapAttrsToList (name: conf: (
              builtins.map (iface: {
                "31-${iface}-${name}" = {
                  matchConfig.Name = iface;
                  networkConfig.Bridge = name;
                  linkConfig.RequiredForOnline = "enslaved";
                };
              })
              conf.interfaces
            ))
            cfg.bridges)
        ))

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
        (lib.attrsets.mapAttrs' (name: conf:
          nameValuePair "36-${name}" {
            matchConfig.Name = name;
            bridgeConfig = {};
            networkConfig = {
              DHCP = "no";
              IPv6AcceptRA = "no";
              DHCPServer =
                if (conf.ipv4 != null)
                then "yes"
                else "no";
              IPv6SendRA = "yes";
              ConfigureWithoutCarrier = "yes";
            };
            dhcpServerConfig = {
              EmitRouter = "yes";
              EmitTimezone = "yes";
              PoolOffset = 128;
              #EmitDNS = "yes";
              #DNS = ipv4.address;
            };
            /*
            ipv6SendRAConfig = {
              EmitDNS = "yes";
              DNS = #ipv6.address;
            };
            */
            ipv6Prefixes = map (Prefix: {inherit Prefix;}) conf.ipv6;
            address = (lists.optional (conf.ipv4 != null) conf.ipv4) ++ map (ip: "${ip}/64") conf.ipv6;
            linkConfig.RequiredForOnline = "routable";
          })
        cfg.bridges)
      ];
    };
  });
}
