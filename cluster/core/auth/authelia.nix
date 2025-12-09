{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  top = config.az.cluster.core.auth;
  cfg = top.authelia;
in {
  options.az.cluster.core.auth.authelia = with azLib.opt; {
    rules = lib.mkOption {
      type = with lib.types;
        listOf (submodule {
          freeformType = attrsOf anything;
          options.policy = optStr "two_factor";
        });
      default = [];
    };
    oidcClientSecrets = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = {};
    };
    oidcClients = lib.mkOption {
      type = with lib.types;
        attrsOf (submodule ({name, ...}: {
          freeformType = attrsOf anything;
          options = {
            client_name = optStr name;
            client_secret = lib.mkOption {
              type = oneOf [str attrs];
              default.path = "/secrets/authelia-oidc/${name}";
            };

            public = optBool false;
            authorization_policy = optStr "two_factor";

            consent_mode = optStr "pre-configured";
            pre_configured_consent_duration = optStr "2w";
          };
        }));
      default = {};
    };
    oidcClaims = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = {};
    };

    domains = lib.mkOption {
      type = with lib.types; listOf str;
      default = [top.domain];
    };
  };

  config = lib.mkIf top.enable {
    az.cluster.core.cnpg.enable = true;

    az.server.rke2.namespaces = {
      "app-lldap".networkPolicy.fromNamespaces = ["app-authelia"];
      "app-mail".networkPolicy.fromNamespaces = ["app-authelia"];
      "app-authelia".networkPolicy = {
        fromNamespaces = ["envoy-gateway"];
        toNamespaces = ["app-lldap" "app-mail"];
      };
    };

    services.rke2.autoDeployCharts."authelia-valkey" = {
      repo = "https://valkey.io/valkey-helm";
      name = "valkey";
      version = "0.7.7";
      hash = "sha256-u16EI5qM8Y2AzvQK0BeWEjbN9m4Ohko6NlsPGFs3J7E="; # renovate: https://valkey.io/valkey-helm valkey 0.7.7

      targetNamespace = "app-authelia";
      values = {
        podSecurityContext.seccompProfile.type = "RuntimeDefault";
        securityContext.allowPrivilegeEscalation = false;

        dataStorage.enabled = true;

        valkeyConfig = ''
          bind * -::*
          aclfile /users/acl
        ''; # TODO: github.com/valkey-io/valkey-helm/pull/68

        # https://github.com/valkey-io/valkey-helm/issues/20#issuecomment-3380630048
        auth.enabled = false;
        extraValkeySecrets = [
          {
            name = "authelia-valkey-users";
            mountPath = "/users";
          }
        ];
      };
    };
    services.rke2.autoDeployCharts."authelia" = {
      repo = "https://charts.authelia.com";
      name = "authelia";
      version = "0.10.46";
      hash = "sha256-ktKqQLAjMc4BkEVYU1+5r+RZhk9NkUrKzQigdhq/JrY="; # renovate: https://charts.authelia.com authelia 0.10.46

      targetNamespace = "app-authelia";
      # values defined in HelmChartConfig due to sops values in oidcClients

      extraDeploy = [
        {
          apiVersion = "postgresql.cnpg.io/v1";
          kind = "Cluster";
          metadata = {
            name = "authelia-cnpg";
            namespace = "app-authelia";
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
              database = "authelia";
              owner = "authelia";
              secret.name = "authelia-cnpg-user";
            };

            storage.size = "1Gi"; # really shouldn't need more than this
          };
        }

        # https://www.authelia.com/integration/proxies/envoy/#secure-gateway
        {
          apiVersion = "gateway.envoyproxy.io/v1alpha1";
          kind = "SecurityPolicy";
          metadata = {
            name = "authelia-extauth";
            namespace = "envoy-gateway";
          };
          spec = {
            targetRefs = [
              {
                group = "gateway.networking.k8s.io";
                kind = "Gateway";
                name = "envoy-gateway";
                sectionName = "https";
              }
            ];
            extAuth = {
              http = {
                path = "/api/authz/ext-authz/";
                backendRefs = [
                  {
                    group = "";
                    kind = "Service";
                    name = "authelia";
                    namespace = "app-authelia";
                    port = 80;
                  }
                ];
              };
              failOpen = false;
              headersToExtAuth = [
                "X-Forwarded-Proto"
                "Authorization"
                "Proxy-Authorization"
                "Accept"
                "Cookie"
              ];
            };
          };
        }
        {
          apiVersion = "gateway.networking.k8s.io/v1beta1";
          kind = "ReferenceGrant";
          metadata = {
            name = "envoy-extauth";
            namespace = "app-authelia";
          };
          spec = {
            from = [
              {
                group = "gateway.envoyproxy.io";
                kind = "SecurityPolicy";
                namespace = "envoy-gateway";
              }
            ];
            to = [
              {
                group = "";
                kind = "Service";
              }
            ];
          };
        }
      ];
    };
    az.server.rke2.secrets = [
      {
        apiVersion = "v1";
        kind = "Secret";
        type = "kubernetes.io/basic-auth";
        metadata = {
          name = "authelia-cnpg-user";
          namespace = "app-authelia";
        };
        stringData = {
          username = "authelia";
          password = config.sops.placeholder."rke2/authelia/cnpg-passwd";
        };
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "authelia-valkey-users";
          namespace = "app-authelia";
        };
        stringData."acl" = ''
          user authelia on >${config.sops.placeholder."rke2/authelia/valkey-passwd"} ~*  &* +@all
        '';
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "authelia-oidc";
          namespace = "app-authelia";
        };
        stringData = lib.mapAttrs (_: secret: config.sops.placeholder.${secret}) cfg.oidcClientSecrets;
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "authelia-misc";
          namespace = "app-authelia";
        };
        data = {
          hmac-secret = config.sops.placeholder."rke2/authelia/hmac-secret"; # binary data
          jwk-key = config.sops.placeholder."rke2/authelia/jwk-key"; # yaml whitespace reasons
        };
        stringData = {
          lldap-passwd = config.sops.placeholder."rke2/authelia/lldap-passwd";
          cnpg-passwd = config.sops.placeholder."rke2/authelia/cnpg-passwd";
          valkey-passwd = config.sops.placeholder."rke2/authelia/valkey-passwd";
          storage-encryption-key = config.sops.placeholder."rke2/authelia/storage-encryption-key";
        };
      }
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChartConfig";
        metadata = {
          name = "authelia";
          namespace = "kube-system";
        };
        spec.valuesContent = builtins.toJSON {
          pod.securityContext = {
            container = {
              runAsNonRoot = true;
              runAsUser = 65534;
              runAsGroup = 65534;
              seccompProfile.type = "RuntimeDefault";
              capabilities.drop = ["ALL"];
              allowPrivilegeEscalation = false;
            };
            pod.fsGroup = 65534;
          };
          configMap = {
            theme = "dark";
            default_2fa_method = "totp";

            totp = {
              issuer = top.domain;
              algorithm = "sha512";
              digits = 8;
              secret_size = 128;
            };

            webauthn.display_name = top.domain;
            authentication_backend = {
              password_reset.disable = true;
              password_change.disable = true;

              ldap = let
                split = lib.splitString "." top.domain;
                base_dn = lib.concatMapStringsSep "," (n: "dc=${n}") split;
              in {
                enabled = true;
                implementation = "lldap";
                address = "ldap://lldap.app-lldap.svc";

                inherit base_dn;
                user = "uid=authelia,ou=people,${base_dn}";
                password = {
                  secret_name = "authelia-misc";
                  path = "lldap-passwd";
                };
              };
            };

            identity_providers.oidc = {
              enabled = cfg.oidcClients != {};

              hmac_secret = {
                secret_name = "authelia-misc";
                path = "hmac-secret";
              };
              jwks = [
                {
                  key.path = "/secrets/authelia-misc/jwk-key";
                  #certificate_chain = ""; # TODO?
                }
              ];

              #TODO?: authorization_policies = {};
              clients = cfg.oidcClients;
              claims_policies = cfg.oidcClaims;
            };

            server.endpoints.authz.ext-authz.implementation = "ExtAuthz";

            session = {
              expiration = "1h";
              inactivity = "5m";
              remember_me = "1M";

              cookies =
                builtins.map (domain: {
                  domain = domain;
                  subdomain = "auth";
                  default_redirection_url = "https://${domain}";
                })
                cfg.domains;

              redis = {
                enabled = true;
                deploy = false;
                host = "authelia-valkey.app-authelia.svc";
                username = "authelia";
                password = {
                  secret_name = "authelia-misc";
                  path = "valkey-passwd";
                };
              };
            };

            regulation = {
              max_retries = 5;
              find_time = "5m";
              ban_time = "5m";
            };
            password_policy.zxcvbn = {
              enabled = true;
              min_score = 4;
            };

            storage.encryption_key = {
              secret_name = "authelia-misc";
              path = "storage-encryption-key";
            };
            storage.postgres = {
              enabled = true;
              address = "tcp://authelia-cnpg-rw.app-authelia.svc:5432";
              password = {
                secret_name = "authelia-misc";
                path = "cnpg-passwd";
              };
            };

            /*
            notifier.filesystem = {
              enabled = true;
              filename = "/tmp/notifier"; # TODO mail
            };
            */
            notifier.smtp = {
              enabled = true;

              sender = "authelia <noreply@${top.domain}>";
              identifier = "app-authelia-${top.domain}";
              startup_check_address = "test@${top.domain}";

              address = "submission://mail.app-mail.svc";
              tls.skip_verify = true;
              username = null;
              password.disabled = true;
            };

            access_control = {
              default_policy = "deny";
              rules =
                [
                  {
                    domain = ["auth.${top.domain}"];
                    policy = "bypass";
                  }
                ]
                ++ cfg.rules;
            };
          };

          secret.additionalSecrets = {
            authelia-oidc = {};
            authelia-misc = {};
          };
        };
      }
    ];

    az.cluster.core.envoyGateway.httpRoutes = [
      {
        name = "authelia";
        namespace = "app-authelia";
        hostnames = ["auth.${top.domain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "authelia";
                port = 80;
              }
            ];
          }
        ];
      }
    ];

    az.server.rke2.clusterWideSecrets."rke2/authelia/hmac-secret" = {};
    az.server.rke2.clusterWideSecrets."rke2/authelia/jwk-key" = {};
    az.server.rke2.clusterWideSecrets."rke2/authelia/storage-encryption-key" = {};
    az.server.rke2.clusterWideSecrets."rke2/authelia/lldap-passwd" = {};
    az.server.rke2.clusterWideSecrets."rke2/authelia/cnpg-passwd" = {};
    az.server.rke2.clusterWideSecrets."rke2/authelia/valkey-passwd" = {};
  };
}
