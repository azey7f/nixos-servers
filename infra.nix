# TODO: documentation
lib: rec {
  domains = {
    "azey.net" = {
      vps = [
        # used in k3s nameserver & rathole (if rathole-pubkey is defined)
        {
          ipv4 = "188.245.84.161";
          ipv6 = "2a01:4f8:c013:f05f::53";
          knotPubkey = "Dz14HoMs3cuczSYTUscntbB7ZRb7JAGg98/pP+Rv0tk=";
        }
        {
          ipv4 = "95.217.221.156";
          ipv6 = "2a01:4f9:c012:dc23::53";
          knotPubkey = "jLWkMn4g5XD8oC4HRDzwGY8eWCkExNb/lDUPoiafyis=";
        }
      ];

      clusters = {
        # NOTE: currently there's a max limit of 255 microvm defs per server before things break, because mac addrs
        # TODO: go through all usages of az.microvm.id and make sure ^^ is actually true, might actually be 255 microvms in cluster or flake
        "primary.k8s" = rec {
          publicSubnet = "fd95:3a23:dd1f"; # ULA routed through mullvad, no native IPv6 :c

          # prefix for internal /64 microVM subnets
          # the actual subnets are generated dynamically:
          #   "${publicSubnet}${microvmSubnet}${serverId}::/64"
          # where serverId is a hex index of the server in .servers, generated via findFirstIndex
          # see ./config/default.nix and ./config/microvm.nix
          microvmSubnet = ":cb";

          servers = {
            "astra" = {
              cephDisks = [
                "/dev/disk/by-id/ata-ST4000VX016-3CV104_WW60G3W1"
                "/dev/disk/by-id/ata-ST4000VX016-3CV104_WW61HSLR"
                "/dev/disk/by-id/ata-ST4000VX016-3CV104_WW61HXHH"
                "/dev/disk/by-id/ata-ST4000VX016-3CV104_WW63F1WF"
                "/dev/disk/by-id/ata-WL4000GSA6454G_WOCL25001386576"
                "/dev/disk/by-id/ata-WL4000GSA6454G_WOCL25001386896"
              ];
              vms = {
                k3s-controller = {
                  count = 3;
                  mem = 8192;
                  vcpu = 4;
                };
                k3s-worker = {
                  count = 3;
                  mem = 16384;
                };
              };
            };
          };
        };
      };
    };
  };

  # convenience mappings
  clusters =
    lib.attrsets.concatMapAttrs (domain: domainV: (
      lib.attrsets.concatMapAttrs (cluster: clusterV: {
        "${cluster}.${domain}" = clusterV;
      })
      domainV.clusters
    ))
    domains;

  servers =
    lib.attrsets.concatMapAttrs (cluster: clusterV: (
      lib.attrsets.concatMapAttrs (server: serverV: {
        "${server}.${cluster}" = serverV;
      })
      clusterV.servers
    ))
    clusters;
}
