{
  config,
  lib,
  azLib,
  outputs,
  ...
} @ args:
with lib; let
  cfg = config.az.svc.rke2.nameserver;
  revDomain = azLib.reverseFQDN cfg.domain;
in {
  config = mkIf cfg.enable {
    az.server.rke2.manifests."app-nameserver" = [
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "knot";
          namespace = "app-nameserver";
        };
        spec = {
          selector.app = "knot";
          ipFamilyPolicy = "PreferDualStack";
          ipFamilies = ["IPv4" "IPv6"];
          ports = [
            {
              # DoQ, used for communication w/ secondaries
              name = "knot-doq";
              port = 853;
              protocol = "UDP";
            }
            {
              # standard DNS for cluster-internal RFC2136 ACME
              name = "knot-dns";
              port = 53;
              protocol = "UDP";
            }
          ];
        };
      }
      {
        apiVersion = "gateway.networking.k8s.io/v1alpha2";
        kind = "UDPRoute";
        metadata = {
          name = "knot-doq";
          namespace = "app-nameserver";
        };
        spec = {
          parentRefs = [
            {
              name = "envoy-gateway";
              namespace = "envoy-gateway";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "knot";
                  port = 853;
                }
              ];
            }
          ];
        };
      }
    ];

    az.svc.rke2.envoyGateway.listeners = [
      {
        name = "knot-doq";
        protocol = "UDP";
        port = 853;
        allowedRoutes.namespaces.from = "All"; # TODO: Selector
      }
    ];
  };
}
