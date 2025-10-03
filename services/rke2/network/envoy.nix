{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.envoyGateway;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.envoyGateway = with azLib.opt; {
    enable = optBool false;
    gateways = let
      gwOptions = {
        addresses = {
          ipv4 = mkOption {
            type = with types; nullOr str;
            default = null;
          };
          ipv6 = mkOption {type = types.str;};
        };

        listeners = mkOption {
          type = with types; listOf attrs;
          default = [];
        };
      };
    in {
      # external = accessible from the internet, routed, frp reverse-proxied, etc
      # internal = only accessible from LAN/via VPN
      external = gwOptions;
      internal = gwOptions;
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
            gateways = mkOption {
              type = with types; listOf str;
              default = ["external" "internal"];
            };

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

  config = mkIf cfg.enable {
    /*
    az.server.rke2.remoteManifests."gateway-api-latest" = {
      url = "https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/experimental-install.yaml";
      hash = "sha256-Pnon5EVv89aGBqaoUWMGqv81TW8JULMrsxkwZpt7+Lg="; # v1.3.0
    };
    */

    az.server.rke2.namespaces."envoy-gateway" = {
      networkPolicy.extraEgress = [{toEntities = ["cluster"];}];
      networkPolicy.extraIngress = [{fromEntities = ["all"];}];
    };

    az.server.rke2.manifests."envoy-gateway" =
      [
        {
          apiVersion = "helm.cattle.io/v1";
          kind = "HelmChart";
          metadata = {
            name = "envoy-gateway";
            namespace = "kube-system";
          };
          spec = {
            targetNamespace = "envoy-gateway";

            chart = "oci://docker.io/envoyproxy/gateway-helm";
            version = "1.5.2";
          };
        }

        {
          apiVersion = "gateway.networking.k8s.io/v1";
          kind = "GatewayClass";
          metadata = {
            name = "envoy-gateway";
            namespace = "envoy-gateway";
          };
          spec.controllerName = "gateway.envoyproxy.io/gatewayclass-controller";
        }

        # dual stack
        {
          apiVersion = "gateway.envoyproxy.io/v1alpha1";
          kind = "EnvoyProxy";
          metadata = {
            name = "envoy-proxy-config";
            namespace = "envoy-gateway";
          };
          spec.ipFamily = "DualStack";
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
            targetRefs =
              lib.attrsets.mapAttrsToList (name: _: {
                group = "gateway.networking.k8s.io";
                kind = "Gateway";
                name = "envoy-gateway-${name}";
              })
              cfg.gateways;

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

        # wildcard cert
        {
          apiVersion = "cert-manager.io/v1";
          kind = "Certificate";
          metadata = {
            name = "wildcard";
            namespace = "envoy-gateway";
          };
          spec = {
            secretName = "wildcard-tlscert";

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

        # HTTP -> HTTPS redirect
        {
          apiVersion = "gateway.networking.k8s.io/v1";
          kind = "HTTPRoute";
          metadata = {
            name = "http-redirect";
            namespace = "envoy-gateway";
          };
          spec = {
            parentRefs =
              lib.attrsets.mapAttrsToList (name: _: {
                name = "envoy-gateway-${name}";
                namespace = "envoy-gateway";
                sectionName = "http";
              })
              cfg.gateways;
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

        # 404 redirect to root
        {
          apiVersion = "gateway.networking.k8s.io/v1";
          kind = "HTTPRoute";
          metadata = {
            name = "https-default-redirect";
            namespace = "envoy-gateway";
          };
          spec = {
            parentRefs =
              lib.attrsets.mapAttrsToList (name: _: {
                name = "envoy-gateway-${name}";
                namespace = "envoy-gateway";
                sectionName = "https";
              })
              cfg.gateways;
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
      ]
      ++ lib.lists.flatten (lib.attrsets.mapAttrsToList (name: gw: [
          # Gateway objects
          {
            apiVersion = "gateway.networking.k8s.io/v1";
            kind = "Gateway";
            metadata = {
              name = "envoy-gateway-${name}";
              namespace = "envoy-gateway";
              #annotations."cert-manager.io/cluster-issuer" = "letsencrypt-issuer";
            };
            spec = {
              gatewayClassName = "envoy-gateway";
              listeners = gw.listeners;
              infrastructure.parametersRef = {
                group = "gateway.envoyproxy.io";
                kind = "EnvoyProxy";
                name = "envoy-proxy-config";
              };
              addresses =
                [
                  {
                    type = "IPAddress";
                    value = gw.addresses.ipv6;
                  }
                ]
                ++ lib.lists.optional (gw.addresses.ipv4 != null) {
                  type = "IPAddress";
                  value = gw.addresses.ipv4;
                };
            };
          }
        ])
        cfg.gateways);

    # default value of gateways.*.listeners
    az.svc.rke2.envoyGateway.gateways = let
      listeners = [
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
            certificateRefs = [
              {
                kind = "Secret";
                name = "wildcard-tlscert";
              }
            ];
          };
        }
      ];
    in {
      external = {inherit listeners;};
      internal = {inherit listeners;};
    };

    # cfg.httpRoutes impl
    az.server.rke2.manifests."envoy-gateway-routes" =
      builtins.map (route: {
        apiVersion = "gateway.networking.k8s.io/v1";
        kind = "HTTPRoute";
        metadata = {
          name = route.name;
          namespace = route.namespace;
        };
        spec = {
          parentRefs =
            lib.lists.map (name: {
              name = "envoy-gateway-${name}";
              namespace = "envoy-gateway";
              sectionName = route.gatewaySection;
            })
            route.gateways;
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
                          (lib.attrsets.mapAttrsToList (name: value: {
                              inherit name value;
                            })
                            (
                              {
                                cat = "~(=^.^=)"; # essential for (emotional) security
                                contact = "me@${domain}";
                                x-powered-by = "NixOS; RKE2; hopes and dreams (and estrogen)";
                                source-code = "https://git.${domain}/infra";

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
                                x-robots-tag = "none"; # TODO: https://gateway.envoyproxy.io/docs/tasks/traffic/direct-response/ global location
                              }
                              // route.responseHeaders
                            )))
                        ++ [
                          {
                            name = "content-security-policy";
                            value =
                              "upgrade-insecure-requests; "
                              + (
                                lib.strings.concatStringsSep "; " (
                                  lib.attrsets.mapAttrsToList (n: v: "${n} " + (lib.strings.concatStringsSep " " v))
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
                            value = strings.concatStringsSep ", " (attrsets.mapAttrsToList (policyName: policy: "${policyName}=(${strings.concatStringsSep " " policy})") (
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
