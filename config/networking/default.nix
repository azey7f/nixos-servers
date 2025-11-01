{
  config,
  azLib,
  lib,
  ...
}:
with lib;
with lib.strings; let
  cfg = config.az.server.net;
in {
  imports = azLib.scanPath ./.;

  options.az.server.net = with azLib.opt; {
    enable = optBool false;

    bridges = mkOption {
      type = with types;
        attrsOf (submodule ({name, ...}: {
          options = {
            enable = mkEnableOption "";
            name = mkOption {
              type = types.str;
              default = name;
            };

            interfaces = mkOption {
              type = with types; listOf str;
              default = [];
            };
          };
        }));
      default = {};
    };

    interfaces = mkOption {
      type = with types;
        attrsOf (submodule ({name, ...}: {
          options = {
            enable = mkEnableOption "";
            name = mkOption {
              type = types.str;
              default = name;
            };

            ipv4 = {
              addr = mkOption {
                type = with types; nullOr str;
                default = null;
              };
              subnetSize = mkOption {
                type = types.ints.u8;
                default = 24;
              };
              gateway = mkOption {
                type = with types; nullOr str;
                default = null;
              };

              dhcpClient = optBool false;
              dhcpServer = optBool false;
            };

            ipv6 = {
              addr = mkOption {
                type = with types; nullOr (listOf str);
                default = null;
              };
              subnetSize = mkOption {
                type = types.ints.u8;
                default = 64;
              };
              gateway = mkOption {
                type = with types; nullOr str;
                default = null;
              };

              sendRA = optBool false;
              acceptRA = optBool false;
            };

            onlineWhen = optStr "routable";

            extraRoutes = mkOption {
              type = with types; listOf attrs;
              default = [];
            };

            vlans = mkOption {
              # final vlan interfaces will be named "${name}.${id}"
              type = with types; listOf ints.positive; # physical VLAN ids
              default = [];
            };
          };
        }));
      default = {};
    };
  };

  config = mkIf cfg.enable {
    # force systemd-networkd
    networking.useDHCP = false;
    networking.interfaces = lib.mkForce {};

    systemd.network = {
      enable = true;

      links = {
        # non-persistent MAC addrs
        "00-bridges" = {
          matchConfig.Type = "bridge";
          linkConfig.MACAddressPolicy = "none";
        };
      };

      netdevs = attrsets.mergeAttrsList (lib.lists.flatten [
        # define VLANs
        (lib.attrsets.mapAttrsToList (name: iface:
          builtins.map (id: {
            "10-${name}-vlan${toString vlan.id}" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "${iface.name}.${toString vlan.id}";
              };
              vlanConfig.Id = vlan.id;
            };
          })
          iface.vlans)
        cfg.interfaces)

        # define bridges
        (attrsets.mapAttrs' (name: bridge:
          nameValuePair "10-${name}" {
            netdevConfig = {
              Name = bridge.name;
              Kind = "bridge";
            };
          })
        cfg.bridges)
      ]);

      networks = lib.attrsets.mergeAttrsList (lib.lists.flatten [
        # setup interfaces
        (lib.attrsets.mapAttrs' (name: iface:
          nameValuePair "20-${name}" {
            matchConfig.Name = iface.name;

            bridgeConfig = {}; # necessary for bridges, doesn't seem to break anything for non-bridges
            networkConfig = {
              ConfigureWithoutCarrier =
                if !(iface.ipv4.dhcpClient || iface.ipv6.acceptRA)
                then "yes"
                else "no";

              DHCP =
                if iface.ipv4.dhcpClient
                then "yes"
                else "no";
              DHCPServer =
                if iface.ipv4.dhcpServer
                then "yes"
                else "no";

              IPv6AcceptRA =
                if iface.ipv6.acceptRA
                then "yes"
                else "no";
              IPv6SendRA =
                if iface.ipv6.sendRA
                then "yes"
                else "no";
            };
            dhcpServerConfig = mkIf iface.ipv4.dhcpServer {
              EmitRouter = "yes";
              EmitTimezone = "yes";
              PoolOffset = 128;
            };
            ipv6Prefixes = lib.lists.optionals iface.ipv6.sendRA (map (Prefix: {inherit Prefix;}) conf.ipv6);

            address = lib.lists.flatten [
              (lists.optional (iface.ipv4.addr != null)
                "${iface.ipv4.addr}/${toString iface.ipv4.subnetSize}")
              (lists.optional (iface.ipv6.addr != null)
                (map (ip: "${ip}/${toString iface.ipv6.subnetSize}") iface.ipv6.addr))
            ];
            routes =
              lib.lists.flatten [
                (lib.lists.optional (iface.ipv4.gateway != null) {Gateway = iface.ipv4.gateway;})
                (lib.lists.optional (iface.ipv6.gateway != null) {Gateway = iface.ipv6.gateway;})
              ]
              ++ iface.extraRoutes;
            linkConfig.RequiredForOnline = iface.onlineWhen;

            vlan = builtins.map (vlan: "${iface.name}.${toString vlan}") iface.vlans;
          })
        cfg.interfaces)

        # connect interfaces to bridges
        (lib.attrsets.mapAttrsToList (name: bridge: (
            builtins.map (iface: {
              "30-${iface}-${name}" = {
                matchConfig.Name = iface;
                networkConfig.Bridge = bridge.name;
                linkConfig.RequiredForOnline = "enslaved";
              };
            })
            bridge.interfaces
          ))
          cfg.bridges)
      ]);
    };
  };
}
