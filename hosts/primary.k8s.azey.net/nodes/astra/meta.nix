{
  lib,
  config,
  outputs,
  ...
}: {
  networking.hostId = "a6b703c2";
  system.stateVersion = config.system.nixos.release; # root is on tmpfs, this should be fine

  # FIXME: UDPRoute doesn't work for some reason, so blocky can't be used directly
  services.dnsproxy = {
    enable = true;
    settings.upstream = ["tcp://10.33.1.2"]; # rTODO ["tcp://${config.az.cluster.publicSubnet}:fffe::2"];
    settings.listen-ports = [53];
    settings.listen-addrs = ["192.168.0.254" "::1"];
  };
  az.core.net.dns.nameservers = ["::1"];

  #systemd.services."rke2-server".enable = false;
  az.server = rec {
    rke2 = {
      enable = true;
      server.enable = true;

      haproxy.enable = true;
      keepalived.enable = true;

      bgp = {
        # https://github.com/cilium/cilium/issues/28985
        # TODO: get an actual router and do this properly, *please*.
        enable = true;
        #router = "${config.az.cluster.publicSubnet}::1";
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

      primaryInterface = "vbr-uplink";
    };

    net = {
      bridges."vbr-uplink".interfaces = ["eno1"];
      interfaces = {
        "vbr-uplink" = {
          ipv4 = {
            addr = "192.168.0.254";
            gateway = "192.168.0.1";
            subnetSize = 24;
          };
          # ipv6 configured automatically by ../rke2
        };
      };
    };
  };
}
