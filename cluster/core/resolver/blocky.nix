# unused, probably doesn't work as-is
{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  top = config.az.cluster.core.resolver;
  cfg = top.blocky;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.core.resolver.blocky = with azLib.opt; {
    upstreams = lib.mkOption {
      type = with lib.types; listOf str;
      default = ["unbound.app-resolver.svc"];
    };
    httpDomains = lib.mkOption {type = with lib.types; listOf str;};
  };

  config = lib.mkIf top.enable {
    az.server.rke2.namespaces."app-resolver" = {
      networkPolicy.fromNamespaces = ["envoy-gateway"];
      networkPolicy.toWAN = true; # blocklists
    };

    az.server.rke2.images = {
      blocky = {
        imageName = "spx01/blocky";
        finalImageTag = "v0.28.1";
        imageDigest = "sha256:e9af552da2b0849f9b3b48ae3169acb2696fdf0ddc65df52e4025c9deef04a60";
        hash = "sha256-geG9/FH4Ye8Puzz798zziuVcelcRiSPfie0o0N4lIas="; # renovate: spx01/blocky v0.28.1
      };
    };
    services.rke2.manifests."resolver".content =
      [
        {
          apiVersion = "v1";
          kind = "ConfigMap";
          metadata = {
            name = "blocky-cm";
            namespace = "app-resolver";
          };
          data."config.yml" = builtins.toJSON {
            upstreams.groups.default = cfg.upstreams;
            ports = {
              dns = 53;
              http = 80;
            };
            ede.enable = true;

            # https://v.firebog.net/hosts/lists.php?type=tick
            blocking.clientGroupsBlock.default = ["firebog"];
            blocking.denylists.firebog = [
              "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
              "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
              "https://v.firebog.net/hosts/static/w3kbl.txt"
              "https://adaway.org/hosts.txt"
              "https://v.firebog.net/hosts/AdguardDNS.txt"
              "https://v.firebog.net/hosts/Admiral.txt"
              "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
              "https://v.firebog.net/hosts/Easylist.txt"
              "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
              "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
              "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
              "https://v.firebog.net/hosts/Easyprivacy.txt"
              "https://v.firebog.net/hosts/Prigent-Ads.txt"
              "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
              "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
              "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
              "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
              "https://v.firebog.net/hosts/Prigent-Crypto.txt"
              "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
              "https://bitbucket.org/ethanr/dns-blacklists/raw/8575c9f96e5b4a1308f2f12394abd86d0927a4a0/bad_lists/Mandiant_APT1_Report_Appendix_D.txt"
              "https://phishing.army/download/phishing_army_blocklist_extended.txt"
              "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
              "https://v.firebog.net/hosts/RPiList-Malware.txt"
              "https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt"
              "https://raw.githubusercontent.com/AssoEchap/stalkerware-indicators/master/generated/hosts"
              "https://urlhaus.abuse.ch/downloads/hostfile/"
              "https://lists.cyberhost.uk/malware.txt"
            ];
          };
        }
        {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            name = "blocky";
            namespace = "app-resolver";
          };
          spec = {
            selector.matchLabels.app = "blocky";
            template.metadata.labels.app = "blocky";

            template.spec.securityContext = {
              runAsNonRoot = true;
              seccompProfile.type = "RuntimeDefault";
              # https://github.com/0xERR0R/blocky/blob/4fffb35ad80cb6493896a62c1893e8281c8fba90/Dockerfile#L40
              runAsUser = 100;
              runAsGroup = 100;
              fsGroup = 100;
              fsGroupChangePolicy = "OnRootMismatch";
            };

            template.spec.containers = [
              {
                name = "blocky";
                image = images.blocky.imageString;
                volumeMounts = [
                  {
                    name = "blocky-cm";
                    mountPath = "/app/config.yml";
                    subPath = "config.yml";
                  }
                ];
                securityContext = {
                  allowPrivilegeEscalation = false;
                  capabilities.drop = ["ALL"];
                  capabilities.add = ["NET_BIND_SERVICE"];
                  readOnlyRootFilesystem = true;
                };
              }
            ];

            template.spec.volumes = [
              {
                name = "blocky-cm";
                configMap = {
                  name = "blocky-cm";
                  items = [
                    {
                      key = "config.yml";
                      path = "config.yml";
                    }
                  ];
                };
              }
            ];
          };
        }

        {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            name = "blocky";
            namespace = "app-resolver";
          };
          spec = {
            selector.app = "blocky";
            ipFamilyPolicy = "SingleStack";
            ipFamilies = ["IPv6"];
            ports = [
              {
                name = "dns-udp";
                port = 53;
                protocol = "UDP";
              }
              {
                name = "dns-tcp";
                port = 53;
                protocol = "TCP";
              }
              {
                name = "http";
                port = 80;
                protocol = "TCP";
              }
            ];
          };
        }
      ]
      ++ lib.optionals config.az.cluster.core.envoyGateway.enable [
        {
          apiVersion = "gateway.networking.k8s.io/v1alpha2";
          kind = "UDPRoute";
          metadata = {
            name = "blocky-udp";
            namespace = "app-resolver";
          };
          spec = {
            parentRefs = [
              {
                name = "envoy-gateway";
                namespace = "envoy-gateway";
                sectionName = "blocky-udp";
              }
            ];
            rules = [
              {
                backendRefs = [
                  {
                    group = "";
                    kind = "Service";
                    weight = 1;
                    name = "blocky";
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
            name = "blocky-tcp";
            namespace = "app-resolver";
          };
          spec = {
            parentRefs = [
              {
                name = "envoy-gateway";
                namespace = "envoy-gateway";
                sectionName = "blocky-tcp";
              }
            ];
            rules = [
              {
                backendRefs = [
                  {
                    name = "blocky";
                    port = 53;
                  }
                ];
              }
            ];
          };
        }
      ];

    az.cluster.core.envoyGateway.httpRoutes =
      lib.concatMap (domain: [
        {
          name = "blocky";
          namespace = "app-resolver";
          hostnames = ["dns.${domain}"];
          rules = [
            {
              backendRefs = [
                {
                  name = "blocky";
                  port = 80;
                }
              ];
            }
          ];
        }
      ])
      cfg.httpDomains;

    az.cluster.core.auth.authelia.rules =
      lib.concatMap (domain: [
        {
          domain = ["dns.${domain}"];
          policy = "bypass";
          resources = ["^/dns-query.*"];
        }
        {
          domain = ["dns.${domain}"];
          subject = "group:admin";
          policy = "two_factor";
        }
      ])
      cfg.httpDomains;

    az.cluster.core.envoyGateway.listeners = [
      {
        name = "blocky-udp";
        protocol = "UDP";
        port = 53;
        allowedRoutes.namespaces.from = "All"; # TODO: Selector
        allowedRoutes.kinds = [{kind = "UDPRoute";}];
      }
      {
        name = "blocky-tcp";
        protocol = "TCP";
        port = 53;
        allowedRoutes.namespaces.from = "All"; # TODO: Selector
        allowedRoutes.kinds = [{kind = "TCPRoute";}];
      }
    ];
  };
}
