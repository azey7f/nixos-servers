{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  top = config.az.server.rke2;
  cfg = top.bgp;
in {
  options.az.server.rke2.bgp = with azLib.opt; {
    enable = optBool false;
    router = optStr "::1";
    peerASN = mkOption {
      type = types.ints.unsigned;
      default = 64512;
    };
    selfASN = mkOption {
      type = types.ints.unsigned;
      default = 64513;
    };
  };

  config = mkIf cfg.enable (lib.mkMerge [
    (mkIf (cfg.router == "::1") {
      az.server.net.frr.enable = true;
      az.server.net.frr.ospf.redistribute = ["bgp"];
      az.server.net.frr.extraConfig = let
        # very janky & assumes a lot of stuff, but ::1 BGP is a huge hack anyways...
        # here's hoping I'll be able to drop this whole mkIf soon
        peerAddr = "${config.az.cluster.net.prefix}${config.az.cluster.net.nodes}::${toString config.az.cluster.meta.nodes.${config.networking.hostName}.id}";
      in ''
        allow-reserved-ranges
        access-list all permit any
        route-map set-nexthop permit 10
        	match ipv6 address all
        	set ipv6 next-hop prefer-global
        	set ipv6 next-hop global ${peerAddr}
        !
        router bgp ${toString cfg.peerASN}
        	bgp allow-martian-nexthop
        	no bgp ebgp-requires-policy
        	no bgp network import-check
        	bgp router-id 0.0.0.1
        	neighbor ::1 remote-as ${toString cfg.selfASN}
        	neighbor ::1 route-map set-nexthop in
        	address-family ipv6 unicast
        		neighbor ::1 activate
        		neighbor ::1 soft-reconfiguration inbound
        	exit-address-family
        !
      '';
      services.frr.bgpd.enable = true;
    })
    {
      services.rke2.manifests."cilium-bgp".content = [
        {
          apiVersion = "cilium.io/v2alpha1";
          kind = "CiliumBGPClusterConfig";
          metadata = {
            name = "local";
            namespace = "kube-system";
          };
          spec.bgpInstances = [
            {
              name = "instance-${toString cfg.selfASN}";
              localASN = cfg.selfASN;
              peers = [
                {
                  name = "peer-${toString cfg.peerASN}";
                  peerASN = cfg.peerASN;
                  peerAddress = cfg.router;
                  peerConfigRef.name = "cilium-peer";
                }
              ];
            }
          ];
        }
        {
          apiVersion = "cilium.io/v2alpha1";
          kind = "CiliumBGPNodeConfigOverride";
          metadata = {
            name = config.networking.fqdn;
            namespace = "kube-system";
          };
          spec.bgpInstances = [
            {
              name = "instance-${toString cfg.selfASN}";
              routerID = "0.0.0.2";
            }
          ];
        }
        {
          apiVersion = "cilium.io/v2alpha1";
          kind = "CiliumBGPPeerConfig";
          metadata = {
            name = "cilium-peer";
            namespace = "kube-system";
          };
          spec = {
            timers = {
              holdTimeSeconds = 9;
              keepAliveTimeSeconds = 3;
            };
            gracefulRestart = {
              enabled = true;
              restartTimeSeconds = 15;
            };
            families = [
              {
                afi = "ipv6";
                safi = "unicast";
                advertisements.matchLabels.advertise = "bgp";
              }
            ];
          };
        }
        {
          apiVersion = "cilium.io/v2alpha1";
          kind = "CiliumBGPAdvertisement";
          metadata = {
            name = "bgp-advertisements";
            labels.advertise = "bgp";
          };
          spec.advertisements = [
            {
              advertisementType = "Service";
              service.addresses = ["ExternalIP"];
              selector.matchExpressions = [
                {
                  key = "dummy";
                  operator = "NotIn";
                  values = ["never-used-value"];
                }
              ];
              attributes.communities.standard = ["${toString cfg.selfASN}:99"];
            }
          ];
        }
      ];
    }
  ]);
}
