{
  pkgs,
  config,
  lib,
  azLib,
  ...
} @ args: let
  cfg = config.az.cluster.core.mailserver;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.core.mailserver = with azLib.opt; {
    enable = optBool false;

    # :25:: itself is used for the service, :25::1 and up are for pods
    prefix = optStr "${config.az.cluster.net.prefix}${config.az.cluster.net.static}:25";

    primaryDomain = lib.mkOption {type = lib.types.str;};
    domains = lib.mkOption {
      type = with lib.types;
        attrsOf (submodule ({name, ...}: let
          domain = name;
        in {
          options = {
            accounts = lib.mkOption {
              type = attrsOf (submodule ({name, ...}: {
                options = {
                  noCustomPasswd = optBool true;

                  fullName = lib.mkOption {
                    type = with lib.types; nullOr str;
                    default = name;
                  };
                  quota = lib.mkOption {
                    type = with lib.types; nullOr int;
                    default = null;
                  };

                  destinations = lib.mkOption {
                    type = attrsOf (submodule {
                      options = {
                        mailbox = optStr "Inbox";

                        smtpError = lib.mkOption {
                          type = with lib.types; nullOr ints.positive;
                          default = null;
                        };
                        fullName = lib.mkOption {
                          type = with lib.types; nullOr str;
                          default = null;
                        };
                        rulesets = lib.mkOption {
                          type = with lib.types; listOf str;
                          default = [];
                        };
                      };
                    });
                    default."${name}@${domain}" = {};
                  };
                };
              }));
              default = {};
            };
          };
        }));
      default.${cfg.primaryDomain}.accounts = {
        "admin" = {};
      };
    };
  };

  config = lib.mkIf cfg.enable {
    az.server.rke2.namespaces."app-mailserver" = {
      networkPolicy.fromNamespaces = ["envoy-gateway"];
      networkPolicy.toWAN = true;
      networkPolicy.fromCIDR = ["::/0"];
      podSecurity = "privileged"; # "mox must be started as root, and will drop privileges after binding required sockets"
      legacyIP = true; # only for sendgrid, inbound v4 is reverse proxied (yeah yeah I know, whatever, I'll fix it later)
    };

    az.server.rke2.images = {
      mox = {
        imageName = "r.xmox.nl/mox";
        finalImageTag = "v0.0.15";
        imageDigest = "sha256:47497222e83679f95049329f12c5d8c4bfd3b809e62d4ffcfd508907e66b06a5";
        hash = "sha256-TeOTZy799+O/EJSY0865V6wcY+l4Zeg43U5wNTSASuM="; # renovate: r.xmox.nl/mox v0.0.15
      };
    };
    az.server.rke2.secrets = [
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "mox-config";
          namespace = "app-mailserver";
        };
        data =
          {
            "host.rsa2048.key" = config.sops.placeholder."rke2/mailserver/hostkeys/rsa2048.key";
            "host.ecdsap256.key" = config.sops.placeholder."rke2/mailserver/hostkeys/ecdsap256.key";
          }
          // lib.mapAttrs' (domain: _: {
            name = "${azLib.reverseFQDN domain}.2025a.key";
            value = config.sops.placeholder."rke2/mailserver/dkim/${azLib.reverseFQDN domain}.2025a.key";
          })
          cfg.domains;
        stringData = {
          "mox.conf" = import ./mox.nix args;
          "domains.conf" = import ./domains.nix args;
          "passwd-admin" = config.sops.placeholder."rke2/mailserver/passwd-admin";
        };
      }
    ];

    services.rke2.manifests."mailserver".content = [
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "mox-data";
          namespace = "app-mailserver";
        };
        spec = {
          accessModes = ["ReadWriteOnce"];
          resources.requests.storage = "10Gi";
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "StatefulSet";
        metadata = {
          name = "mox";
          namespace = "app-mailserver";
        };
        spec = {
          selector.matchLabels.app = "mox";
          template.metadata.labels.app = "mox";
          serviceName = "mox";

          # TODO: figure out how to set addrs dynamically based on ordinal, or give up and use multiple StatefulSets
          # ^^^^ will only be useful when/if mox starts supporting syncing between multiple servers
          template.metadata.annotations."cni.projectcalico.org/ipAddrs" = builtins.toJSON ["${cfg.prefix}::1" "172.30.0.111"]; # v4 doesn't matter

          template.spec.dnsConfig.options = [
            {name = "edns0";}
            {name = "trust-ad";}
          ];

          template.spec.securityContext = {
            # runAsNonRoot = true;
            seccompProfile.type = "RuntimeDefault";
            # runAsUser = 65534;
            # runAsGroup = 65534;
            # fsGroup = 65534;
          };

          template.spec.containers = [
            {
              name = "mox";
              image = images.mox.imageString;
              #command = ["sleep" "infinity"];
              env = [(lib.nameValuePair "MOX_DOCKER" "yes")];
              volumeMounts = [
                {
                  name = "mox-data";
                  mountPath = "/mox/data";
                }
                {
                  name = "mox-conf";
                  mountPath = "/mox/config";
                  readOnly = true;
                }
              ];
              securityContext = {
                allowPrivilegeEscalation = false;
                #capabilities.drop = ["ALL"]; # fork/exec /bin/mox: operation not permitted"
              };
            }
          ];
          template.spec.volumes = [
            {
              name = "mox-data";
              persistentVolumeClaim.claimName = "mox-data";
            }
            {
              name = "mox-conf";
              secret.secretName = "mox-config";
            }
          ];
        };
      }

      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "mox";
          namespace = "app-mailserver";
        };
        spec = {
          selector.app = "mox";
          ipFamilyPolicy = "SingleStack";
          ipFamilies = ["IPv6"];
          externalIPs = ["${cfg.prefix}::"];
          ports = [
            {
              name = "smtp";
              port = 25;
              protocol = "TCP";
            }
            {
              name = "smtps";
              port = 465;
              protocol = "TCP";
            }
            {
              name = "imaps";
              port = 993;
              protocol = "TCP";
            }
            {
              # only for SMTPS/IMAPS & STARTTLS ACME certs, and autoconfig+mta-sts
              name = "https";
              port = 443;
              protocol = "TCP";
            }
          ];
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "mox-http";
          namespace = "app-mailserver";
        };
        spec = {
          selector.app = "mox";
          ipFamilyPolicy = "SingleStack";
          ipFamilies = ["IPv6"];
          ports = [
            {
              name = "http";
              port = 8080;
              protocol = "TCP";
            }
          ];
        };
      }
    ];

    /*
    az.cluster.domains = lib.listToAttrs (
      builtins.map (domain: {
        nginx = {
          enable = true;
          sites."mta-sts" = {
            git.enable = false;
            nginxExtraConfig = ''
              location /.well-known/mta-sts.txt {
              	add_header content-type 'text/plain; charset=UTF-8';
              	return 200 'version: STSv1\nmode: enforce\nmx: mx.${domain}\nmax_age: 604800\n';
              }
            '';
          };
        };
      })
      cfg.domains
    );
    */

    az.cluster.core.envoyGateway.httpRoutes = [
      {
        name = "mailserver";
        namespace = "app-mailserver";
        hostnames = ["mail.${cfg.primaryDomain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "mox-http";
                port = 8080;
              }
            ];
          }
        ];
        csp = "lax";
      }
    ];

    az.cluster.core.auth.authelia.rules = [
      {
        domain = ["mail.${cfg.primaryDomain}"];
        subject = "group:admin";
        policy = "two_factor";
      }
    ];

    az.server.rke2.clusterWideSecrets =
      (lib.mapAttrs' (domain: _: (
          lib.nameValuePair "rke2/mailserver/dkim/${azLib.reverseFQDN domain}.2025a.key" {}
        ))
        cfg.domains)
      // {
        "rke2/mailserver/passwd-admin" = {};
        "rke2/mailserver/passwd-smtp2go" = {};
        "rke2/mailserver/hostkeys/ecdsap256.key" = {};
        "rke2/mailserver/hostkeys/rsa2048.key" = {};
      };
  };
}
