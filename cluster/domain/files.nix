# apparently they also have a helm chart. whoops
# TODO: maybe rewrite this to use https://github.com/sftpgo/helm-chart at some point?
{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  domains = lib.filterAttrs (_: v: v.enable) config.az.cluster.domainSpecific.files;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.domainSpecific.files = lib.mkOption {
    type = with lib.types;
      attrsOf (submodule {
        options = with azLib.opt; {
          enable = optBool false;
          storage = optStr "100Gi";
        };
      });
    default = {};
  };

  config = lib.mkIf (domains != {}) {
    az.cluster.core.cnpg.enable = true;

    az.server.rke2.namespaces =
      lib.mapAttrs' (
        domain: cfg: let
          id = builtins.replaceStrings ["."] ["-"] domain;
        in
          lib.nameValuePair "app-files-${id}" {
            networkPolicy.toNamespaces = ["envoy-gateway"]; # OIDC autodiscovery
            networkPolicy.fromNamespaces = ["envoy-gateway"];
          }
      )
      domains;

    az.server.rke2.images = {
      sftpgo = {
        imageName = "drakkan/sftpgo";
        finalImageTag = "v2.7.0";
        imageDigest = "sha256:24f68c1e6617f3999debde0478f435d375d496c46644b82d3ca154842d4f6c40";
        hash = "sha256-9UhyhdmUhSlcPuAKaj+AV0Hvqf/s2BIwVbKMxJsPSyQ="; # renovate: drakkan/sftpgo v2.7.0
      };
    };

    az.server.rke2.secrets = lib.flatten (
      lib.mapAttrsToList (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in [
        {
          apiVersion = "v1";
          kind = "Secret";
          type = "kubernetes.io/basic-auth";
          metadata = {
            name = "sftpgo-cnpg-user";
            namespace = "app-files-${id}";
          };
          stringData = {
            username = "sftpgo";
            password = config.sops.placeholder."rke2/sftpgo-${domain}/cnpg-passwd";
          };
        }
        {
          apiVersion = "v1";
          kind = "Secret";
          metadata = {
            name = "sftpgo-config";
            namespace = "app-files-${id}";
          };
          stringData."sftpgo.json" = let
            proxy_allowed = ["${config.az.cluster.net.prefix}00::/${toString config.az.cluster.net.prefixSize}"];
          in
            builtins.toJSON {
              defender.enabled = true;

              sftpd.bindings = [];
              ftpd.bindings = [];

              webdavd.bindings = [
                {
                  port = 81;
                  inherit proxy_allowed;
                  client_ip_proxy_header = "X-Forwarded-For";
                }
              ];
              httpd.bindings = [
                {
                  port = 80;
                  inherit proxy_allowed;
                  client_ip_proxy_header = "X-Forwarded-For";

                  enabled_login_methods = 3; # OIDC-only
                  enable_rest_api = false;

                  oidc = {
                    config_url = "https://auth.${domain}";
                    redirect_base_url = "https://files.${domain}";
                    client_id = config.sops.placeholder."rke2/sftpgo-${domain}/oidc-id";
                    client_secret = config.sops.placeholder."rke2/sftpgo-${domain}/oidc-secret";
                    username_field = "preferred_username";
                    scopes = ["openid" "profile" "email" "sftpgo"];

                    #role_field = "sftpgo_role";
                    # allow same user to login as both user and admin
                    # admins are imperative, default one is set on first login
                    implicit_roles = true;
                  };
                }
              ];

              data_provider = {
                driver = "postgresql";
                name = "sftpgo";
                host = "sftpgo-cnpg-rw.app-files-${id}.svc";
                username = "sftpgo";
                password = config.sops.placeholder."rke2/sftpgo-${domain}/cnpg-passwd";

                #pre_login_hook = "/scripts/autocreate-user-prelogin"; # no work :c
              };
            };
        }
      ])
      domains
    );

    services.rke2.manifests."files".content = lib.flatten (
      lib.mapAttrsToList (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in [
        {
          apiVersion = "v1";
          kind = "PersistentVolumeClaim";
          metadata = {
            name = "files";
            namespace = "app-files-${id}";
          };
          spec = {
            accessModes = ["ReadWriteOnce"];
            resources.requests.storage = cfg.storage;
          };
        }

        {
          apiVersion = "postgresql.cnpg.io/v1";
          kind = "Cluster";
          metadata = {
            name = "sftpgo-cnpg";
            namespace = "app-files-${id}";
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
              database = "sftpgo";
              owner = "sftpgo";
              secret.name = "sftpgo-cnpg-user";
            };

            storage.size = "100Gi";
          };
        }

        {
          apiVersion = "v1";
          kind = "ConfigMap";
          metadata = {
            name = "sftpgo-scripts";
            namespace = "app-files-${id}";
          };
          # https://github.com/drakkan/sftpgo/discussions/1685#discussioncomment-14100255
          data."autocreate-user-prelogin" = ''
            #!/bin/sh
            # Create a user on OIDC login if it doesn't exist.
            #
            # https://docs.sftpgo.com/2.6/dynamic-user-mod/

            # Extract fields from user JSON.
            USER_ID=$(echo "$SFTPGO_LOGIND_USER" | jq -r '.id')
            USERNAME=$(echo "$SFTPGO_LOGIND_USER" | jq -r '.username')

            # Only proceed if the user doesn't exist.
            [ "$USER_ID" != 0 ] && exit

            # Only proceed if login method is OIDC.
            [ "$SFTPGO_LOGIND_METHOD" != "IDP" ] && exit
            [ "$SFTPGO_LOGIND_PROTOCOL" != "OIDC" ] && exit

            # Write the user to stdout to create the user.
            # https://github.com/drakkan/sftpgo/blob/2.6.x/openapi/openapi.yaml#L5847
            cat <<EOF
            {
            	"status": 1,
            	"username": "$USERNAME",
            	"has_password": false,
            	"permissions": {
            		"/": ["*"]
            	}
            }
            EOF
          '';
        }

        {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            name = "sftpgo-${id}";
            namespace = "app-files-${id}";
          };
          spec = {
            selector.matchLabels.app = "sftpgo-${id}";
            template.metadata.labels.app = "sftpgo-${id}";

            template.spec.securityContext = {
              runAsNonRoot = true;
              seccompProfile.type = "RuntimeDefault";
              runAsUser = 65534;
              runAsGroup = 65534;
              fsGroup = 65534;
            };

            template.spec.containers = [
              {
                name = "sftpgo";
                image = images.sftpgo.imageString;
                volumeMounts = [
                  {
                    name = "files";
                    mountPath = "/srv";
                  }
                  {
                    name = "sftpgo-config";
                    mountPath = "/var/lib/sftpgo";
                  }
                  {
                    name = "sftpgo-scripts";
                    mountPath = "/scripts";
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
                name = "files";
                persistentVolumeClaim.claimName = "files";
              }
              {
                name = "sftpgo-config";
                secret.secretName = "sftpgo-config";
              }
              {
                name = "sftpgo-scripts";
                configMap = {
                  name = "sftpgo-scripts";
                  defaultMode = 493; # 0755 octal
                };
              }
            ];
          };
        }

        {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            name = "sftpgo-${id}";
            namespace = "app-files-${id}";
          };
          spec = {
            selector.app = "sftpgo-${id}";
            ipFamilyPolicy = "SingleStack";
            ipFamilies = ["IPv6"];
            ports = [
              {
                name = "http";
                port = 80;
                protocol = "TCP";
              }
              {
                name = "webdav";
                port = 81;
                protocol = "TCP";
              }
            ];
          };
        }
      ])
      domains
    );

    az.cluster.core.envoyGateway.httpRoutes = lib.flatten (
      lib.mapAttrsToList (
        domain: cfg: let
          id = builtins.replaceStrings ["."] ["-"] domain;
        in [
          {
            name = "sftpgo-${id}-http";
            namespace = "app-files-${id}";
            hostnames = ["files.${domain}"];
            rules = [
              {
                backendRefs = [
                  {
                    name = "sftpgo-${id}";
                    port = 80;
                  }
                ];
              }
            ];
            csp = "lax";
          }
          {
            name = "sftpgo-${id}-dav";
            namespace = "app-files-${id}";
            hostnames = ["webdav.${domain}"];
            rules = [
              {
                backendRefs = [
                  {
                    name = "sftpgo-${id}";
                    port = 81;
                  }
                ];
              }
            ];
            csp = "strict";
          }
        ]
      )
      domains
    );

    az.cluster.core.auth.authelia.rules = [
      {
        domain = lib.mapAttrsToList (domain: cfg: "files.${domain}") domains;
        subject = "group:admin";
        policy = "two_factor";
      }
      {
        domain = lib.mapAttrsToList (domain: cfg: "webdav.${domain}") domains;
        policy = "bypass";
      }
    ];

    /*
    # replaced with implicit_roles
    az.cluster.core.auth.authelia.userAttributes."sftpgo_role".expression = "\"admin\" in groups ? \"admin\" : \"user\"";
    */
    az.cluster.core.auth.authelia.oidcClaims."sftpgo" = {
      id_token = [
        "preferred_username"
        /*
        "sftpgo_role"
        */
      ];
      #custom_claims."sftpgo_role" = {};
    };
    #az.cluster.core.auth.authelia.oidcScopes."sftpgo".claims = ["sftpgo_role"];

    az.cluster.core.auth.authelia.oidcClientSecrets =
      lib.mapAttrs' (domain: cfg: let
        id = builtins.replaceStrings ["."] ["-"] domain;
      in {
        name = "sftpgo-${id}";
        value = "rke2/sftpgo-${domain}/oidc-secret-digest";
      })
      domains;

    az.cluster.core.auth.authelia.oidcClients = lib.mapAttrs' (domain: cfg: let
      id = builtins.replaceStrings ["."] ["-"] domain;
    in
      lib.nameValuePair "sftpgo-${id}" {
        client_id = config.sops.placeholder."rke2/sftpgo-${domain}/oidc-id";

        redirect_uris = [
          "https://files.${domain}/web/oidc/redirect"
          "https://files.${domain}/web/oauth2/redirect"
        ];
        scopes = ["openid" "email" "profile" "sftpgo"];
        claims_policy = "sftpgo";

        require_pkce = false;
        pkce_challenge_method = "";
        response_types = ["code"];
        grant_types = ["authorization_code"];
        access_token_signed_response_alg = "none";
        userinfo_signed_response_alg = "none";
        token_endpoint_auth_method = "client_secret_basic";
      })
    domains;

    az.server.rke2.clusterWideSecrets =
      lib.concatMapAttrs (domain: cfg: {
        "rke2/sftpgo-${domain}/oidc-id" = {};
        "rke2/sftpgo-${domain}/oidc-secret" = {};
        "rke2/sftpgo-${domain}/oidc-secret-digest" = {};
        "rke2/sftpgo-${domain}/cnpg-passwd" = {};
      })
      domains;
  };
}
