{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.server.rke2;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.server.rke2 = with azLib.opt; {
    namespaces = mkOption {
      type = with types;
        attrsOf (submodule ({name, ...}: {
          options = {
            name = optStr name;
            create = optBool true;

            mullvadRouted = optBool false;
            legacyIP = optBool false;

            podSecurity = mkOption {
              type = nullOr str;
              default = null;
            };

            networkPolicy = {
              # allow from/to specific namespace, always includes self
              fromNamespaces = mkOption {
                type = listOf str;
                default = [];
              };
              toNamespaces = mkOption {
                type = listOf str;
                default = [];
              };

              /*
              # enterprise-only feature in calico :/
                     toDomains = mkOption {
                       type = listOf str;
                       default = [];
                     };
              */

              toPorts = {
                tcp = mkOption {
                  type = listOf (oneOf [str int]);
                  default = [];
                };
                udp = mkOption {
                  type = listOf (oneOf [str int]);
                  default = [];
                };
              };

              toCIDR = mkOption {
                type = listOf str;
                default = [];
              };
              fromCIDR = mkOption {
                type = listOf str;
                default = [];
              };

              # allow to/from cluster prefix
              toCluster = optBool false;
              fromCluster = optBool false;
              # allow to all non-LAN addrs
              toWAN = optBool false;

              # custom
              extraIngress = mkOption {
                type = listOf attrs;
                default = [];
              };
              extraEgress = mkOption {
                type = listOf attrs;
                default = [];
              };
            };
          };
        }));
      default = {};
    };
  };

  config = mkIf cfg.enable {
    az.server.rke2.namespaces = {
      "default".create = false; # nothing should be running in default anyways
      "kube-system" = {
        networkPolicy.fromCluster = true;
        networkPolicy.toCluster = true;
        networkPolicy.toPorts = {
          # coredns
          tcp = [53];
          udp = [53];
        };
      };
    };

    az.server.rke2.manifests."00-namespaces" = let
      clusterPrefixes = [
        "${config.az.cluster.net.prefix}00::/${toString config.az.cluster.net.prefixSize}"
        "${config.az.cluster.net.mullvad.ipv6}::/64"
      ];

      # https://en.wikipedia.org/wiki/Reserved_IP_addresses as of this commit
      # IPv6 list not needed since publicly routable addrs are just 2000::/3 (yay!)
      # 2000::/3 includes some non-routable stuff like 2001:db8::/32, but not ULAs/link-locals/etc which is what's important
      lanCIDRs = [
        "0.0.0.0/8"
        "10.0.0.0/8"
        "100.64.0.0/10"
        "127.0.0.0/8"
        "169.254.0.0/16"
        "172.16.0.0/12"
        "192.0.0.0/24"
        "192.0.2.0/24"
        "192.168.0.0/16"
        "198.18.0.0/15"
        "198.51.100.0/24"
        "203.0.113.0/24"
        "233.252.0.0/24"
        "255.255.255.255/32"
      ];
    in
      lib.lists.flatten (lib.attrsets.mapAttrsToList (
          _: ns:
            lib.lists.optional ns.create {
              apiVersion = "v1";
              kind = "Namespace";
              metadata.name = ns.name;
              metadata.labels =
                {name = ns.name;}
                // lib.attrsets.optionalAttrs (ns.podSecurity != null)
                {"pod-security.kubernetes.io/enforce" = ns.podSecurity;};
              metadata.annotations = let
                mullvad = config.az.cluster.net.mullvad.enable;
              in
                {
                  "cni.projectcalico.org/ipFamilies" = builtins.toJSON (
                    ["IPv6"] ++ lib.optional (mullvad && ns.legacyIP) "IPv4"
                  );
                }
                // lib.optionalAttrs (mullvad && ns.mullvadRouted) {
                  "cni.projectcalico.org/ipv6pools" = builtins.toJSON ["mullvad"];
                }
                // lib.optionalAttrs (mullvad && ns.legacyIP) {
                  "cni.projectcalico.org/ipv4pools" = builtins.toJSON ["mullvad-legacy"];
                };
            }
            ++ [
              {
                apiVersion = "projectcalico.org/v3";
                kind = "NetworkPolicy";
                metadata = {
                  name = "az-network-policy";
                  namespace = ns.name;
                };
                spec = {
                  performanceHints = ["AssumeNeededOnEveryNode"];
                  ingress =
                    ns.networkPolicy.extraIngress
                    # fromNamespaces
                    ++ [
                      {
                        action = "Allow";
                        source.namespaceSelector = "name in { ${
                          lib.concatMapStringsSep ", " (name: "'${name}'") (
                            ns.networkPolicy.fromNamespaces ++ [ns.name]
                          )
                        } }";
                      }
                    ]
                    # fromCluster
                    ++ lib.optional ns.networkPolicy.fromCluster {
                      action = "Allow";
                      source.nets = clusterPrefixes;
                    }
                    # fromCIDR
                    ++ lib.lists.optional (ns.networkPolicy.fromCIDR != []) {
                      action = "Allow";
                      source.nets = ns.networkPolicy.fromCIDR;
                    };
                  egress =
                    ns.networkPolicy.extraEgress
                    # allow DNS lookups
                    ++ [
                      {
                        action = "Allow";
                        protocol = "UDP";
                        destination = {
                          selector = "k8s-app == 'kube-dns'";
                          namespaceSelector = "name == 'kube-system'";
                          ports = [53];
                        };
                      }
                      {
                        action = "Allow";
                        protocol = "TCP";
                        destination = {
                          selector = "k8s-app == 'kube-dns'";
                          namespaceSelector = "name == 'kube-system'";
                          ports = [53];
                        };
                      }
                      # toNamespaces
                      {
                        action = "Allow";
                        destination.namespaceSelector = "name in { ${
                          lib.concatMapStringsSep ", " (name: "'${name}'") (
                            ns.networkPolicy.toNamespaces ++ [ns.name]
                          )
                        } }";
                      }
                    ]
                    # toPorts
                    ++ lib.optional (ns.networkPolicy.toPorts.tcp != []) {
                      action = "Allow";
                      protocol = "TCP";
                      destination.ports = ns.networkPolicy.toPorts.tcp;
                    }
                    ++ lib.optional (ns.networkPolicy.toPorts.udp != []) {
                      action = "Allow";
                      protocol = "UDP";
                      destination.ports = ns.networkPolicy.toPorts.udp;
                    }
                    # toCluster
                    ++ lib.optional ns.networkPolicy.toCluster {
                      action = "Allow";
                      destination.nets = clusterPrefixes;
                    }
                    # toCIDR
                    ++ lib.lists.optional (ns.networkPolicy.toCIDR != []) {
                      action = "Allow";
                      destination.nets = ns.networkPolicy.toCIDR;
                    }
                    # toWAN
                    ++ lib.lists.optionals ns.networkPolicy.toWAN [
                      {
                        action = "Allow";
                        destination.nets = ["2000::/3"];
                        destination.notNets = clusterPrefixes;
                      }
                      {
                        action = "Allow";
                        destination.notNets = lanCIDRs;
                      }
                    ];
                };
              }
            ]
        )
        cfg.namespaces);
  };
}
