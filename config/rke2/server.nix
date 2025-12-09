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
    };
  };

  config = mkIf cfg.enable {
    # https://docs.rke2.io/install/requirements?cni-rules=Calico
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
        extraFlags = let
          inherit (config.az.cluster) net;
        in
          [
            "--cluster-domain=${config.networking.domain}"
            "--cluster-cidr=${net.prefix}${net.pods}::/${toString net.subnetSize}"
            "--service-cidr=${net.prefix}${net.services}::/112" # largest supported by k3s, probably also by rke2
            "--node-ip=${net.prefix}${net.nodes}::${
              azLib.math.decToHex config.az.cluster.meta.nodes.${config.networking.hostName}.id ""
            }"
            "--kube-controller-manager-arg=node-cidr-mask-size-ipv6=${toString net.subnetSize}"
            "--tls-san-security"
            "--tls-san=api.${config.networking.domain}"
            "--tls-san=${config.networking.fqdn}"
            "--tls-san=${net.prefix}${net.static}::ffff"
            "--embedded-registry"
          ]
          ++ lib.optionals config.az.cluster.core.metrics.enable [
            "--etcd-expose-metrics"
            "--kube-scheduler-arg=bind-address=::"
            "--kube-controller-manager-arg=bind-address=::"
          ];

        cni = "calico";

        manifests."calico-config".content = let
          inherit (config.az.cluster) net;

          ipPools =
            [
              {
                name = "default";
                cidr = "${net.prefix}${net.pods}::/${toString net.subnetSize}";
                assignmentMode = "Automatic";
                blockSize = 116;
                #natOutgoing = _false;
                #encapsulation = "None";
              }
              {
                name = "static";
                cidr = "${net.prefix}${net.static}::/${toString net.subnetSize}";
                assignmentMode = "Manual"; # only used for ipAddrs annotations
                blockSize = 116;
              }
            ]
            ++ lib.optionals net.mullvad.enable [
              {
                name = "mullvad";
                cidr = "${net.mullvad.ipv6}${net.pods}::/64";
                assignmentMode = "Manual";
                blockSize = 116;
              }
              {
                name = "mullvad-legacy";
                cidr = "${net.mullvad.ipv4}/16";
                assignmentMode = "Manual";
                blockSize = 26;
              }
            ];
        in
          [
            /*
            {
              apiVersion = "v1";
              kind = "ConfigMap";
              metadata = {
                name = "kubernetes-services-endpoint";
                namespace = "tigera-operator";
              };
              data = {
                #KUBERNETES_SERVICE_HOST = "api.${config.networking.domain}";
                KUBERNETES_SERVICE_HOST = "${net.prefix}${net.static}::ffff";
                KUBERNETES_SERVICE_PORT = "8443";
              };
            }
            */
            {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "rke2-calico";
                namespace = "kube-system";
              };
              spec.valuesContent = let
                inherit (config.az.cluster) net;
                _true = "Enabled";
                _false = "Disabled";
              in
                builtins.toJSON {
                  apiServer.enabled = _true;

                  installation = {
                    enabled = _true;
                    nonPrivileged = _false;
                    controlPlaneReplicas = 1;

                    calicoNetwork = {
                      linuxDataplane = "Nftables";
                      #linuxDataplane = "BPF"; # TODO: for some reason completely kills vbr-uplink networking + pod routing doesn't even work?
                      #bpfNetworkBootstrap = _true;
                      #linuxDataplane = "VPP"; # TODO?: doesn't seem to be any way to set up without a bunch of boilerplate
                      bgp = _true;

                      nodeAddressAutodetectionV6.cidrs = ["${net.prefix}${net.nodes}::/${toString net.subnetSize}"];

                      /*
                      ipPools =
                        [
                          {
                            name = "default";
                            cidr = "${net.prefix}${net.pods}::/${toString net.subnetSize}";
                            assignmentMode = "Automatic";
                            blockSize = 116;
                            natOutgoing = _false;
                            encapsulation = "None";
                          }
                          {
                            name = "static";
                            cidr = "${net.prefix}${net.static}::/${toString net.subnetSize}";
                            assignmentMode = "Manual"; # only used for ipAddrs annotations
                            blockSize = 116;
                            natOutgoing = _false;
                            encapsulation = "None";
                          }
                        ]
                        ++ lib.optionals net.mullvad.enable [
                          {
                            name = "mullvad";
                            cidr = "${net.mullvad.ipv6}${net.pods}::/64";
                            assignmentMode = "Manual";
                            blockSize = 116;
                            natOutgoing = _false;
                            encapsulation = "None";
                          }
                          {
                            name = "mullvad-legacy";
                            cidr = "${net.mullvad.ipv4}/16";
                            assignmentMode = "Manual";
                            blockSize = 26;
                            natOutgoing = _false;
                            encapsulation = "None";
                          }
                        ];
                      */
                    };
                  };
                  felixConfiguration = {
                    featureDetectOverride = "ChecksumOffloadBroken=false";
                    #bpfExternalServiceMode = "DSR";
                    wireguardEnabled = true;
                    wireguardEnabledV6 = true;
                  };
                };
            }
          ]
          ++ builtins.map (pool: {
            apiVersion = "crd.projectcalico.org/v1";
            kind = "IPPool";
            metadata.name = pool.name;
            spec =
              {
                allowedUses = ["Workload" "Tunnel"];
                nodeSelector = "all()";
                ipipMode = "Never"; # encap either not needed or handled via iptables
                vxlanMode = "Never";
              }
              // lib.filterAttrs (name: _: name != "name") pool;
          })
          ipPools;
      };

    az.server.rke2.namespaces = {
      "calico-system".networkPolicy.toCluster = true;
      "calico-apiserver".networkPolicy.toCluster = true;
    };
  };
}
