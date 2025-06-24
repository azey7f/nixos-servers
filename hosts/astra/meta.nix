{
  lib,
  config,
  ...
}:
with lib; {
  networking.hostName = "astra";
  networking.hostId = "a6b703c2";
  networking.domain = "azey.net";
  system.stateVersion = config.system.nixos.release; # root is on tmpfs, this should be fine

  az.server = {
    net = {
      interface = "eno1";

      frr.ospf.enable = true;
      dontSetGateways = true;

      bridges = {
        # libvirt bridges
        vbr-trusted = {
          enable = true;
          ipv4 = "172.20.0.1/24";
          ipv6 = "2001:470:59b6:a39d::/64";
        };
        vbr-untrusted = {
          enable = true;
          ipv4 = "172.20.1.1/24";
          ipv6 = "2001:470:59b6:d857::/64";
        };
      };

      ipv4 = {
        address = "10.33.0.2";
        gateway = "10.33.0.1"; # used for remote unlock only, discovered via OSPF
        subnetSize = 24;
      };

      ipv6 = {
        publicAddress = "2001:470:59b6::2"; #TODO
        address = "fd95:3a23:dd1f::2";
        #gateway = "fd95:3a23:dd1f::1";
      };
    };
  };
}
