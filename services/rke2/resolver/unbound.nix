{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  top = config.az.svc.rke2.resolver;
  cfg = top.unbound;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.resolver.unbound = with azLib.opt; {
    enable = optBool top.enable;
  };

  config = mkIf cfg.enable {
    az.server.rke2.manifests."app-resolver" = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "app-resolver";
        metadata.labels.name = "app-resolver";
      }
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

          	# resolve private addrs
          	private-domain: "${domain}."

          ${
            if config.az.svc.rke2.nameserver.enable
            then ''
              # use local authoritative NS for domain
              # note that this uses the public NS, internal records are handled in blocky if enabled
              	forward-zone:
              		name: "${domain}."
              		forward-addr: "${config.az.svc.rke2.envoyGateway.gateways.external.addresses.ipv6}"
            ''
            else ""
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
              image = "klutchell/unbound:1.23.1";
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
          ipFamilyPolicy = "PreferDualStack";
          ipFamilies = ["IPv4" "IPv6"];
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
