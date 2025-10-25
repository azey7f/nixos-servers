{
  config,
  lib,
  azLib,
  ...
}: let
  cfg = config.az.cluster;
in {
  # ./core    domain-agnostic cluster core services - az.cluster.core
  # ./domain  internal az.cluster.domainSpecific modules
  imports = azLib.scanPath ./.;

  options.az.cluster = with azLib.opt; {
    enable = optBool false;

    # mail sent in HTTP contact header, DNS CAA record, etc
    contactMail = lib.mkOption {
      type = lib.types.str;
      # must be set
    };

    # ${publicSubnet}::/64 is reserved for cluster stuff, e.g. network infra, API servers' VIP, etc
    publicSubnet = lib.mkOption {
      type = lib.types.str;
      example = "2001:db8:1234";
      # must be set
    };
    # nodes' addrs are generated dynamically in ../config/rke2/default.nix:
    #   "${publicSubnet}${nodeSubnet}::${decToHex meta.nodes.${hostName}.id}/64"
    nodeSubnet = lib.mkOption {
      type = lib.types.str;
      default = ":ffff";
    };

    clusterCidr = optStr "10.42.0.0/16,fd01::/48";
    serviceCidr = optStr "10.43.0.0/16,fd98::/108";

    # convenience mapping for .domainSpecific, so services can be
    # defined per-domain rather than the other way around
    domains = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = {};
    };

    # infra metadata
    meta = {
      # used mainly in ../../config/rke2
      nodes = lib.mkOption {
        type = with lib.types;
          attrsOf (submodule {
            options = {
              id = lib.mkOption {type = ints.positive;}; # ID 0 is reserved for default gateway IP
            };
          });
        default = {};
      };

      # used in nameserver & frp
      vps = lib.mkOption {
        type = with lib.types;
          attrsOf (submodule {
            options = {
              ipv4 = lib.mkOption {type = types.str;};
              ipv6 = lib.mkOption {type = types.str;};

              zones = lib.mkOption {
                type = attrsOf (attrsOf (listOf str));
                example = {
                  "example.com".external = ["www" "@" "*"];
                };
                default = {};
              };
              knotPubkey = lib.mkOption {type = types.str;};
            };
          });
        default = {};
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # domains impl
    # from:  domains.domain.service = {...};
    # to:    domainSpecific.service.domain = {...};
    az.cluster.domainSpecific = lib.foldl lib.recursiveUpdate {} (
      lib.mapAttrsToList (
        domain: services: lib.mapAttrs (_: v: {${domain} = v;}) services
      )
      cfg.domains
    );
  };
}
