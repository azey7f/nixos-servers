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
  cfg = top.etcd;
  server = outputs.servers.${config.az.microvm.serverName}.config;
  cluster = outputs.infra.clusters.${server.networking.domain};
in {
  options.az.microvm.kubernetes.etcd = with azLib.opt; {
    enable = optBool false;
    dataDir = mkOpt types.path "/data/etcd";

    servers = mkOption {
      type = with types; listOf str;
      default = lib.lists.flatten (
        lib.attrsets.mapAttrsToList (serverName: serverV: (
          lib.attrsets.mapAttrsToList (baseName: vm: (
            map (i: let
              name = "${baseName}-${toString i}";
              conf = outputs.microvm."${serverName}:${name}".config;
            in
              lib.lists.optional conf.az.microvm.kubernetes.etcd.enable "${name}.${serverName}.${server.networking.domain}")
            (lib.lists.range 0 (vm.count - 1))
          ))
          serverV.vms
        ))
        cluster.servers
      );
    };
  };

  config = mkIf cfg.enable {
    az.microvm.dataShare = true;

    networking.firewall.allowedTCPPorts = [2379 2380];
    environment.systemPackages = with pkgs; [etcd];

    systemd.services.etcd = {
      serviceConfig.LoadCredential = [
        "kubernetes.pem:/certs/kubernetes.pem"
        "kubernetes.key.pem:/certs/kubernetes.key.pem"
      ];
      wants = ["network-online.target"];
      after = ["network-online.target"];
    };

    services.etcd = {
      enable = true;
      name = config.networking.fqdn;

      trustedCaFile = "/etc/ssl/domain-ca.crt";
      certFile = "/run/credentials/etcd.service/kubernetes.pem";
      keyFile = "/run/credentials/etcd.service/kubernetes.key.pem";

      clientCertAuth = true;
      peerClientCertAuth = true;

      listenClientUrls = [
        "https://[${top.vmAddr}]:2379"
        "https://[::1]:2379"
        "https://127.0.0.1:2379"
      ];
      listenPeerUrls = ["https://[${top.vmAddr}]:2380"];

      initialAdvertisePeerUrls = ["https://${config.networking.fqdn}:2380"];
      advertiseClientUrls = ["https://${config.networking.fqdn}:2379"];

      initialCluster = map (fqdn: "${fqdn}=https://${fqdn}:2380") cfg.servers;

      dataDir = cfg.dataDir;
    };
  };
}
