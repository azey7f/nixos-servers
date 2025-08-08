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
      The az.svc.rke2.hydra module uses keepalived, which isn't enabled.
      Normally the hydra module should be used along with az.server.rke2.keepalived.
    '';
    assertions = [
      {
        assertion = config.systemd.services ? hydra-init;
        message = "upstream service breaking change: no hydra-init service defined";
      }
      {
        assertion = config.users.users ? hydra-www && config.users.users ? hydra-queue-runner;
        message = "upstream service breaking change: expected user not defined";
      }
    ];

    # nix config - # CRITICAL TODO
    nix.settings.allowed-users = ["@hydra"];

    # other native stuff
    networking.hosts.${cfg.virtualIP} = ["hydra.${config.networking.domain}"];

    # TODO: cross-compilation for nixos-vps
    # TODO: figure out if there's any way to eval nixos-servers *without* giving hydra access to literally all infra secrets
    services.hydra = {
      enable = true;
      port = cfg.port;
      hydraURL = "https://hydra.${domain}";
      notificationSender = "hydra@invalid.internal"; # TODO

      minimumDiskFree = 50;
      minimumDiskFreeEvaluator = 50;

      dbi = "dbi:Pg:dbname=hydra;host=${config.az.svc.rke2.envoyGateway.addresses.ipv6};user=hydra;";
      extraEnv = {
        # undocumented, https://github.com/NixOS/hydra/blob/79ba8fdd04ba53826aa9aaba6e25fd0d6952b3b3/nixos-modules/hydra.nix#L21
        PGPASSFILE = "/run/secrets/rendered/rke2/hydra/pgpass";
      };
    };

    az.server.rke2.clusterWideSecrets."rke2/hydra/cnpg-passwd" = {};
    sops.templates = let
      pgpass = owner: {
        content = "*:*:*:*:${config.sops.placeholder."rke2/hydra/cnpg-passwd"}";
        group = "hydra";
        inherit owner;
      };
    in {
      "rke2/hydra/pgpass" = pgpass "hydra";
      "rke2/hydra/pgpass-www" = pgpass "hydra-www";
      "rke2/hydra/pgpass-queue-runner" = pgpass "hydra-queue-runner";
    };
    # in the official hydra module's own wise words, "grrr"
    systemd.services.hydra-server.environment.PGPASSFILE = lib.mkForce "/run/secrets/rendered/rke2/hydra/pgpass-www";
    systemd.services.hydra-queue-runner.environment.PGPASSFILE = lib.mkForce "/run/secrets/rendered/rke2/hydra/pgpass-queue-runner";

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
            	#TODO systemctl start az-hydra-active.service
            	#TODO systemctl start --all hydra-\*
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
    az.server.rke2.manifests."app-hydra" = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "app-hydra";
        metadata.labels.name = "app-hydra";
      }

      # cnpg DB
      {
        apiVersion = "postgresql.cnpg.io/v1";
        kind = "Cluster";
        metadata = {
          name = "hydra-cnpg";
          namespace = "app-hydra";
        };
        spec = {
          instances = 1; # TODO: HA

          bootstrap.initdb = {
            database = "hydra";
            owner = "hydra";
            secret.name = "hydra-cnpg-user";
          };

          storage.size = "2Gi"; # should be fine? it's mostly just logs AFAIK
        };
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        type = "kubernetes.io/basic-auth";
        metadata = {
          name = "hydra-cnpg-user";
          namespace = "app-hydra";
        };
        stringData = {
          username = "hydra";
          password = config.sops.placeholder."rke2/hydra/cnpg-passwd";
        };
      }

      # networking boilerplate (yippee)
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "hydra";
          namespace = "app-hydra";
        };
        spec = {
          clusterIP = "None";
          ports = [
            {
              name = "http";
              protocol = "TCP";
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
          name = "hydra";
          namespace = "app-hydra";
          labels."kubernetes.io/service-name" = "hydra";
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
      {
        apiVersion = "gateway.networking.k8s.io/v1alpha2";
        kind = "TCPRoute";
        metadata = {
          name = "hydra-cnpg";
          namespace = "app-hydra";
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
                  name = "hydra-cnpg-rw";
                  port = 5432;
                }
              ];
            }
          ];
        };
      }
    ];

    az.svc.rke2.envoyGateway.httpRoutes = [
      {
        name = "hydra";
        namespace = "app-hydra";
        hostnames = ["hydra.${domain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "hydra";
                port = cfg.port;
              }
            ];
          }
        ];
      }
    ];

    az.svc.rke2.envoyGateway.listeners = [
      {
        name = "hydra-cnpg";
        protocol = "TCP";
        port = 5432;
        allowedRoutes.namespaces.from = "All"; # TODO: Selector
      }
    ];

    az.svc.rke2.authelia.rules = [
      {
        domain = ["hydra.${domain}"];
        policy = "bypass";
      }
    ];
  };
}
