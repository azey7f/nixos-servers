# TODO: OIDC
{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.authelia;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.authelia = with azLib.opt; {
    enable = optBool false;
    rules = mkOption {
      type = with types;
        listOf (submodule (value: {
          freeformType = with types; attrsOf anything;
          options.policy = optStr "two_factor";
        }));
      default = [];
    };
  };

  config = mkIf cfg.enable {
    az.svc.rke2.cnpg.enable = true;
    az.server.rke2.manifests."app-authelia" = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "app-authelia";
        metadata.labels.name = "app-authelia";
      }
      {
        apiVersion = "postgresql.cnpg.io/v1";
        kind = "Cluster";
        metadata = {
          name = "authelia-cnpg";
          namespace = "app-authelia";
        };
        spec = {
          instances = 1; # TODO: HA

          bootstrap.initdb = {
            database = "authelia";
            owner = "authelia";
            secret.name = "authelia-cnpg-user";
          };

          storage.size = "1Gi"; # really shouldn't need more than this
        };
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        type = "kubernetes.io/basic-auth";
        metadata = {
          name = "authelia-cnpg-user";
          namespace = "app-authelia";
        };
        data = {
          username = "YXV0aGVsaWE="; # echo -n authelia | base64
          password = config.sops.placeholder."rke2/authelia/cnpg-passwd";
        };
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "authelia-misc";
          namespace = "app-authelia";
        };
        data = {
          lldap-passwd = config.sops.placeholder."rke2/authelia/lldap-passwd";
          cnpg-passwd = config.sops.placeholder."rke2/authelia/cnpg-passwd";
        };
      }
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "authelia";
          namespace = "kube-system";
        };
        spec = {
          targetNamespace = "app-authelia";

          chart = "authelia";
          repo = "https://charts.authelia.com";

          valuesContent = builtins.toJSON {
            pod.securityContext = {
              container = {
                runAsNonRoot = true;
                runAsUser = 65532;
                runAsGroup = 65532;
                seccompProfile.type = "RuntimeDefault";
                capabilities.drop = ["ALL"];
                allowPrivilegeEscalation = false;
              };
              pod.fsGroup = 65532;
            };
            configMap = {
              theme = "dark";
              default_2fa_method = "totp";

              totp = {
                issuer = domain;
                algorithm = "sha512";
                digits = 8;
                secret_size = 128;
              };

              webauthn.display_name = domain;
              authentication_backend = {
                password_reset.disable = true;
                password_change.disable = true;

                ldap = let
                  split = lib.strings.splitString "." domain;
                  base_dn = lib.strings.concatMapStringsSep "," (n: "dc=${n}") split;
                in {
                  enabled = true;
                  implementation = "lldap";
                  address = "ldap://lldap-ldap.app-lldap.svc";

                  inherit base_dn;
                  user = "uid=authelia,ou=people,${base_dn}";
                  password = {
                    secret_name = "authelia-misc";
                    path = "lldap-passwd";
                  };
                };
              };

              server.endpoints.authz.ext-authz.implementation = "ExtAuthz";

              session = {
                expiration = "1h";
                inactivity = "5m";
                remember_me = "1M";

                cookies = [
                  {
                    inherit domain;
                    subdomain = "auth";
                    #authelia_url = "https://auth.${domain}";
                    default_redirection_url = "https://${domain}";
                  }
                ];

                /*
                redis = { # TODO
                  enabled = true;
                  deploy = true;
                };
                */
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

              storage.postgres = {
                enabled = true;
                address = "tcp://authelia-cnpg-rw.app-authelia.svc:5432";
                password = {
                  secret_name = "authelia-misc";
                  path = "cnpg-passwd";
                };
              };

              notifier.filesystem = {
                enabled = true;
                filename = "/tmp/notifier"; # TODO
              };

              access_control = {
                default_policy = "deny";
                rules = cfg.rules;
              };
            };

            secret.additionalSecrets = {
              authelia-misc = {};
            };
          };
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

    az.svc.rke2.envoyGateway.httpRoutes = [
      {
        name = "authelia";
        namespace = "app-authelia";
        hostnames = ["auth.${domain}"];
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

    az.svc.rke2.authelia.rules = [
      {
        domain = ["auth.${config.az.server.rke2.baseDomain}"];
        policy = "bypass";
      }
    ];

    sops.secrets."rke2/authelia/lldap-passwd" = {
      # cluster-wide
      sopsFile = "${config.az.server.sops.path}/${azLib.reverseFQDN config.networking.domain}/default.yaml";
    };
    sops.secrets."rke2/authelia/cnpg-passwd" = {
      sopsFile = "${config.az.server.sops.path}/${azLib.reverseFQDN config.networking.domain}/default.yaml";
    };
  };
}
