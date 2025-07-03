{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  top = config.az.microvm.k3s;
  cfg = top.server;
  server = outputs.servers.${config.az.microvm.serverName}.config;
  cluster = outputs.infra.clusters.${server.networking.domain};
in {
  options.az.microvm.k3s.server = with azLib.opt; {
    enable = optBool false;
    clusterInit = optBool (config.az.microvm.index == 0); # init only on first node

    # openssl rand -hex goes brr
    #clusterCidr = optStr "fd9a:c2f6:1fd6:42::/56";
    #serviceCidr = optStr "fd9a:c2f6:1fd6:43::/112";
    clusterCidr = optStr "fd01::/48"; # TODO setup fails with ^^
    serviceCidr = optStr "fd98::/108";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [2379 2380 6443];
    services.k3s =
      (lib.attrsets.optionalAttrs cfg.clusterInit {serverAddr = mkForce "";})
      // {
        role = "server";
        extraFlags = [
          #"--disable=traefik" # TODO?
          "--cluster-domain=${server.networking.domain}"
          "--cluster-cidr=${cfg.clusterCidr}"
          "--service-cidr=${cfg.serviceCidr}"
          "--flannel-ipv6-masq" # TODO
          "--tls-san-security"
          "--tls-san=api.${server.networking.domain}"
          "--tls-san=${config.networking.fqdn}"
          "--secrets-encryption" # all data is encrypted at rest anyways, but this doesn't hurt
          "--disable=servicelb" # metallb used instead
        ];
        clusterInit = cfg.clusterInit;

        autoDeployCharts = server.az.k3s.charts; # see ../../../services/k3s
        manifests = server.az.k3s.manifests;
      };
  };
}
