# this is half a native module and half an RKE2 one, but it's still clustered so I'm putting it here
# since I'm not sure if hydra is stateless even with an external DB (#TODO),
# the service only gets started via keepalived on one host at a time and is accessed via VIP
{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.hydra;
  cluster = outputs.infra.clusters.${config.networking.domain};
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.hydra = with azLib.opt; {
    enable = optBool false;
    port = mkOpt types.port 8033; # semi-random
    virtualIP = optStr "${cluster.publicSubnet}::fffe";
  };

  config = mkIf cfg.enable {
    warnings = lib.lists.optional (!config.services.keepalived.enable) ''
      The az.svc.rke2.hydra module uses keepalived, which isn't configured.
      Normally the hydra module should be used along with az.server.rke2.keepalived.
    '';

    # native stuff
    networking.hosts.${cfg.virtualIP} = ["hydra.${config.networking.domain}"];

    services.hydra = {
      enable = true;
      hydraURL = "https://hydra.${domain}";
      notificationSender = "hydra@localhost";
      extraEnv = {
        # undocumented, https://github.com/NixOS/hydra/blob/79ba8fdd04ba53826aa9aaba6e25fd0d6952b3b3/nixos-modules/hydra.nix#L21
        PGPASSFILE = "/run/secrets/rendered/rke2/hydra/pgpass";
      };
    };

    sops.templates."rke2/hydra/pgpass" = {
      content = "dbserver.example.org:*:hydra:hydra:${config.sops.placeholder."rke2/hydra/pgpass"}"; # TODO
      owner = "hydra";
      group = "hydra";
      mode = "0440";
    };

    # prevent starting hydra automatically, requisite bind to dummy service
    systemd.services.hydra-init.requisite = ["az-hydra-active.service"];
    systemd.services.az-hydra-active = {
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
      serviceConfig.ExecStart = "${pkgs.coreutils}/bin/true";
    };

    # keepalived config
    services.keepalived = let
      kcfg = config.az.server.rke2.keepalived;
    in {
      vrrpInstances.hydra = {
        interface = kcfg.interface;
        priority = 200 + config.az.server.id;
        virtualRouterId = 2;
        virtualIps = [{addr = cfg.virtualIP;}];
        unicastSrcIp = builtins.elemAt config.az.server.net.ipv6.address 0;
        unicastPeers = lib.lists.flatten (
          lib.attrsets.mapAttrsToList (serverName: server: (
            let
              conf = outputs.nixosConfigurations.${serverName}.config;
            in
              lib.lists.optional (conf.az.server.id != config.az.server.id && conf.az.server.rke2.hydra.enable) (
                lib.lists.findFirst (addr: (
                  lib.lists.any (n: n == "${serverName}.${conf.networking.domain}")
                  config.networking.hosts.${addr}
                ))
                null (builtins.attrNames config.networking.hosts)
              )
          ))
          cluster.nodes
        );
        extraConfig = ''
          notify ${pkgs.writeScript "keepalived-hydra-notify" ''
            #!/usr/bin/env sh
            if [ "$3" == "MASTER" ]; then
            	systemctl start az-hydra-active.service
		systemctl start --all hydra-\*
            else
            	systemctl stop hydra-\* # shouldn't be necessary, but just in case
            	systemctl stop az-hydra-active.service
            fi
          ''}
        '';
      };
    };

    # K8s stuff
    az.svc.rke2.cnpg.enable = true; # TODO
    az.server.rke2.manifests."envoy-gateway-external" = [
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "external-hydra";
          namespace = "envoy-gateway";
        };
        spec = {
          clusterIP = "None";
          ports = [
            {
              name = "http";
              procotol = "TCP";
              port = cfg.port;
              targetPort = cfg.port;
            }
          ];
        };
      }
      {
        apiVersion = "discovery.k8s.io/v1";
        kind = "EndpointSlice";
        metadata = {
          name = "external-hydra";
          namespace = "envoy-gateway";
          labels."kubernetes.io/service-name" = "external-hydra";
        };
        addressType = "IPv6";
        ports = [
          {
            name = "http";
            protocol = "TCP";
            port = cfg.port;
          }
        ];
        endpoints = [
          {
            addresses = [cfg.virtualIP];
            conditions.ready = true;
          }
        ];
      }
    ];

    az.svc.rke2.envoyGateway.httpRoutes = [
      {
        name = "external-hydra";
        namespace = "envoy-gateway";
        hostnames = ["hydra.${domain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "external-hydra";
                port = cfg.port;
              }
            ];
          }
        ];
      }
    ];

    az.svc.rke2.authelia.rules = [
      {
        domain = ["hydra.${domain}"];
        subject = "group:admin";
        policy = "two_factor";
      }
    ];
  };
}
