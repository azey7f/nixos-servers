{
  lib,
  config,
  outputs,
  ...
}:
with lib; let
  cluster = outputs.infra.clusters.${config.networking.domain};
in {
  networking.hostId = "a6b703c2";
  system.stateVersion = config.system.nixos.release; # root is on tmpfs, this should be fine

  az.svc.tayga = {
    # NAT64
    enable = true;
    ipv6.subnet = "${cluster.publicSubnet}:6464";
  };

  az.svc.k3s = {
    metallb.enable = true;
  };

  az.server = {
    kubernetes = {
      enable = true;
      ca.jwk = {
        x = "m76tuf5IsBLD9vZlTqJI_HH7rO2FcdlKOTjxnMOHk7o";
        y = "xqWf32Zi5aX-rBgYG_tj9cH8T1wW8kcAqSup1KqAHD0";
        kid = "tgOkfY-nZ5mT-gjD7nKCpxu9NWWZNoCMBfaPBa_RrF4";
      };
    };

    net = {
      interface = "eno1";

      frr.ospf.enable = true;
      dontSetGateways = true;

      bridges = {
        # libvirt bridges
        vbr-trusted = {
          enable = true;
          ipv4 = "172.20.0.1/24";
          ipv6 = ["${cluster.publicSubnet}:a39d::/64"];
        };
        vbr-untrusted = {
          enable = true;
          ipv4 = "172.20.1.1/24";
          ipv6 = ["${cluster.publicSubnet}:d857::/64"];
        };
      };

      ipv4 = {
        address = "10.33.0.2";
        gateway = "10.33.0.1"; # used for remote unlock only, discovered via OSPF
        subnetSize = 24;
      };

      # ipv6 configured automatically from ../../infra.nix
    };
  };
}
