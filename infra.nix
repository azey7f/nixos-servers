# TODO: documentation
lib: rec {
  domains = {
    "azey.net" = {
      vps = [
        # used in k8s nameserver & frp
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
        "primary.k8s" = rec {
          # ${publicSubnet}::/64 is reserved for cluster stuff, e.g. network infra, API servers' VIP, etc
          # nodes' addrs are generated dynamically:
          #   "${publicSubnet}${nodeSubnet}::${nodeIndex}/64"
          # where nodeIndex is the node's 1-based index in .nodes
          publicSubnet = "fd95:3a23:dd1f"; # ULA routed through mullvad, no native IPv6 :c
          nodeSubnet = ":ffff";

          nodes = {
            "astra" = {
              storage = [
                # all 4TB
                "/dev/disk/by-id/ata-ST4000VX016-3CV104_WW60G3W1"
                "/dev/disk/by-id/ata-ST4000VX016-3CV104_WW61HSLR"
                "/dev/disk/by-id/ata-ST4000VX016-3CV104_WW61HXHH"
                "/dev/disk/by-id/ata-ST4000VX016-3CV104_WW63F1WF"
                "/dev/disk/by-id/ata-WL4000GSA6454G_WOCL25001386576"
                "/dev/disk/by-id/ata-WL4000GSA6454G_WOCL25001386896"
              ];
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

  nodes =
    lib.attrsets.concatMapAttrs (cluster: clusterV: (
      lib.attrsets.concatMapAttrs (node: nodeV: {
        "${node}.${cluster}" = nodeV;
      })
      clusterV.nodes
    ))
    clusters;
}
