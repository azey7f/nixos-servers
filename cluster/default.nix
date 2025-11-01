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

    net = {
      subnetSize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 64;
      };

      prefix = lib.mkOption {
        type = lib.types.str;
        example = "2001:db8:1234";
        # must be set
      };
      prefixSubnetSize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 48;
      };

      # nodes' addrs are generated dynamically in ../config/rke2/default.nix:
      #   "${prefix}${nodes}::${decToHex meta.nodes.${hostName}.id}/${subnetSize}"
      nodes = lib.mkOption {
        type = lib.types.str;
        example = ":ffff";
        # must be set
      };

      # reserved static subnet used for apiserver and ExternalIP
      #     apiserver: "${prefix}${static}::ffff/128"
      #  gateway e.g.: "${prefix}${static}::1/128"
      static = lib.mkOption {type = lib.types.str;};

      # --cluster-cidr
      #  "${prefix}${pods}::/${subnetSize}"
      pods = lib.mkOption {type = lib.types.str;};

      # --service-cidr
      #  "${prefix}${pods}::/${subnetSize}"
      services = lib.mkOption {type = lib.types.str;};
    };

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
              # IDs 0xffff and above are reserved
              # at time of writing of those only 0xffff is actually used for the default gateway
              id = lib.mkOption {type = ints.positive;};
            };
          });
        default = {};
      };

      # used in nameserver & frp
      vps = lib.mkOption {
        type = with lib.types;
          attrsOf (submodule {
            options = {
              ip = lib.mkOption {type = types.str;};
              ipv4 = lib.mkOption {type = types.str;};

              zones = lib.mkOption {
                type = attrsOf (listOf str);
                example = {
                  "example.com" = ["www" "@"];
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
