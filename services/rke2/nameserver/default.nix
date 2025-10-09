# TODO: docs - knotc status cert-key, keymgr <zone> ds
{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
} @ args:
with lib; let
  cfg = config.az.svc.rke2.nameserver;
  images = config.az.server.rke2.images;
in {
  options.az.svc.rke2.nameserver = with azLib.opt; {
    enable = optBool false;
    domains = mkOption {
      type = with types;
        attrsOf (submodule ({name, ...}: {
          options = {
            domain = optStr name;
            zonefile = optStr (azLib.reverseFQDN name);

            # knot-${id} name for pods, services, etc
            id = let
              # service names are DNS names, so can't use dots
              sanitize = builtins.replaceStrings "." "--";
            in
              optStr "${sanitize name}-${sanitize (azLib.reverseFQDN name)}";

            secondaryServers = mkOption {
              type = with types; listOf attrs;
              default =
                if outputs.infra.domains ? ${name}
                then builtins.filter (remote: remote ? knotPubkey) outputs.infra.domains.${name}.vps
                else [];
            };
            acmeTsig = optBool true;

            gateways = mkOption {
              type = with types; listOf str;
              default = [];
            };
          };
        }));
      default = {};
    };
  };

  config = mkIf cfg.enable {
    az.server.rke2.namespaces."app-nameserver" = {
      networkPolicy.fromNamespaces = ["envoy-gateway"];
      networkPolicy.extraEgress =
        lib.attrsets.mapAttrsToList (_: {secondaryServers, ...}: {
          toCIDR =
            lib.lists.flatten (builtins.map (v: ["${v.ipv4}/32" "${v.ipv6}/128"]) secondaryServers);
        })
        cfg.domains;
    };

    # default domain
    az.svc.rke2.nameserver.domains.${config.az.server.rke2.baseDomain} = {
      id = "public";
      gateways = lib.lists.optional config.az.svc.rke2.envoyGateway.enable "external";
    };

    az.server.rke2.images = {
      knot = {
        imageName = "cznic/knot";
        finalImageTag = "v3.5.0";
        imageDigest = "sha256:8148dd1e680ebe68b1d63d7d9b77513d3b7b70c720810ea3f3bd1b5f121da4e8";
        hash = "sha256-1hs0KSz+iN2A9n0pzrsD4Lmyi3M18ENs5l4zWY16xeg="; # renovate: cznic/knot
      };
    };
    az.server.rke2.manifests."app-nameserver" = lib.lists.flatten (lib.attrsets.mapAttrsToList (
        _: {
          id,
          domain,
          zonefile,
          acmeTsig,
          gateways,
          ...
        } @ domainConf:
          [
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
              apiVersion = "v1";
              kind = "Secret";
              metadata = {
                name = "knot-${id}-config";
                namespace = "app-nameserver";
              };
              stringData = {
                "${zonefile}.zone" = import ./zones/${zonefile}.nix domainConf args;
                "knot.conf" = import ./config.nix domainConf args;
              };
            }
            (mkIf acmeTsig {
              apiVersion = "v1";
              kind = "Secret";
              metadata = {
                name = "${id}-rfc2136-tsig";
                namespace = "cert-manager";
              };
              stringData.secret = config.sops.placeholder."rke2/nameserver/${id}/tsig-secret";
            })
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
                strategy.type = "Recreate"; # same as ^^, doesn't matter if it goes down for a bit

                template.spec.securityContext = {
                  runAsNonRoot = true;
                  seccompProfile.type = "RuntimeDefault";
                  runAsUser = 65534;
                  runAsGroup = 65534;
                  fsGroup = 65534;
                };
                template.spec.containers = [
                  {
                    name = "knot";
                    image = images.knot.imageString;
                    command = ["knotd" "-c" "/config/knot.conf"];
                    volumeMounts = [
                      {
                        name = "knot-rundir";
                        mountPath = "/rundir";
                      }
                      {
                        name = "knot-data";
                        mountPath = "/storage";
                      }
                      {
                        name = "knot-config";
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
                    name = "knot-rundir";
                    emptyDir.sizeLimit = "100Mi";
                  }
                  {
                    name = "knot-data";
                    persistentVolumeClaim.claimName = "knot-${id}-data";
                  }
                  {
                    name = "knot-config";
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
                  # standard DNS for cluster-internal RFC2136 ACME or manual authoritative resolution
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
          ]
          ++ lib.lists.optionals ((builtins.length gateways) != 0) [
            {
              apiVersion = "gateway.networking.k8s.io/v1alpha2";
              kind = "UDPRoute";
              metadata = {
                name = "knot-${id}-udp";
                namespace = "app-nameserver";
              };
              spec = {
                parentRefs =
                  lib.lists.map (name: {
                    name = "envoy-gateway-${name}";
                    namespace = "envoy-gateway";
                    sectionName = "knot-udp";
                  })
                  gateways;
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
                parentRefs =
                  lib.lists.map (name: {
                    name = "envoy-gateway-${name}";
                    namespace = "envoy-gateway";
                    sectionName = "knot-tcp";
                  })
                  gateways;
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
                parentRefs =
                  lib.lists.map (name: {
                    name = "envoy-gateway-${name}";
                    namespace = "envoy-gateway";
                    sectionName = "knot-doq";
                  })
                  gateways;
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
          ]
      )
      cfg.domains);

    # ACME
    az.server.rke2.clusterWideSecrets = lib.attrsets.mapAttrs' (_: {id, ...}: {
      name = "rke2/nameserver/${id}/tsig-secret";
      value = {};
    }) (lib.attrsets.filterAttrs (_: {acmeTsig, ...}: acmeTsig) cfg.domains);

    # GW listeners
    az.svc.rke2.envoyGateway.gateways = builtins.listToAttrs (builtins.map (gateway: {
      name = gateway;
      value.listeners = [
        {
          name = "knot-udp";
          protocol = "UDP";
          port = 53;
          allowedRoutes.namespaces.from = "All"; # TODO: Selector
          allowedRoutes.kinds = [{kind = "UDPRoute";}];
        }
        {
          name = "knot-tcp";
          protocol = "TCP";
          port = 53;
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
    }) (lib.lists.unique (lib.attrsets.foldlAttrs (acc: _: {gateways, ...}: acc ++ gateways) [] cfg.domains)));
  };
}
