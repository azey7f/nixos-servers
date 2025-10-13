{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.lldap;
  domain = config.az.server.rke2.baseDomain;
  images = config.az.server.rke2.images;
in {
  options.az.svc.rke2.lldap = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.svc.rke2.cnpg.enable = true;

    az.server.rke2.namespaces."app-lldap" = {
      networkPolicy.fromNamespaces = ["envoy-gateway"];
    };

    az.server.rke2.images = {
      lldap = {
        imageName = "lldap/lldap";
        finalImageTag = "2025-10-12"; # versioning: regex:^(?<major>\d+)-(?<minor>\d+)-(?<patch>\d+)$
        imageDigest = "sha256:d67b1565dc72d3c89ab8da893ca300c886be4a8ac02cb1e58c9bddd75b503847";
        hash = "sha256-BYH2m7890pjN4INnWr7v/kzumwhs9v1ccviE5LdSi3U="; # renovate: lldap/lldap 2025-10-12
      };
    };
    az.server.rke2.secrets = [
      {
        apiVersion = "v1";
        kind = "Secret";
        type = "kubernetes.io/basic-auth";
        metadata = {
          name = "lldap-cnpg-user";
          namespace = "app-lldap";
        };
        stringData = {
          username = "lldap";
          password = config.sops.placeholder."rke2/lldap/cnpg-passwd";
        };
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "lldap-env";
          namespace = "app-lldap";
        };
        stringData = let
          split = lib.strings.splitString "." domain;
        in {
          TZ = config.az.core.locale.tz;

          LLDAP_HTTP_HOST = "::";
          LLDAP_HTTP_PORT = "80";
          LLDAP_LDAP_HOST = "::";
          LLDAP_LDAP_PORT = "389";
          LLDAP_HTTP_URL = "https://lldap.${domain}";

          LLDAP_LDAP_BASE_DN = lib.strings.concatMapStringsSep "," (n: "dc=${n}") split;
          LLDAP_DATABASE_URL = "postgresql://lldap:${config.sops.placeholder."rke2/lldap/cnpg-passwd"}@lldap-cnpg-rw.app-lldap.svc/lldap";
          LLDAP_JWT_SECRET = config.sops.placeholder."rke2/lldap/jwt-secret";
          LLDAP_KEY_SEED = config.sops.placeholder."rke2/lldap/key-seed";
          LLDAP_LDAP_USER_PASS = config.sops.placeholder."rke2/lldap/init-passwd"; # should be deleted after init
        };
      }
    ];
    services.rke2.manifests."lldap".content = [
      {
        apiVersion = "postgresql.cnpg.io/v1";
        kind = "Cluster";
        metadata = {
          name = "lldap-cnpg";
          namespace = "app-lldap";
        };
        spec = {
          instances = 1; # TODO: HA

          imageCatalogRef = {
            apiGroup = "postgresql.cnpg.io";
            kind = "ClusterImageCatalog";
            name = "postgresql";
            major = 18;
          };

          bootstrap.initdb = {
            database = "lldap";
            owner = "lldap";
            secret.name = "lldap-cnpg-user";
          };

          storage.size = "1Gi";
        };
      }

      {
        apiVersion = "apps/v1";
        kind = "StatefulSet";
        metadata = {
          name = "lldap";
          namespace = "app-lldap";
        };
        spec = {
          selector.matchLabels.app = "lldap";
          template.metadata.labels.app = "lldap";
          serviceName = "lldap";

          template.spec.securityContext = {
            runAsNonRoot = true;
            seccompProfile.type = "RuntimeDefault";
            runAsUser = 65534;
            runAsGroup = 65534;
            fsGroup = 65534;
          };

          template.spec.containers = [
            {
              name = "lldap";
              image = images.lldap.imageString;
              command = ["/app/lldap" "run"];
              envFrom = [{secretRef.name = "lldap-env";}];
              securityContext = {
                allowPrivilegeEscalation = false;
                capabilities.drop = ["ALL"];
              };
            }
          ];
        };
      }

      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "lldap";
          namespace = "app-lldap";
        };
        spec = {
          selector.app = "lldap";
          ipFamilyPolicy = "PreferDualStack";
          ipFamilies = ["IPv4" "IPv6"];
          ports = [
            {
              name = "http";
              port = 80;
              protocol = "TCP";
            }
            {
              name = "ldap";
              port = 389;
              protocol = "TCP";
            }
          ];
        };
      }
    ];

    az.svc.rke2.envoyGateway.httpRoutes = [
      {
        name = "lldap";
        namespace = "app-lldap";
        hostnames = ["lldap.${domain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "lldap";
                port = 80;
              }
            ];
          }
        ];
      }
    ];

    az.svc.rke2.authelia.rules = [
      {
        domain = ["lldap.${domain}"];
        subject = "group:admin";
        policy = "two_factor";
      }
    ];

    az.server.rke2.clusterWideSecrets."rke2/lldap/init-passwd" = {};
    az.server.rke2.clusterWideSecrets."rke2/lldap/cnpg-passwd" = {};
    az.server.rke2.clusterWideSecrets."rke2/lldap/jwt-secret" = {};
    az.server.rke2.clusterWideSecrets."rke2/lldap/key-seed" = {};
  };
}
