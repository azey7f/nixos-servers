{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  top = config.az.cluster.core.resolver;
  images = config.az.server.rke2.images;
in {
  config = lib.mkIf top.enable {
    az.server.rke2.namespaces."app-resolver" = {
      networkPolicy.toNamespaces = ["envoy-gateway"];
      networkPolicy.toPorts = {
        tcp = [53];
        udp = [53];
      };
    };
    az.server.rke2.namespaces."envoy-gateway".networkPolicy.fromNamespaces = ["app-resolver"];

    az.server.rke2.images = {
      unbound = {
        imageName = "klutchell/unbound";
        finalImageTag = "1.24.1";
        imageDigest = "sha256:e506a417d3e3673a259bb1c2cd2e843cf20b3847f3f33853f785395766a5d3c4";
        hash = "sha256-GIse0o3Ao8049yhZ16XuWtdqQHSjXK2jdVbzfmsUVnM="; # renovate: klutchell/unbound 1.24.1
      };
    };
    services.rke2.manifests."resolver".content = [
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "unbound-cm";
          namespace = "app-resolver";
        };
        data."unbound.conf" = ''
          server:
          	# container is started with correct user
          	username: ""

          	# networking
          	interface: ::0
          	do-ip4: yes
          	do-ip6: yes
          	do-udp: yes
          	do-tcp: yes
          	access-control: 0.0.0.0/0 allow
          	access-control: ::/0 allow

          	# misc hardening & stuff
          	ede: yes
          	harden-glue: yes
          	harden-large-queries: yes
          	harden-below-nxdomain: yes
          	harden-referral-path: yes
          	harden-algo-downgrade: yes
          	harden-short-bufsize: yes
          	harden-dnssec-stripped: yes
          	val-clean-additional: yes
          	aggressive-nsec: yes
          	use-caps-for-id: no
          	hide-identity: yes
          	hide-version: yes
          	msg-cache-size: 128m
          	msg-cache-slabs: 2
          	rrset-roundrobin: yes
          	rrset-cache-size: 256m
          	rrset-cache-slabs: 2
          	key-cache-size: 256m
          	key-cache-slabs: 2
          	cache-min-ttl: 0
          	serve-expired: yes
          	prefetch: yes
          	prefetch-key: yes
          	so-reuseport: yes

          ${
            lib.optionalString config.az.cluster.core.nameserver.enable (
              lib.concatMapStringsSep "\n" (domain: ''
                # resolve private addrs for ${domain}
                	private-domain: "${domain}."
                # use local authoritative NS for ${domain}
                	forward-zone:
                		name: "${domain}."
                		forward-addr: "${config.az.cluster.core.envoyGateway.address}@53"
                		forward-no-cache: yes
                		forward-tcp-upstream: yes
              '')
              config.az.cluster.core.nameserver.zones
            )
          }
        '';
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "unbound";
          namespace = "app-resolver";
        };
        spec = {
          selector.matchLabels.app = "unbound";
          template.metadata.labels.app = "unbound";

          template.spec.securityContext = {
            runAsNonRoot = true;
            seccompProfile.type = "RuntimeDefault";
            # https://github.com/klutchell/unbound-docker/blob/506f2cde47aaa32e54c9df1740f1c9b2986d9f8a/Dockerfile#L23-L24
            runAsUser = 101;
            runAsGroup = 102;
            fsGroup = 102;
          };

          template.spec.containers = [
            {
              name = "unbound";
              image = images.unbound.imageString;
              volumeMounts = [
                {
                  name = "unbound-cm";
                  mountPath = "/etc/unbound/custom.conf.d";
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
              name = "unbound-cm";
              configMap = {
                name = "unbound-cm";
                items = [
                  {
                    key = "unbound.conf";
                    path = "unbound.conf";
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
          name = "unbound";
          namespace = "app-resolver";
        };
        spec = {
          selector.app = "unbound";
          ipFamilyPolicy = "SingleStack";
          ipFamilies = ["IPv6"];
          ports = [
            {
              name = "dns-tcp";
              port = 53;
              protocol = "TCP";
            }
            {
              name = "dns-udp";
              port = 53;
              protocol = "UDP";
            }
          ];
        };
      }
    ];
  };
}
