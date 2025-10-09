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
  cluster = outputs.infra.clusters.${server.networking.domain};
in {
  options.az.server.rke2 = with azLib.opt; {
    server = {
      enable = optBool false;
      clusterInit = optBool (config.az.server.id == 0); # init only on first node
    };

    loadBalancing = {
      cidrs = mkOption {
        type = with types; nullOr (listOf str);
        default = null;
      };
      interfaces = mkOption {
        type = with types; listOf str;
        default = ["^e+"];
      };
    };
  };

  config = mkIf cfg.enable {
    # https://docs.rke2.io/install/requirements?cni-rules=Cilium
    networking.firewall.allowedTCPPorts = [2379 2380 2381 6443 9345];

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
        extraFlags =
          [
            "--cluster-domain=${config.networking.domain}"
            "--cluster-cidr=${top.clusterCidr}"
            "--service-cidr=${top.serviceCidr}"
            "--tls-san-security"
            "--tls-san=api.${config.networking.domain}"
            "--tls-san=${config.networking.fqdn}"
          ]
          ++ lib.optionals config.az.svc.rke2.metrics.enable [
            "--etcd-expose-metrics"
            "--kube-scheduler-arg=bind-address=::"
            "--kube-controller-manager-arg=bind-address=::"
          ];
        cni = "cilium";
      };

    az.server.rke2.namespaces."cilium-spire" = {
      podSecurity = "privileged";
      networkPolicy.extraEgress = [{toEntities = ["cluster"];}];
      networkPolicy.extraIngress = [{fromEntities = ["cluster"];}];
    };
    az.server.rke2.manifests."rke2-cilium-config" = [
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChartConfig";
        metadata = {
          name = "rke2-cilium";
          namespace = "kube-system";
        };
        # TODO: remove operator.replicas whenever I get multiple nodes
        spec.valuesContent = builtins.toJSON {
          operator.replicas = 1;

          ipv6.enabled = true;
          kubeProxyReplacement = true;
          k8sServiceHost = "api.${config.networking.domain}";
          k8sServicePort = 8443;
          tunnelProtocol = "";

          encryption = {
            enabled = true;
            nodeEncryption = true;
            type = "wireguard";
          };

          authentication.mutual.spire = {
            # TODO?: use a cnpg DB
            enabled = true;
            install.enabled = true;
            install.existingNamespace = true;
            install.namespace = "cilium-spire";
          };

          bgpControlPlane.enabled = top.bgp.enable;
          l2announcements = {
            enabled = !top.bgp.enable;
            leaseDuration = "10s";
            leaseRenewDeadline = "5s";
            leaseRetryPeriod = "1s";
          };
        };
        #routingMode: native
        #enableIPv4Masquerade: false
        #enableIPv6Masquerade: false # TODO
      }
    ];

    az.server.rke2.manifests."cilium-net" =
      lib.lists.optional (!top.bgp.enable)
      {
        apiVersion = "cilium.io/v2alpha1";
        kind = "CiliumL2AnnouncementPolicy";
        metadata.name = "default";
        spec = {
          #interfaces = ["^lo$"]; #top.loadBalancing.interfaces;
          loadBalancerIPs = false;
          externalIPs = true;
        };
      }
      ++ lib.lists.optional (top.loadBalancing.cidrs != null)
      {
        apiVersion = "cilium.io/v2alpha1";
        kind = "CiliumLoadBalancerIPPool";
        metadata = {
          name = "default";
          namespace = "kube-system";
        };
        spec = {
          allowFirstLastIPs = "No"; # why is this not just a bool...
          blocks = map (cidr: {inherit cidr;}) top.loadBalancing.cidrs;
        };
      };
  };
}
