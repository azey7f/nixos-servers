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
  cfg = top.server;
  images = config.az.server.rke2.images;
in {
  options.az.server.rke2 = with azLib.opt; {
    server = {
      enable = optBool false;
      clusterInit = optBool (
        if cfg.enable
        then (config.az.cluster.meta.nodes.${config.networking.hostName}.id == 1)
        else false
      ); # init only on first node

      l2Announcements = optBool false;
    };
  };

  config = mkIf cfg.enable {
    # https://docs.rke2.io/install/requirements?cni-rules=Cilium
    networking.firewall.allowedTCPPorts = [2379 2380 2381 6443];

    environment.sessionVariables.KUBECONFIG = "/etc/rancher/rke2/rke2.yaml";

    systemd.services.rke2-server.preStart = "${pkgs.kmod}/bin/modprobe -a ip6_tables ip6table_mangle ip6table_raw ip6table_filter";
    services.rke2 =
      (lib.attrsets.optionalAttrs cfg.clusterInit {serverAddr = mkForce "";})
      // {
        role = "server";
        disable = [
          "rke2-ingress-nginx" # replaced w/ envoy gateway
          "rke2-metrics-server"
          "rke2-snapshot-controller"
          "rke2-snapshot-controller-crd"
          "rke2-snapshot-validation-webhook"
        ];
        extraFlags = let
          inherit (config.az.cluster) net;
        in
          [
            "--cluster-domain=${config.networking.domain}"
            "--cluster-cidr=${net.prefix}${net.pods}::/${toString net.subnetSize}"
            "--service-cidr=${net.prefix}${net.services}::/112" # largest supported by k3s, probably also by rke2
            "--node-ip=${builtins.elemAt config.az.server.net.interfaces.${top.primaryInterface}.ipv6.addr 0}"
            "--kube-controller-manager-arg=node-cidr-mask-size-ipv6=${toString net.subnetSize}"
            "--tls-san-security"
            "--tls-san=api.${config.networking.domain}"
            "--tls-san=${config.networking.fqdn}"
            "--embedded-registry"
          ]
          ++ lib.optionals config.az.cluster.core.metrics.enable [
            "--etcd-expose-metrics"
            "--kube-scheduler-arg=bind-address=::"
            "--kube-controller-manager-arg=bind-address=::"
          ];

        cni = "none"; # cilium deployed manually for image version pinning

        autoDeployCharts."cilium" = {
          repo = "https://helm.cilium.io";
          name = "cilium";
          version = "1.17.8";
          hash = "sha256-G4FNOw2zmprMdWztjC91v3ks4ieWFWou8bxwIF/xVUE="; # renovate: https://helm.cilium.io cilium 1.17.8

          targetNamespace = "kube-system";

          # TODO: remove operator.replicas whenever I get multiple nodes
          # renovate-args: --set authentication.mutual.spire.enabled=true --set envoy.enabled=false
          values = let
            imageOpts = {
              pullPolicy = "Never";
              useDigest = false;
            };
            inherit (config.az.cluster) net;
          in {
            envoy.enabled = false;

            extraArgs = let
              interfaces = lib.concatStringsSep "," ([top.primaryInterface] ++ top.extraInterfaces);
            in ["--devices=${interfaces}"]; # https://github.com/cilium/cilium/issues/37427

            image = imageOpts;
            operator.image = imageOpts;

            operator.replicas = 1;

            kubeProxyReplacement = true;
            k8sServiceHost = "api.${config.networking.domain}";
            k8sServicePort = 8443;

            ipv4.enabled = false; # cease
            ipv6.enabled = true;
            underlayProtocol = "ipv6";

            routingMode = "native";
            tunnelProtocol = "";

            enableIPv6Masquerade = false;
            ipv6NativeRoutingCIDR = "${net.prefix}::/${toString net.prefixSubnetSize}";
            autoDirectNodeRoutes = true;

            ipam.operator = {
              clusterPoolIPv6MaskSize = net.subnetSize + 16;
              clusterPoolIPv6PodCIDRList = ["${net.prefix}${net.pods}::/${toString net.subnetSize}"];
            };

            # TODO https://docs.cilium.io/en/stable/operations/performance/tuning/
            #bpf = {
            #datapathMode = "netkit";
            #distributedLRU.enabled = true;
            #mapDynamicSizeRatio = 0.08;
            #};
            #bpfClockProbe = true;
            # TODO loadBalancer.acceleration

            encryption = {
              enabled = true;
              nodeEncryption = true;
              type = "wireguard";
            };
            # CRITICAL TODO policyEnforcementMode = "always";

            authentication.mutual.spire = {
              # TODO?: use a cnpg DB
              enabled = true;
              install.enabled = true;
              install.existingNamespace = true;
              install.namespace = "cilium-spire";

              install.initImage = imageOpts;
              install.agent.image = imageOpts;
              install.server.image = imageOpts;
            };

            bgpControlPlane.enabled = top.bgp.enable;
            l2announcements = {
              enabled = cfg.l2Announcements;
              leaseDuration = "10s";
              leaseRenewDeadline = "5s";
              leaseRetryPeriod = "1s";
            };
          };

          extraDeploy =
            lib.lists.optional cfg.l2Announcements
            {
              apiVersion = "cilium.io/v2alpha1";
              kind = "CiliumL2AnnouncementPolicy";
              metadata.name = "default";
              spec = {
                loadBalancerIPs = false;
                externalIPs = true;
              };
            };
        };
      };

    az.server.rke2.namespaces."cilium-spire" = {
      podSecurity = "privileged";
      networkPolicy.extraEgress = [{toEntities = ["cluster"];}];
      networkPolicy.extraIngress = [{fromEntities = ["cluster"];}];
    };
  };
}
