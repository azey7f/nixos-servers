{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  top = config.az.microvm.kubernetes;
  cfg = top.apiserver;
  server = outputs.servers.${config.az.microvm.serverName}.config;
in {
  options.az.microvm.kubernetes.apiserver = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [6443];

    systemd.services.kube-apiserver = {
      serviceConfig.ReadWritePaths = ["/certs"];
      serviceConfig.LoadCredential = [
        "kubernetes.pem:/certs/kubernetes.pem"
        "kubernetes.key.pem:/certs/kubernetes.key.pem"
        "service-account.pem:/certs/service-account.pem"
        "service-account.key.pem:/certs/service-account.key.pem"
      ];
    };

    services.kubernetes.apiserver = let
      certFile = "/run/credentials/kube-apiserver.service/kubernetes.pem";
      keyFile = "/run/credentials/kube-apiserver.service/kubernetes.key.pem";
    in {
      enable = true;
      allowPrivileged = false;

      serviceClusterIpRange = top.servicesSubnet;

      #runtimeConfig = "api/all=false,api/v1=true"; # TODO: ???
      extraOpts = "--v=4";

      securePort = 6443;
      #bindAddress = top.vmAddr;
      bindAddress = "::";
      advertiseAddress = top.vmAddr;

      etcd = {
        inherit certFile keyFile;
        servers = map (fqdn: "https://${fqdn}:2379") top.etcd.servers;
      };

      tlsCertFile = certFile;
      tlsKeyFile = keyFile;
      kubeletClientCertFile = certFile;
      kubeletClientKeyFile = keyFile;

      apiAudiences = "api,https://api.${server.networking.domain}";
      serviceAccountIssuer = "https://api.${server.networking.domain}";
      serviceAccountKeyFile = "/run/credentials/kube-apiserver.service/service-account.pem";
      serviceAccountSigningKeyFile = "/run/credentials/kube-apiserver.service/service-account.key.pem";

      # https://github.com/justinas/nixos-ha-kubernetes/blob/f270d173f1efde7704b4d6dd805a27a3d2c1cba7/modules/controlplane/apiserver.nix#L11-L33
      # TODO?
      authorizationMode = ["RBAC" "Node" "ABAC"];
      authorizationPolicy =
        (map (r: {
          apiVersion = "abac.authorization.kubernetes.io/v1beta1";
          kind = "Policy";
          spec = {
            user = "system:coredns";
            namespace = "*";
            resource = r;
            readonly = true;
          };
        }) ["endpoints" "services" "pods" "namespaces"])
        ++ (map (r: {
          apiVersion = "abac.authorization.kubernetes.io/v1beta1";
          kind = "Policy";
          spec = {
            user = "flannel";
            namespace = "*";
            resource = r;
            readonly = true;
          };
        }) ["pods" "nodes"])
        ++ [
          {
            apiVersion = "abac.authorization.kubernetes.io/v1beta1";
            kind = "Policy";
            spec = {
              user = "system:coredns";
              namespace = "*";
              resource = "endpointslices";
              apiGroup = "discovery.k8s.io";
              readonly = true;
            };
          }
          {
            apiVersion = "abac.authorization.kubernetes.io/v1beta1";
            kind = "Policy";
            spec = {
              user = "flannel";
              namespace = "*";
              resource = "nodes";
              subresource = "status";
              verb = "patch";
            };
          }

          # no idea why this is needed even though I'm using a system:masters cert
          # kubectl exec, logs & port-forward fails with Forbidden without it
          {
            apiVersion = "abac.authorization.kubernetes.io/v1beta1";
            kind = "Policy";
            spec = {
              user = "kubernetes";
              namespace = "*";
              resource = "nodes";
            };
          }
        ];
    };
  };
}
