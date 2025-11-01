{
  pkgs,
  config,
  lib,
  azLib,
  ...
} @ args: let
  cfg = config.az.cluster.core.nameserver;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.core.nameserver = with azLib.opt; {
    enable = optBool false;

    address = optStr "${config.az.cluster.net.prefix}${config.az.cluster.net.static}::53";

    # see ./zones, files are named by reversed FQDN for sorting reasons
    zones = lib.mkOption {
      type = with lib.types; listOf str;
      default = builtins.attrNames config.az.cluster.domains;
    };

    secondaryServers = lib.mkOption {
      type = with lib.types; attrsOf anything; # see cluster/default.nix meta.vps def
      default = config.az.cluster.meta.vps;
    };
    acmeTsig = optBool true;
  };

  config = lib.mkIf cfg.enable {
    az.server.rke2.namespaces."app-nameserver" = {
      networkPolicy.extraIngress = [{fromEntities = ["all"];}];
      networkPolicy.extraEgress = [
        {toCIDR = lib.concatMap (v: ["${v.ip}/128"]) (builtins.attrValues cfg.secondaryServers);}
      ];
    };

    az.server.rke2.images = {
      knot = {
        imageName = "cznic/knot";
        finalImageTag = "v3.5.0";
        imageDigest = "sha256:8148dd1e680ebe68b1d63d7d9b77513d3b7b70c720810ea3f3bd1b5f121da4e8";
        hash = "sha256-1hs0KSz+iN2A9n0pzrsD4Lmyi3M18ENs5l4zWY16xeg="; # renovate: cznic/knot v3.5.0
      };
    };
    services.rke2.manifests."nameserver".content = [
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "knot-data";
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
          name = "knot";
          namespace = "app-nameserver";
        };
        spec = {
          selector.matchLabels.app = "knot";
          template.metadata.labels.app = "knot";

          replicas = 1; # TODO: HA
          strategy.type = "Recreate";

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
              persistentVolumeClaim.claimName = "knot-data";
            }
            {
              name = "knot-config";
              secret.secretName = "knot-config";
            }
          ];
        };
      }

      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "knot";
          namespace = "app-nameserver";
        };
        spec = {
          selector.app = "knot";
          ipFamilyPolicy = "SingleStack";
          ipFamilies = ["IPv6"];
          externalIPs = [cfg.address];
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
    ];

    az.server.rke2.secrets =
      [
        {
          apiVersion = "v1";
          kind = "Secret";
          metadata = {
            name = "knot-config";
            namespace = "app-nameserver";
          };
          stringData =
            builtins.listToAttrs (builtins.map (zone: let
                vpsConfig = lib.concatStrings (
                  lib.mapAttrsToList (_: vps:
                    lib.concatMapStrings (sub: ''
                      ${sub}              IN  AAAA          ${vps.ip}
                      ${lib.optionalString (vps ? ipv4) ''
                        ${sub}            IN  A             ${vps.ipv4}
                      ''}
                    '') (vps.zones.${zone} or []))
                  config.az.cluster.meta.vps
                );
              in {
                name = "${zone}.zone";
                value = (import ./zones/${azLib.reverseFQDN zone}.nix zone args) + vpsConfig;
              })
              cfg.zones)
            // {"knot.conf" = import ./config.nix cfg args;};
        }
      ]
      ++ lib.optional cfg.acmeTsig {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "rfc2136-tsig";
          namespace = "cert-manager";
        };
        stringData.secret = config.sops.placeholder."rke2/nameserver/tsig-secret";
      };

    # ACME
    az.server.rke2.clusterWideSecrets = lib.optionalAttrs cfg.acmeTsig {
      "rke2/nameserver/tsig-secret" = {};
    };
  };
}
