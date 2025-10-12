{
  lib,
  config,
  outputs,
  ...
}:
with lib; let
  cluster = outputs.infra.clusters.${config.networking.domain};
  domain = config.az.server.rke2.baseDomain;
in {
  networking.hostId = "a6b703c2";
  system.stateVersion = config.system.nixos.release; # root is on tmpfs, this should be fine

  # FIXME: UDPRoute doesn't work for some reason, so blocky can't be used directly
  services.dnsproxy = {
    enable = true;
    settings.upstream = ["tcp://${cluster.publicSubnet}:fc6a::1"];
    settings.listen-ports = [53];
    settings.listen-addrs = ["192.168.0.254" "::1"];
  };
  az.core.net.dns.nameservers = ["::1"];

  az.svc.rke2 = {
    # cluster core
    envoyGateway = {
      enable = true;
      gateways.external.addresses = {
        ipv4 = "10.33.1.1";
        ipv6 = "${cluster.publicSubnet}:fc6a::1";
      };
      gateways.internal.addresses = {
        ipv4 = "10.33.1.2";
        ipv6 = "${cluster.publicSubnet}:fc6a::2";
      };
    };
    certManager.enable = true;
    metrics.enable = true;

    mail.enable = true;
    frp.enable = true;
    nameserver.enable = true;
    resolver.enable = true;

    # auth
    lldap.enable = true;
    authelia.enable = true;

    # web core
    nginx.enable = true;
    searxng.enable = true;
    # media
    navidrome.enable = true;
    feishin.enable = true;
    # source control, ci/cd
    forgejo.enable = true;
    woodpecker.enable = true;
    renovate.enable = true;
    attic.enable = true;
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
        #router = "${cluster.publicSubnet}::1";
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

      #frr.ospf.enable = true;
      #dontSetGateways = true;

      /*
        vlans = {
        trusted = {
          enable = true;
          id = 10;
          createBridge = true;
          addresses = ["10.33.10.2/24" "${cluster.publicSubnet}:10::2/64"];
        };
      };
      */

      bridges = {
        # libvirt bridges
        /*
          vbr-trusted = {
          ipv4 = "172.20.0.1/24";
          ipv6 = ["${cluster.publicSubnet}:a39d::"];
        };
        */
        /*
        vbr-untrusted = {
          enable = true;
          ipv4 = "172.20.1.1/24";
          ipv6 = ["${cluster.publicSubnet}:d857::"];
        };
        */
      };

      ipv4 = {
        #address = "10.33.0.2";
        #gateway = "10.33.0.1"; # used for remote unlock only, discovered via OSPF
        address = "192.168.0.254";
        gateway = "192.168.0.1";
        subnetSize = 24;
      };

      # ipv6 configured automatically from ../../infra.nix
    };
  };
}
