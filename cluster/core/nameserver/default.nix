{
  pkgs,
  config,
  lib,
  azLib,
  ...
} @ args: let
  instances = lib.filterAttrs (_: v: v.enable) config.az.cluster.core.nameserver;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.core.nameserver = with azLib.opt; let
    nsOptions = id: defaultSecondaries: {
      enable = optBool false;

      # see ./zones, files are named by reversed FQDN for sorting reasons
      zones = lib.mkOption {
        type = with lib.types; listOf str;
        default = builtins.attrNames config.az.cluster.domains;
      };

      secondaryServers = lib.mkOption {
        type = with lib.types; attrsOf anything; # see cluster/default.nix meta.vps def
        default = defaultSecondaries;
      };
      acmeTsig = optBool true;

      gatewayPort = lib.mkOption {
        type = lib.types.port;
        default = 53;
      };
    };
  in {
    # see ../envoy.nix
    external = nsOptions "external" config.az.cluster.meta.vps;
    internal = nsOptions "internal" {};
  };

  config = lib.mkIf (instances != {}) {
    assertions =
      lib.mapAttrsToList (id: cfg: {
        assertion = config.az.cluster.core.envoyGateway.gateways.${id}.enable;
        message = ''
          The ${id} cluster nameserver is enabled, but the ${id} envoy gateway isn't.
          It technically isn't *necessary*, but some stuff (like resolver) assumes the nameserver is accessible via the gateway on port ${cfg.gatewayPort}.
        '';
      })
      instances;

    az.server.rke2.namespaces."app-nameserver" = {
      networkPolicy.fromNamespaces = ["envoy-gateway"];
      networkPolicy.extraEgress =
        lib.mapAttrsToList (
          _: cfg: {toCIDR = lib.concatMap (v: ["${v.ipv4}/32" "${v.ipv6}/128"]) (builtins.attrValues cfg.secondaryServers);}
        )
        instances;
    };

    az.server.rke2.images = {
      knot = {
        imageName = "cznic/knot";
        finalImageTag = "v3.5.0";
        imageDigest = "sha256:8148dd1e680ebe68b1d63d7d9b77513d3b7b70c720810ea3f3bd1b5f121da4e8";
        hash = "sha256-1hs0KSz+iN2A9n0pzrsD4Lmyi3M18ENs5l4zWY16xeg="; # renovate: cznic/knot v3.5.0
      };
    };
    services.rke2.manifests =
      lib.mapAttrs' (id: cfg: {
        name = "nameserver-${id}";
        value.content = [
          {
            apiVersion = "v1";
            kind = "PersistentVolumeClaim";
            metadata = {
              name = "knot-${id}-data";
              namespace = "app-nameserver";
            };
            spec = {
              accessModes = ["ReadWriteOnce"];
              resources.requests.storage = "10Mi"; # just keys & journal
            };
          }
          {
            apiVersion = "apps/v1";
            kind = "Deployment";
            metadata = {
              name = "knot-${id}";
              namespace = "app-nameserver";
            };
            spec = {
              selector.matchLabels.app = "knot-${id}";
              template.metadata.labels.app = "knot-${id}";

              replicas = 1; # hidden master, doesn't need HA
              strategy.type = "Recreate"; # ^^, doesn't matter if it goes down for a bit

              template.spec.securityContext = {
                runAsNonRoot = true;
                seccompProfile.type = "RuntimeDefault";
                runAsUser = 65534;
                runAsGroup = 65534;
                fsGroup = 65534;
              };
              template.spec.containers = [
                {
                  name = "knot-${id}";
                  image = images.knot.imageString;
                  command = ["knotd" "-c" "/config/knot.conf"];
                  volumeMounts = [
                    {
                      name = "knot-${id}-rundir";
                      mountPath = "/rundir";
                    }
                    {
                      name = "knot-${id}-data";
                      mountPath = "/storage";
                    }
                    {
                      name = "knot-${id}-config";
                      mountPath = "/config";
                      readOnly = true;
                    }
                  ];
                  securityContext = {
                    allowPrivilegeEscalation = false;
                    capabilities.drop = ["ALL"];
                  };
                }
              ];
              template.spec.volumes = [
                {
                  name = "knot-${id}-rundir";
                  emptyDir.sizeLimit = "100Mi";
                }
                {
                  name = "knot-${id}-data";
                  persistentVolumeClaim.claimName = "knot-${id}-data";
                }
                {
                  name = "knot-${id}-config";
                  secret.secretName = "knot-${id}-config";
                }
              ];
            };
          }

          {
            apiVersion = "v1";
            kind = "Service";
            metadata = {
              name = "knot-${id}";
              namespace = "app-nameserver";
            };
            spec = {
              selector.app = "knot-${id}";
              ipFamilyPolicy = "PreferDualStack";
              ipFamilies = ["IPv4" "IPv6"];
              ports = [
                # standard DNS for cluster-internal RFC2136 ACME or authoritative resolution
                {
                  name = "knot-udp";
                  port = 53;
                  protocol = "UDP";
                }
                {
                  name = "knot-tcp";
                  port = 53;
                  protocol = "TCP";
                }
                # DoQ, mainly for communication w/ secondaries
                {
                  name = "knot-doq";
                  port = 853;
                  protocol = "UDP";
                }
              ];
            };
          }

          {
            apiVersion = "gateway.networking.k8s.io/v1alpha2";
            kind = "UDPRoute";
            metadata = {
              name = "knot-${id}-udp";
              namespace = "app-nameserver";
            };
            spec = {
              parentRefs = [
                {
                  name = "envoy-gateway-${id}";
                  namespace = "envoy-gateway";
                  sectionName = "knot-udp";
                }
              ];
              rules = [
                {
                  backendRefs = [
                    {
                      name = "knot-${id}";
                      port = 53;
                    }
                  ];
                }
              ];
            };
          }
          {
            apiVersion = "gateway.networking.k8s.io/v1alpha2";
            kind = "TCPRoute";
            metadata = {
              name = "knot-${id}-tcp";
              namespace = "app-nameserver";
            };
            spec = {
              parentRefs = [
                {
                  name = "envoy-gateway-${id}";
                  namespace = "envoy-gateway";
                  sectionName = "knot-tcp";
                }
              ];
              rules = [
                {
                  backendRefs = [
                    {
                      name = "knot-${id}";
                      port = 53;
                    }
                  ];
                }
              ];
            };
          }
          {
            apiVersion = "gateway.networking.k8s.io/v1alpha2";
            kind = "UDPRoute";
            metadata = {
              name = "knot-${id}-doq";
              namespace = "app-nameserver";
            };
            spec = {
              parentRefs = [
                {
                  name = "envoy-gateway-${id}";
                  namespace = "envoy-gateway";
                  sectionName = "knot-doq";
                }
              ];
              rules = [
                {
                  backendRefs = [
                    {
                      name = "knot-${id}";
                      port = 853;
                    }
                  ];
                }
              ];
            };
          }
        ];
      })
      instances;

    az.server.rke2.secrets = lib.flatten (lib.mapAttrsToList (
        id: cfg:
          [
            {
              apiVersion = "v1";
              kind = "Secret";
              metadata = {
                name = "knot-${id}-config";
                namespace = "app-nameserver";
              };
              stringData =
                builtins.listToAttrs (builtins.map (zone: let
                    vpsConfig = lib.concatStrings (
                      lib.mapAttrsToList (_: vps:
                        lib.concatMapStrings (sub: ''
                          ${sub}              IN  AAAA          ${vps.ipv6}
                          ${lib.optionalString (vps ? ipv4) ''
                            ${sub}            IN  A             ${vps.ipv4}
                          ''}
                        '') (vps.zones.${zone}.${id} or []))
                      config.az.cluster.meta.vps
                    );
                  in {
                    name = "${zone}.zone";
                    value = (import ./zones/${azLib.reverseFQDN zone}.nix zone args).${id} + vpsConfig;
                  })
                  cfg.zones)
                // {"knot.conf" = import ./config.nix id cfg args;};
            }
          ]
          ++ lib.optional cfg.acmeTsig {
            apiVersion = "v1";
            kind = "Secret";
            metadata = {
              name = "${id}-rfc2136-tsig";
              namespace = "cert-manager";
            };
            stringData.secret = config.sops.placeholder."rke2/nameserver/${id}/tsig-secret";
          }
      )
      instances);

    # ACME
    az.server.rke2.clusterWideSecrets =
      lib.mapAttrs' (id: cfg: {
        name = "rke2/nameserver/${id}/tsig-secret";
        value = {};
      })
      (lib.filterAttrs (id: cfg: cfg.acmeTsig) instances);

    # GW listeners
    az.cluster.core.envoyGateway.gateways =
      lib.mapAttrs (id: cfg: {
        listeners = [
          {
            name = "knot-udp";
            protocol = "UDP";
            port = cfg.gatewayPort;
            allowedRoutes.namespaces.from = "All"; # TODO: Selector
            allowedRoutes.kinds = [{kind = "UDPRoute";}];
          }
          {
            name = "knot-tcp";
            protocol = "TCP";
            port = cfg.gatewayPort;
            allowedRoutes.namespaces.from = "All"; # TODO: Selector
            allowedRoutes.kinds = [{kind = "TCPRoute";}];
          }
          {
            name = "knot-doq";
            protocol = "UDP";
            port = 853;
            allowedRoutes.namespaces.from = "All"; # TODO: Selector
            allowedRoutes.kinds = [{kind = "UDPRoute";}];
          }
        ];
      })
      instances;
  };
}
