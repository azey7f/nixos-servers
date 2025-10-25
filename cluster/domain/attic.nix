# TODO: move to rook ceph S3 storage whenever I finally upgrade to an actual cluster, also switch to Deployment w/ multiple replicas
{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  domains = lib.filterAttrs (_: v: v.enable) config.az.cluster.domainSpecific.attic;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.domainSpecific.attic = lib.mkOption {
    type = with lib.types;
      attrsOf (submodule {
        options = with azLib.opt; {
          enable = optBool false;
        };
      });
    default = {};
  };

  config = lib.mkIf (domains != {}) {
    az.cluster.core.cnpg.enable = true;

    az.server.rke2.namespaces."app-attic" = {
      networkPolicy.fromNamespaces = ["envoy-gateway" "app-woodpecker-steps"];
    };
    az.server.rke2.namespaces."app-woodpecker-steps".networkPolicy.toNamespaces = ["app-attic"];

    az.server.rke2.images = {
      attic = {
        # what the fuck is a semver
        imageName = "ghcr.io/zhaofengli/attic";
        finalImageTag = "59d60f266ce854e05143c5003b67fe07bcd562a6";
        imageDigest = "sha256:d7335b391f3a0a31f2bc7dfc34632bd9595b065079b20b52c71e99df070d8fab";
        hash = "sha256-ju3Vi4p5dMLOPIHhV6Po+o1qT0DgWrALHx/6rwIrrO8="; # renovate: ghcr.io/zhaofengli/attic 59d60f266ce854e05143c5003b67fe07bcd562a6
      };
    };
    az.server.rke2.secrets = [
      {
        apiVersion = "v1";
        kind = "Secret";
        type = "kubernetes.io/basic-auth";
        metadata = {
          name = "attic-cnpg-user";
          namespace = "app-attic";
        };
        stringData = {
          username = "attic";
          password = config.sops.placeholder."rke2/attic/cnpg-passwd";
        };
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "attic-config";
          namespace = "app-attic";
        };
        stringData."config.toml" = ''
          listen = "[::]:80"

          allowed-hosts = [${lib.concatStringsSep ", " ([''"attic.app-attic.svc"''] ++ lib.mapAttrsToList (domain: cfg: ''"attic.${domain}"'') domains)}]
          # api-endpoint = ""

          max-nar-info-size = 52428800 # 50MiB

          [chunking]
          nar-size-threshold = 262144
          min-size = 16384
          avg-size = 65536
          max-size = 262144

          [database]
          url = "postgresql://attic:${config.sops.placeholder."rke2/attic/cnpg-passwd"}@attic-cnpg-rw.app-attic.svc/attic"

          [storage]
          type = "local"
          path = "/storage"

          [jwt.signing]
          token-rs256-secret-base64 = "${config.sops.placeholder."rke2/attic/jwt-secret"}"

          # defaults
          [compression]
          type = "zstd"

          [garbage-collection]
          interval = "12 hours"
        '';
      }
    ];
    services.rke2.manifests."attic".content = [
      {
        apiVersion = "postgresql.cnpg.io/v1";
        kind = "Cluster";
        metadata = {
          name = "attic-cnpg";
          namespace = "app-attic";
        };
        spec = {
          instances = 1; # TODO: HA

          imageCatalogRef = {
            apiGroup = "postgresql.cnpg.io";
            kind = "ClusterImageCatalog";
            name = "postgresql";
            major = 17;
          };

          bootstrap.initdb = {
            database = "attic";
            owner = "attic";
            secret.name = "attic-cnpg-user";
          };

          storage.size = "5Gi";
        };
      }

      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "attic-storage";
          namespace = "app-attic";
        };
        spec = {
          accessModes = ["ReadWriteOnce"];
          resources.requests.storage = "1Ti"; #c4ch3 th3 w0r1d
        };
      }

      {
        apiVersion = "apps/v1";
        kind = "StatefulSet";
        metadata = {
          name = "attic";
          namespace = "app-attic";
        };
        spec = {
          selector.matchLabels.app = "attic";
          template.metadata.labels.app = "attic";
          serviceName = "attic";

          template.spec.securityContext = {
            runAsNonRoot = true;
            seccompProfile.type = "RuntimeDefault";
            runAsUser = 65534;
            runAsGroup = 65534;
            fsGroup = 65534;
          };

          template.spec.containers = [
            {
              name = "attic";
              image = images.attic.imageString;
              args = ["-f" "/config/config.toml"]; # why is this not -c
              volumeMounts = [
                {
                  name = "attic-storage";
                  mountPath = "/storage";
                }
                {
                  name = "attic-config";
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
              name = "attic-config";
              secret.secretName = "attic-config";
            }
            {
              name = "attic-storage";
              persistentVolumeClaim.claimName = "attic-storage";
            }
          ];
        };
      }

      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "attic";
          namespace = "app-attic";
        };
        spec = {
          selector.app = "attic";
          ipFamilyPolicy = "PreferDualStack";
          ipFamilies = ["IPv4" "IPv6"];
          ports = [
            {
              name = "attic";
              port = 80;
              protocol = "TCP";
            }
          ];
        };
      }
    ];

    az.cluster.core.envoyGateway.httpRoutes = [
      {
        name = "attic";
        namespace = "app-attic";
        hostnames = lib.mapAttrsToList (domain: cfg: "attic.${domain}") domains;
        rules = [
          {
            backendRefs = [
              {
                name = "attic";
                port = 80;
              }
            ];
            timeouts.request = "1200s";
            timeouts.backendRequest = "1200s";
          }
        ];
      }
    ];

    az.cluster.core.auth.authelia.rules = [
      {
        domain = lib.mapAttrsToList (domain: cfg: "attic.${domain}") domains;
        policy = "bypass";
      }
    ];

    az.server.rke2.clusterWideSecrets."rke2/attic/jwt-secret" = {};
    az.server.rke2.clusterWideSecrets."rke2/attic/cnpg-passwd" = {};
  };
}
