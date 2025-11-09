{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (config.az.cluster) net;

  cfg = config.az.cluster.core.envoyGateway;
  images = config.az.server.rke2.images;
in {
  options.az.cluster.core.envoyGateway = with azLib.opt; {
    enable = optBool false;

    infraSourceAvailableAt = optStr "https://git.azey.net/infra";

    address = optStr "${net.prefix}${net.static}::1";

    listeners = mkOption {
      type = with types; listOf attrs;
      default = [];
    };

    httpRoutes = mkOption {
      type = with types;
        listOf (submodule {
          options = {
            name = mkOption {type = types.str;};
            namespace = mkOption {type = types.str;};

            rules = mkOption {type = listOf attrs;};
            hostnames = mkOption {
              type = with types; listOf str;
              default = [];
            };
            gatewaySection = optStr "https";

            csp = optStr "lax";
            customCSP = mkOption {
              type = with types; attrsOf (listOf str);
              default = {};
            };
            permissionPolicies = mkOption {
              type = with types; attrsOf (listOf str);
              default = {};
            };
            responseHeaders = mkOption {
              type = with types; attrsOf (nullOr str);
              default = {};
            };
          };
        });
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    /*
    az.server.rke2.remoteManifests."gateway-api-latest" = {
      url = "https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/experimental-install.yaml";
      hash = "sha256-Pnon5EVv89aGBqaoUWMGqv81TW8JULMrsxkwZpt7+Lg="; # v1.3.0
    };
    */

    az.server.rke2.namespaces."envoy-gateway" = {
      networkPolicy.fromCIDR = ["::/0"];
      networkPolicy.toCluster = true;
    };

    az.server.rke2.images = {
      envoy-proxy = {
        imageName = "docker.io/envoyproxy/envoy";
        finalImageTag = "distroless-v1.36.2"; # versioning: regex:^distroless-v(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)$
        imageDigest = "sha256:322a7ea9c30080873a2f7d41f43d0b7a392455a92fe3d2a3db9a760c839f547f";
        hash = "sha256-NYhs5lMBHcxr2dAo6JixgLfQUhi++66kbYg0QwPeagk="; # renovate: docker.io/envoyproxy/envoy distroless-v1.36.2
      };
    };

    services.rke2.autoDeployCharts."envoy-gateway" = {
      repo = "oci://docker.io/envoyproxy/gateway-helm";
      version = "1.5.4";
      hash = "sha256-6NuKBKPDUiBCUAnbagSIWOQcN/2WviLbpnmBa0TenGw="; # renovate: docker.io/envoyproxy/gateway-helm 1.5.4

      targetNamespace = "envoy-gateway";
      extraDeploy =
        [
          {
            apiVersion = "gateway.networking.k8s.io/v1";
            kind = "GatewayClass";
            metadata = {
              name = "envoy-gateway";
              namespace = "envoy-gateway";
            };
            spec.controllerName = "gateway.envoyproxy.io/gatewayclass-controller";
          }

          # envoy proxy conf
          {
            apiVersion = "gateway.envoyproxy.io/v1alpha1";
            kind = "EnvoyProxy";
            metadata = {
              name = "envoy-proxy-config";
              namespace = "envoy-gateway";
            };
            spec = {
              ipFamily = "IPv6";
              telemetry.accessLog.disable = true;
              provider = {
                type = "Kubernetes";
                kubernetes.envoyDeployment.container.image = "${images.envoy-proxy.imageName}:${images.envoy-proxy.finalImageTag}";
              };
            };
          }

          # TLS config & conn limit
          {
            apiVersion = "gateway.envoyproxy.io/v1alpha1";
            kind = "ClientTrafficPolicy";
            metadata = {
              name = "envoy-gateway-traffic-policy";
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

              # TODO: http3 doesn't seem to work for some reason
              # [source/common/quic/envoy_quic_proof_source.cc:81] No certificate is configured in transport socket config.
              #http3 = {};

              tls = {
                minVersion = "1.3";
                ecdhCurves = ["X25519"];
                session.resumption.stateless = {};
              };

              connection.connectionLimit.value = 33000;
            };
          }

          # HTTP -> HTTPS redirect
          {
            apiVersion = "gateway.networking.k8s.io/v1";
            kind = "HTTPRoute";
            metadata = {
              name = "http-redirect";
              namespace = "envoy-gateway";
            };
            spec = {
              parentRefs = [
                {
                  name = "envoy-gateway";
                  namespace = "envoy-gateway";
                  sectionName = "http";
                }
              ];
              rules = [
                {
                  filters = [
                    {
                      type = "RequestRedirect";
                      requestRedirect = {
                        scheme = "https";
                        statusCode = 301;
                      };
                    }
                  ];
                }
              ];
            };
          }

          # Gateway CR
          {
            apiVersion = "gateway.networking.k8s.io/v1";
            kind = "Gateway";
            metadata = {
              name = "envoy-gateway";
              namespace = "envoy-gateway";
            };
            spec = {
              gatewayClassName = "envoy-gateway";
              listeners = cfg.listeners;
              infrastructure.parametersRef = {
                group = "gateway.envoyproxy.io";
                kind = "EnvoyProxy";
                name = "envoy-proxy-config";
              };
              addresses = [
                {
                  type = "IPAddress";
                  value = cfg.address;
                }
              ];
            };
          }
        ]
        ++ lib.flatten (lib.mapAttrsToList (domain: svc: let
            id = builtins.replaceStrings ["."] ["-"] domain;
          in (
            # 404 redirect to root
            lib.singleton {
              apiVersion = "gateway.networking.k8s.io/v1";
              kind = "HTTPRoute";
              metadata = {
                name = "https-default-redirect";
                namespace = "envoy-gateway";
              };
              spec = {
                parentRefs = [
                  {
                    name = "envoy-gateway";
                    namespace = "envoy-gateway";
                    sectionName = "https";
                  }
                ];
                hostnames = ["*.${domain}"];
                rules = [
                  {
                    filters = [
                      {
                        type = "RequestRedirect";
                        requestRedirect = {
                          hostname = domain;
                          path = {
                            type = "ReplaceFullPath";
                            replaceFullPath = "/";
                          };
                          statusCode = 302;
                        };
                      }
                    ];
                  }
                ];
              };
            }
            # wildcard cert
            ++ lib.optional (svc.certManager.enable) {
              apiVersion = "cert-manager.io/v1";
              kind = "Certificate";
              metadata = {
                name = "wildcard-${id}";
                namespace = "envoy-gateway";
              };
              spec = {
                secretName = "wildcard-tlscert-${id}";

                privateKey = {
                  algorithm = "ECDSA";
                  size = 384;
                };
                signatureAlgorithm = "ECDSAWithSHA384";
                usages = ["server auth"];

                dnsNames = [
                  "${domain}"
                  "*.${domain}"
                ];

                issuerRef = {
                  kind = "ClusterIssuer";
                  name = "letsencrypt-issuer";
                };
              };
            }
          ))
          config.az.cluster.domains);
    };

    # default value of listeners
    az.cluster.core.envoyGateway.listeners = [
      {
        name = "http";
        protocol = "HTTP";
        port = 80;
        allowedRoutes.namespaces.from = "Same";
      }
      {
        name = "https";
        protocol = "HTTPS";
        port = 443;
        allowedRoutes.namespaces.from = "All";
        tls = {
          mode = "Terminate";
          certificateRefs =
            lib.mapAttrsToList (domain: _: {
              kind = "Secret";
              name = "wildcard-tlscert-${builtins.replaceStrings ["."] ["-"] domain}";
            })
            config.az.cluster.domains;
        };
      }
    ];

    # cfg.httpRoutes impl
    services.rke2.manifests."envoy-gateway-routes".content =
      builtins.map (route: {
        apiVersion = "gateway.networking.k8s.io/v1";
        kind = "HTTPRoute";
        metadata = {
          name = route.name;
          namespace = route.namespace;
        };
        spec = {
          parentRefs = [
            {
              name = "envoy-gateway";
              namespace = "envoy-gateway";
              sectionName = route.gatewaySection;
            }
          ];
          hostnames = route.hostnames;
          rules =
            map (
              prev:
                prev
                // {
                  filters = [
                    {
                      type = "ResponseHeaderModifier";
                      responseHeaderModifier.set =
                        (builtins.filter (r: r.value != null)
                          (lib.mapAttrsToList (name: value: {
                              inherit name value;
                            })
                            (
                              {
                                cat = "~(=^.^=)"; # essential for (emotional) security
                                contact = config.az.cluster.contactMail;
                                x-powered-by = "NixOS; RKE2; hopes and dreams (and estrogen)";
                                source-code = cfg.infraSourceAvailableAt;

                                # security
                                strict-transport-security = "max-age=63072000; includeSubdomains; preload";
                                access-control-allow-origin = "*"; # TODO: https://gateway.envoyproxy.io/docs/tasks/security/cors/
                                x-content-type-options = "nosniff";
                                x-xss-protection = "1; mode=block";
                                x-frame-options = "SAMEORIGIN";
                                referrer-policy = "same-origin";
                                cross-origin-opener-policy = "same-origin";
                                cross-origin-embedder-policy = "require-corp";
                                cross-origin-resource-policy = "same-site";

                                # misc
                                x-robots-tag = "none"; # TODO?: https://gateway.envoyproxy.io/docs/tasks/traffic/direct-response/ global location
                              }
                              // route.responseHeaders
                            )))
                        ++ [
                          {
                            name = "content-security-policy";
                            value =
                              "upgrade-insecure-requests; "
                              + (
                                lib.concatStringsSep "; " (
                                  lib.mapAttrsToList (n: v: "${n} " + (lib.concatStringsSep " " v))
                                  (
                                    ({
                                      lax = {
                                        default-src = ["'self'" "data:" "blob:"];
                                        script-src = ["'self'" "'unsafe-inline'" "'unsafe-eval'"];
                                        style-src = ["'self'" "'unsafe-inline'"];
                                        frame-ancestors = ["'self'"];
                                      };
                                      strict = {
                                        default-src = ["'none'"];
                                        manifest-src = ["'self'"];
                                        script-src = ["'self'"];
                                        style-src = ["'self'"];
                                        form-action = ["'self'"];
                                        font-src = ["'self'"];
                                        frame-ancestors = ["'self'"];
                                        base-uri = ["'self'"];
                                        connect-src = ["'self'"];
                                        img-src = ["'self'" "data:" "blob:"];
                                        media-src = ["'self'"];
                                      };
                                    }."${route.csp}")
                                    // route.customCSP
                                  )
                                )
                              )
                              + ";";
                          }
                          {
                            name = "permissions-policy"; # FIXME: envoy or gateway API doesn't handle headers with commas properly, and only sends stuff after the last comma
                            value = lib.concatStringsSep ", " (lib.mapAttrsToList (policyName: policy: "${policyName}=(${lib.concatStringsSep " " policy})") (
                              {
                                accelerometer = [];
                                ambient-light-sensor = [];
                                autoplay = ["self"];
                                battery = [];
                                camera = [];
                                cross-origin-isolated = [];
                                display-capture = [];
                                document-domain = [];
                                encrypted-media = [];
                                execution-while-not-rendered = [];
                                execution-while-out-of-viewport = [];
                                fullscreen = ["self"];
                                geolocation = [];
                                gyroscope = [];
                                keyboard-map = [];
                                magnetometer = [];
                                microphone = [];
                                midi = [];
                                navigation-override = [];
                                payment = [];
                                picture-in-picture = [];
                                publickey-credentials-get = [];
                                screen-wake-lock = [];
                                sync-xhr = [];
                                usb = [];
                                web-share = [];
                                xr-spatial-tracking = [];
                                clipboard-read = [];
                                clipboard-write = ["self"];
                                gamepad = [];
                                speaker-selection = [];
                                conversion-measurement = [];
                                focus-without-user-activation = [];
                                hid = [];
                                idle-detection = [];
                                interest-cohort = [];
                                serial = [];
                                sync-script = [];
                                trust-token-redemption = [];
                                unload = [];
                                window-placement = [];
                                vertical-scroll = [];
                              }
                              // route.permissionPolicies
                            ));
                          }
                        ];
                    }
                  ];
                }
            )
            route.rules;
        };
      })
      cfg.httpRoutes;
  };
}
