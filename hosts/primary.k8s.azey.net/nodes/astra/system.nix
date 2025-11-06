{
  lib,
  config,
  ...
}: {
  networking.hostId = "a6b703c2";
  system.stateVersion = config.system.nixos.release; # root is on tmpfs, this should be fine

  az.svc.ssh.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhEXbX8s18h6eUmXh8c7b6zZtUAgZGRrEiFZcLYY8gg grapheneos"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4AA0SE0Q9I8d4U1aXeLcGhp1httDnwdsuRJPiKAi5f main@Apollo"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXOe3PWMsjyWrXBG1hv1YSmNUNGBBLLWOJeqDGXoyhS main@Hyperion"
  ];

  az.core.libvirt.hugepages = {
    enable = true;
    count = 48;
  };

  az.core.net.dns.nameservers = [
    # https://nat64.net
    "2a01:4f8:c2c:123f::1"
    "2a00:1098:2b::1"
    "2a01:4f9:c010:3f02::1"
  ];

  #networking.nftables.enable = true; # TODO: set globally
  networking.firewall = let
    cmds = lib.reverseList [
      "INPUT -i wg-uplink -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
      "INPUT -i wg-uplink -j DROP"

      "FORWARD -o wg-uplink -j ACCEPT"
      "FORWARD -i wg-uplink -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
      "FORWARD -i wg-uplink -j DROP"
    ];
  in {
    extraCommands = lib.concatMapStringsSep "\n" (rule: "ip6tables -I ${rule}") cmds;
    extraStopCommands = lib.concatMapStringsSep "\n" (rule: "ip6tables -D ${rule}") cmds;
  };

  swapDevices = [
    {
      device = "/dev/zvol/nvme/swap";
      randomEncryption.enable = true;
    }
  ];

  #systemd.services."rke2-server".enable = false;
  az.server = {
    power.ignoreKeys = true;

    /*
    disks.standbyOnBoot = {
      enable = true;
      disks = [
        "/dev/disk/by-id/ata-WDC_WD102KRYZ-01A5AB0_VCG675TN"
        "/dev/disk/by-id/ata-WDC_WD102KRYZ-01A5AB0_VCG8623N"
        "/dev/disk/by-id/ata-WDC_WD102KRYZ-01A5AB0_VCGEBXPM"
        "/dev/disk/by-id/ata-WDC_WD102KRYZ-01A5AB0_VCGH2EZM"
      ];
    };
    */

    rke2 = {
      enable = true;
      server.enable = true;

      haproxy.enable = true;
      keepalived.enable = true;

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
      extraInterfaces = ["wg-uplink"];
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
        };

        "wg-uplink" = {
          ipv6.addr = ["2a14:6f42:4969:5608:f7d2:29ff:fe34:11c1"];

          wireguard.privateKeyFile = "/run/secrets/wg-uplink-key";
          wireguard.peers = [
            {
              AllowedIPs = ["2a14:6f42:4969:5608::/128" "::/0"];
              PublicKey = "9k3URy2qxlqdmw43p4LE6ERXAAcyAuuweDt9c2ma2hc=";
              Endpoint = "193.148.249.170:35608";
            }
            {
              AllowedIPs = ["2a14:6f42:4969:5608:f7d2:29ff:fe34:11c1/128" "2a14:6f44:5608::/48"];
              PublicKey = "AlCGtkENzNAsMQX9UhrOWgjvAyp+T/yIAvrnodzbeRY=";
              PersistentKeepalive = 25;
            }
          ];
        };
      };
    };
  };

  sops.secrets."wg-uplink-key" = {
    owner = config.users.users.systemd-network.name;
  };
}
