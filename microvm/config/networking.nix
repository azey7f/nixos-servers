{
  config,
  azLib,
  lib,
  outputs,
  ...
}:
with lib; let
  self = config.az.microvm;
  cfg = config.az.microvm.net;
in {
  options.az.microvm.net = with azLib.opt; {
    enable = optBool false;

    vmAddr = mkOption {
      type = types.str;
      default =
        lib.lists.findFirst (addr: (
          lib.lists.any (n: n == config.networking.hostName) config.networking.hosts.${addr}
        ))
        null (builtins.attrNames config.networking.hosts);
    };
  };

  config = mkIf cfg.enable {
    networking.hosts = outputs.servers.${self.serverName}.config.networking.hosts;

    systemd.network = {
      enable = true;

      networks = {
        "40-wan" = {
          matchConfig.PermanentMACAddress = (builtins.elemAt config.microvm.interfaces 0).mac;

          networkConfig = {
            DHCP = "no";
            IPv6AcceptRA = "no";
            LinkLocalAddressing = "no";
          };

          addresses = [{Address = "${cfg.vmAddr}/64";}];

          #ipv6AcceptRAConfig.Token = "::${toString (self.id + 1)}";
          linkConfig.RequiredForOnline = "routable";

          routes = [
            /*
            {
              # fe80:: is only used to discover MAC addr, so it works for IPv4 as well
              # with a static [Neighbor] entry it's not even necessary to set the address on the host iface
              # ...this is some actual black magic, I should be burned at the stake
              Gateway = "fe80::";
              Source = "172.30.0.254";
            }
            */
            {Gateway = "fe80::";}
          ];
          extraConfig = ''
            [Neighbor]
            Address=fe80::
            LinkLayerAddress=02:00:00:00:00:ff
          '';
        };
      };
    };

    networking = {
      useDHCP = false;

      nftables.enable = true;
      firewall = {
        enable = true;
        filterForward = true;
      };
    };

    az.core.net.dns = {
      enable = true;
      nameservers = [
        # TODO: selfhost DNS64
        "2606:4700:4700::64"
        #"2606:4700:4700::6464"
      ];
    };
  };
}
