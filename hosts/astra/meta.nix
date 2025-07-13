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

  az.svc.rke2 = {
    envoyGateway = {
      enable = true;
      addresses = {
        ipv4 = "10.33.1.1";
        ipv6 = "${cluster.publicSubnet}:fc6a::1";
      };
    };
    certManager.enable = true;
    frp = {
      enable = true;
      remotes = builtins.map (v: v.ipv4) outputs.infra.domains.${config.az.server.rke2.baseDomain}.vps; # TODO: .ipv4, because ipv6 would have to go through mullvad and that's insanely slow on my current connection for living in the middle of nowhere reasons
    };

    nameserver.enable = true;

    lldap.enable = true;
    authelia.enable = true;

    nginx.enable = true;
    searxng.enable = true;
    forgejo.enable = true;
    navidrome.enable = true;
    feishin.enable = true;
  };

  az.server = rec {
    rke2 = {
      enable = true;
      server.enable = true;

      haproxy.enable = true;
      keepalived.enable = true;

      clusterCidr = "172.30.0.0/16,fd01::/48"; # TODO: proper IPv6 addrs
      serviceCidr = "172.31.0.0/16,fd98::/108";

      loadBalancing.cidrs = [
        "${cluster.publicSubnet}:fc6a::/64"
        "10.33.1.0/24"
      ];

      bgp = {
        # https://github.com/cilium/cilium/issues/28985
        # TODO?: make node itself use BGP instead of OSPF
        enable = true;
        router = "${cluster.publicSubnet}::1";
      };

      storage.zfs = {
        enable = true;
        poolName = "hdd";
        disks = [
          # each 4TBs => theoretically total 12TB usable
          [
            "/dev/disk/by-id/ata-ST4000VX016-3CV104_WW60G3W1"
            "/dev/disk/by-id/ata-ST4000VX016-3CV104_WW63F1WF"
          ]
          [
            "/dev/disk/by-id/ata-ST4000VX016-3CV104_WW61HSLR"
            "/dev/disk/by-id/ata-WL4000GSA6454G_WOCL25001386576"
          ]
          [
            "/dev/disk/by-id/ata-ST4000VX016-3CV104_WW61HXHH"
            "/dev/disk/by-id/ata-WL4000GSA6454G_WOCL25001386896"
          ]
        ];
      };
    };

    net = {
      interface = "eno1";

      frr.ospf.enable = true;
      dontSetGateways = true;

      vlans = {
        trusted = {
          enable = true;
          id = 10;
          createBridge = true;
          addresses = ["10.33.10.2/24" "${cluster.publicSubnet}:10::2/64"];
        };
      };

      bridges = {
        # libvirt bridges
        vbr-trusted = {
          enable = true;
          ipv4 = "172.20.0.1/24";
          ipv6 = ["${cluster.publicSubnet}:a39d::"];
        };
        /*
        vbr-untrusted = {
          enable = true;
          ipv4 = "172.20.1.1/24";
          ipv6 = ["${cluster.publicSubnet}:d857::"];
        };
        */
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
