# NOTE: unused, see ../../config/kubernetes/default.nix
{
  config,
  lib,
  azLib,
  pkgs,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.svc.step-ca;
  server = outputs.servers.${config.az.microvm.serverName}.config;
  cluster = outputs.infra.clusters.${server.networking.domain};

  # find nodes on server that fulfill a predicate, e.g. those with an enabled k8s apiserver
  # predicate is a function that takes a microvm's config and returns a bool
  findNodeNames = predicate:
    lib.lists.flatten (
      lib.attrsets.mapAttrsToList (baseName: vm: (
        map (i: let
          name = "${baseName}-${toString i}";
          conf = outputs.microvm."${config.az.microvm.serverName}:${name}".config;
        in
          lib.lists.optional (predicate conf) name)
        (lib.lists.range 0 (vm.count - 1))
      ))
      outputs.infra.servers.${config.networking.domain}.vms
    );
in {
  config = mkIf (cfg.enable && config.az.microvm.kubernetes.enable) {
    az.microvm.dataShare = true;

    # cert bootstrap service
    systemd.services."k8s-bootstrap" = {
      script = let
        vms = server.az.server.microvm.vms;
        mkNames = baseName:
          lib.strings.concatMapStrings
          (i: " ${baseName}-${toString i}")
          (lib.lists.range 0 (vms.${baseName} - 1));
        step = "${pkgs.step-cli}/bin/step";
      in ''
        cd /data
        mkdir -p step-ca-k8s && cd step-ca-k8s

        ### worker certs ###

        # kubelet
        ${lib.strings.concatMapStrings (name: ''
          mkdir -p ${name} && cd ${name}
          if [ ! -f kubelet.pem ]; then
          	${step} ca certificate "system:node:${name}.${config.networking.domain}" \
          		kubelet.pem kubelet.key.pem \
          		--san ${name}.${config.networking.domain} \
            		--san 127.0.0.1 --san ::1 \
          		--set "Organization=system:nodes" \
          		--provisioner "kubernetes" \
          		--provisioner-password-file /secrets/step-ca/provisioner_password \
          		--ca-url https://${config.networking.fqdn} \
          		--root /etc/ssl/domain-ca.crt -f
          fi
          cd ..
        '') (findNodeNames (conf: conf.az.microvm.kubernetes.kubelet.enable))}

        # kube-proxy
        ${lib.strings.concatMapStrings (name: ''
          mkdir -p ${name} && cd ${name}
          if [ ! -f proxy.pem ]; then
          	${step} ca certificate "system:kube-proxy" \
          		proxy.pem proxy.key.pem \
          		--kty RSA \
          		--san ${name}.${config.networking.domain} \
            		--san 127.0.0.1 --san ::1 \
          		--san kube-proxy \
          		--set "Organization=system:node-proxier" \
          		--provisioner "kubernetes" \
          		--provisioner-password-file /secrets/step-ca/provisioner_password \
          		--ca-url https://${config.networking.fqdn} \
          		--root /etc/ssl/domain-ca.crt -f
          fi
          cd ..
        '') (findNodeNames (conf: conf.az.microvm.kubernetes.proxy.enable))}

        # coredns
        ${lib.strings.concatMapStrings (name: ''
          mkdir -p ${name} && cd ${name}
          if [ ! -f coredns.pem ]; then
          	${step} ca certificate "system:coredns" \
          		coredns.pem coredns.key.pem \
          		--kty RSA \
          		--san ${name}.${config.networking.domain} \
            		--san 127.0.0.1 --san ::1 \
          		--set "Organization=system:coredns" \
          		--provisioner "kubernetes" \
          		--provisioner-password-file /secrets/step-ca/provisioner_password \
          		--ca-url https://${config.networking.fqdn} \
          		--root /etc/ssl/domain-ca.crt -f
          fi
          cd ..
        '') (findNodeNames (conf: conf.az.microvm.kubernetes.coredns.enable))}

        # flannel
        ${lib.strings.concatMapStrings (name: ''
          mkdir -p ${name} && cd ${name}
          if [ ! -f flannel.pem ]; then
          	${step} ca certificate flannel \
          		flannel.pem flannel.key.pem \
          		--kty RSA \
          		--san ${name}.${config.networking.domain} \
            		--san 127.0.0.1 --san ::1 \
          		--set "Organization=flannel" \
          		--provisioner "kubernetes" \
          		--provisioner-password-file /secrets/step-ca/provisioner_password \
          		--ca-url https://${config.networking.fqdn} \
          		--root /etc/ssl/domain-ca.crt -f
          fi
          cd ..
        '') (findNodeNames (conf: conf.az.microvm.kubernetes.flannel.enable))}

        ### controller certs ###

        # controller-manager
        ${lib.strings.concatMapStrings (name: ''
          mkdir -p ${name} && cd ${name}
          if [ ! -f controller-manager.pem ]; then
          	${step} ca certificate "system:kube-controller-manager" \
          		controller-manager.pem controller-manager.key.pem \
          		--kty RSA \
            		--san api.${server.networking.domain} \
            		--san ${name}.${config.networking.domain} \
            		--san 127.0.0.1 --san ::1 \
          		--set "Organization=system:kube-controller-manager" \
          		--provisioner "kubernetes" \
          		--provisioner-password-file /secrets/step-ca/provisioner_password \
          		--ca-url https://${config.networking.fqdn} \
          		--root /etc/ssl/domain-ca.crt -f
          fi
          cd ..
        '') (findNodeNames (conf: conf.az.microvm.kubernetes.controllerManager.enable))}

        # scheduler
        ${lib.strings.concatMapStrings (name: ''
          mkdir -p ${name} && cd ${name}
          if [ ! -f scheduler.pem ]; then
          	${step} ca certificate "system:kube-scheduler" \
          		scheduler.pem scheduler.key.pem \
          		--kty RSA \
            		--san api.${server.networking.domain} \
            		--san ${name}.${config.networking.domain} \
            		--san 127.0.0.1 --san ::1 \
          		--set "Organization=system:system:kube-scheduler" \
          		--provisioner "kubernetes" \
          		--provisioner-password-file /secrets/step-ca/provisioner_password \
          		--ca-url https://${config.networking.fqdn} \
          		--root /etc/ssl/domain-ca.crt -f
          fi
          cd ..
        '') (findNodeNames (conf: conf.az.microvm.kubernetes.scheduler.enable))}

        # generic k8s master cert - etcd, apiserver, controller-manager
        ${lib.strings.concatMapStrings (name: ''
            mkdir -p ${name} && cd ${name}
            if [ ! -f kubernetes.pem ]; then
            	${step} ca certificate "kubernetes" \
            		kubernetes.pem kubernetes.key.pem \
            		--kty RSA \
            		--san kubernetes \
            		--san kubernetes.default \
            		--san kubernetes.default.svc \
            		--san kubernetes.default.svc.cluster \
            		--san kubernetes.svc.cluster.local \
            		--san ${name}.${config.networking.domain} \
            		--san api.${server.networking.domain} \
            		--san 127.0.0.1 --san ::1 \
            		--set "Organization=Kubernetes" \
            		--provisioner "kubernetes" \
            		--provisioner-password-file /secrets/step-ca/provisioner_password \
            		--ca-url https://${config.networking.fqdn} \
            		--root /etc/ssl/domain-ca.crt -f
            fi
            cd ..
          '') (findNodeNames (conf: let
            k8s = conf.az.microvm.kubernetes;
          in
            k8s.etcd.enable || k8s.apiserver.enable || k8s.controllerManager.enable))}

        # service account
        ${lib.strings.concatMapStrings (name: ''
            mkdir -p ${name} && cd ${name}
            if [ ! -f service-account.pem ]; then
            	${step} ca certificate "service-accounts" \
            		service-account.pem service-account.key.pem \
            		--kty RSA \
            		--san api.${server.networking.domain} \
            		--san ${name}.${config.networking.domain} \
            		--san 127.0.0.1 --san ::1 \
            		--set "Organization=Kubernetes" \
            		--provisioner "kubernetes" \
            		--provisioner-password-file /secrets/step-ca/provisioner_password \
            		--ca-url https://${config.networking.fqdn} \
            		--root /etc/ssl/domain-ca.crt -f
            fi
            cd ..
          '') (findNodeNames (conf: let
            k8s = conf.az.microvm.kubernetes;
          in
            k8s.apiserver.enable || k8s.controllerManager.enable))}
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Restart = "on-failure";
        RestartSec = 0.5; # restart every .5s, up to 10 times
      };
      startLimitIntervalSec = 60;
      startLimitBurst = 10;
      after = ["step-ca.service"];
      wantedBy = ["default.target"];
    };
  };
}
