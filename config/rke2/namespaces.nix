# CRITICAL TODO
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
              mutualAuth = optBool true;

              # allow from/to specific namespace, always includes self
              fromNamespaces = mkOption {
                type = listOf str;
                default = [];
              };
              toNamespaces = mkOption {
                type = listOf str;
                default = [];
              };

              # https://docs.cilium.io/en/stable/security/policy/language/#dns-based
              toDomains = mkOption {
                type = listOf str;
                default = [];
              };

              # allow from/to all non-LAN addrs
              toWAN = optBool false;
              fromWAN = optBool false;

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
        networkPolicy.extraIngress = [{fromEntities = ["cluster"];}];
        networkPolicy.extraEgress = [
          {toEntities = ["cluster"];}
          {toPorts = [{ports = [{port = "53";}];}];} # coredns
        ];
      };
    };

    az.server.rke2.manifests."00-namespaces" = let
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
          /*
          ++ [
            {
              apiVersion = "cilium.io/v2";
              kind = "CiliumNetworkPolicy";
              metadata = {
                name = "az-network-policy";
                namespace = ns.name;
              };
              spec = {
                endpointSelector = {};
                ingress =
                  ns.networkPolicy.extraIngress
                  ++ [
                    (lib.attrsets.optionalAttrs ns.networkPolicy.mutualAuth {authentication.mode = "required";}
                      // {
                        fromEndpoints =
                          builtins.map (namespace: {matchLabels."k8s:io.kubernetes.pod.namespace" = namespace;})
                          (ns.networkPolicy.fromNamespaces ++ [ns.name]);
                      })
                  ];
                egress =
                  ns.networkPolicy.extraEgress
                  ++ [
                    {
                      toEndpoints =
                        # toNamespaces
                        builtins.map (namespace: {matchLabels."k8s:io.kubernetes.pod.namespace" = namespace;})
                        (ns.networkPolicy.toNamespaces ++ [ns.name]);
                    }
                    {
                      # allow DNS lookups - https://docs.cilium.io/en/stable/security/policy/language/#example
                      toEndpoints = [
                        {
                          matchLabels = {
                            "k8s:io.kubernetes.pod.namespace" = "kube-system";
                            "k8s:k8s-app" = "kube-dns";
                          };
                        }
                      ];
                      toPorts = [
                        {
                          ports = [
                            {
                              port = "53";
                              protocol = "ANY";
                            }
                          ];
                          rules.dns = [{matchPattern = "*";}];
                        }
                      ];
                    }
                    # toDomains
                    {toFQDNs = builtins.map (name: {matchPattern = name;}) ns.networkPolicy.toDomains;}
                  ]
                  # toWAN
                  ++ lib.lists.optionals ns.networkPolicy.toWAN [
                    {toCIDR = ["2000::/3"];}
                    {
                      toCIDRSet = [
                        {
                          cidr = "0.0.0.0/0";
                          except = lanCIDRs;
                        }
                      ];
                    }
                  ]
                  ++ lib.lists.optionals ns.networkPolicy.fromWAN [
                    {fromCIDR = ["2000::/3"];}
                    {
                      fromCIDRSet = [
                        {
                          cidr = "0.0.0.0/0";
                          except = lanCIDRs;
                        }
                      ];
                    }
                  ];
              };
            }
          ]
          */
        )
        cfg.namespaces);
  };
}
