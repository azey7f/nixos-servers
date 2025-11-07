# TODO?: move this to core
{
  config,
  azLib,
  lib,
  ...
}: let
  top = config.az.server.net;
  cfg = top.mullvad;
in {
  options.az.server.net.mullvad = with azLib.opt; {
    enable = lib.mkEnableOption "";

    endpoints = {
      # must be set, gateway+iface through which mullvad endpoints are reachable
      interface = lib.mkOption {
        type = lib.types.str;
        default = builtins.elemAt (builtins.attrNames top.interfaces) 0;
      };
      gateway = lib.mkOption {
        type = lib.types.str;
        default = top.interfaces.${cfg.endpoints.interface}."ipv${toString cfg.endpoints.gatewayProtoVer}".gateway;
      };

      gatewayProtoVer = lib.mkOption {
        type = lib.types.enum [4 6];
        default = 6;
      };
    };

    tunnelAddr4 = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
    };
    tunnelAddr = lib.mkOption {
      type = with lib.types; nullOr (listOf str);
      default = null;
    };

    privateKeyFile = optStr "/run/secrets/wg-mullvad-key";

    servers = lib.mkOption {
      type = with lib.types; listOf str;
      default = [
        # nix eval --impure --expr 'builtins.toJSON (import ./servers.nix)' | jq -c 'fromjson | keys_unsorted[]' | shuf -n16
        "de-ber-wg-001"
        "nl-ams-wg-003"
        "de-fra-wg-004"
        "fi-hel-wg-101"
        "fr-par-wg-002"
        "se-got-wg-006"
        "de-fra-wg-005"
        "se-sto-wg-003"
        "se-mma-wg-102"
        "ch-zrh-wg-001"
        "ch-zrh-wg-004"
        "nl-ams-wg-007"
        "gb-lon-wg-006"
        "nl-ams-wg-008"
        "se-mma-wg-112"
        "de-fra-wg-002"
      ];
    };

    # servers fetched with /scripts/mullvad-mkservers
    serverConfigs = lib.mkOption {
      type = with lib.types;
        attrsOf (submodule ({name, ...}: {
          options = {
            ipv4.addr = lib.mkOption {type = lib.types.str;};
            ipv6.addr = lib.mkOption {type = lib.types.str;};
            publicKey = lib.mkOption {type = lib.types.str;};
          };
        }));
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl."net.ipv6.fib_multipath_hash_policy" = true; # load-balance between servers
    az.server.net = {
      interfaces = let
        MultiPathRoute = builtins.map (server: "fe80::@wg-${builtins.replaceStrings ["-wg-"] ["-"] server}") cfg.servers;
      in
        {
          "${cfg.endpoints.interface}".extraRoutes =
            builtins.map (server: let
              conf = config.az.server.net.mullvad.serverConfigs.${server};
            in {
              Destination =
                if cfg.endpoints.gatewayProtoVer == 6
                then "${conf.ipv6.addr}/128"
                else "${conf.ipv4.addr}/32";
              Gateway = cfg.endpoints.gateway;
            })
            cfg.servers;
        }
        // builtins.listToAttrs (builtins.map (server: {
            name = "wg-${builtins.replaceStrings ["-wg-"] ["-"] server}";
            value = let
              conf = config.az.server.net.mullvad.serverConfigs.${server};
            in {
              ipv4.addr = cfg.tunnelAddr4;
              ipv4.subnetSize = 32;
              ipv6.addr = cfg.tunnelAddr;
              ipv6.subnetSize = 128;

              wireguard.routeTable = "off"; # routes defined manually
              wireguard.privateKeyFile = cfg.privateKeyFile;
              wireguard.peers = [
                {
                  AllowedIPs = ["0.0.0.0/0" "::/0"];
                  PublicKey = conf.publicKey;
                  Endpoint =
                    if cfg.endpoints.gatewayProtoVer == 6
                    then "[${conf.ipv6.addr}]:51820"
                    else "${conf.ipv4.addr}:51820";
                  #PersistentKeepalive = 25;
                }
              ];

              extraRoutes = [
                {
                  inherit MultiPathRoute;
                  Destination = ["0.0.0.0/0"];
                  Metric = 100000;
                }
                {
                  inherit MultiPathRoute;
                  Destination = ["::/0"];
                  Metric = 100000;
                }
              ];
            };
          })
          cfg.servers);

      mullvad.serverConfigs = import ./servers.nix;
    };
  };
}
