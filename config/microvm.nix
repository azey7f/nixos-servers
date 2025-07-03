{
  config,
  azLib,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
} @ args:
with lib; let
  cfg = config.az.server.microvm;
  cluster = outputs.infra.clusters.${config.networking.domain};
in {
  options.az.server.microvm = with azLib.opt; {
    enable = optBool false;

    # large number of declarative VMs = insane rebuild times for host
    #TODO imperative = optBool false;

    vms = mkOption {
      # VM names in microvm/hosts/, with the value being the number of instances to create
      type = with types; attrsOf ints.positive;
      default = builtins.mapAttrs (n: v: v.count) cluster.servers.${config.networking.hostName}.vms;
      example = {
        k8s-ca = 1;
        k8s-controller = 3;
        k8s-worker = 5;
      };
    };
  };

  config = mkIf cfg.enable (let
    vmNames =
      lib.attrsets.foldlAttrs (acc: name: count: (
        acc
        ++ (builtins.map (
          i: "${config.networking.hostName}:${name}-${toString i}"
        ) (lib.lists.range 0 (count - 1)))
      )) []
      cfg.vms;
  in {
    # TODO cron

    # sops-nix stuff
    users.users.microvm.extraGroups = ["keys"];
    sops = lib.mkMerge (map (hostName: let
        conf = outputs.microvm.${hostName}.config;
      in {
        secrets = builtins.mapAttrs (name: value:
          value
          // {
            sopsFile = "${
              config.az.server.sops.path
            }/${
              azLib.reverseFQDN config.networking.fqdn
            }/${
              value.sopsFile or "${conf.networking.hostName}/default.yaml"
            }";
          })
        conf.az.microvm.sops.secrets;
        templates = conf.az.microvm.sops.templates;
      })
      vmNames);

    # misc
    #systemd.services."microvm-virtiofsd@".serviceConfig.TimeoutStopSec = 1;
    systemd.services."microvm@".serviceConfig.Type = mkForce "simple"; # qemu is stuck in activating state without this ATM

    # network stuff
    az.server.net.frr.extraInterfaces = ["vbr-microvm"];
    az.server.net.bridges.vbr-microvm = {
      enable = true;
      ipv6 = [
        "${
          cluster.publicSubnet
        }${
          cluster.microvmSubnet
        }${
          azLib.math.decToHex config.az.server.id ""
        }::ffff/64"
      ];
      interfaces =
        builtins.map (name: "vmtap${
          toString outputs.microvm.${name}.config.az.microvm.id
        }")
        vmNames;
      mac = "02:00:00:00:00:ff";
    };

    networking.hosts = (
      lib.attrsets.concatMapAttrs (
        serverName: server: let
          serverConf = outputs.servers.${serverName}.config;
        in
          (lib.attrsets.concatMapAttrs (baseName: vm: (
              builtins.listToAttrs (
                builtins.map (
                  i: let
                    conf = outputs.microvm."${serverName}:${baseName}-${toString i}".config;
                  in {
                    name = "${
                      cluster.publicSubnet
                    }${
                      cluster.microvmSubnet
                    }${
                      azLib.math.decToHex serverConf.az.server.id ""
                    }::${toString (conf.az.microvm.id + 1)}";
                    value =
                      (lib.lists.optional (serverName == config.networking.hostName) conf.networking.hostName)
                      ++ [conf.networking.fqdn];
                  }
                ) (lib.lists.range 0 (vm.count - 1))
              )
            ))
            server.vms)
          // {
            # server
            "${builtins.elemAt serverConf.az.server.net.ipv6.address 0}" = [
              serverConf.networking.hostName
              serverConf.networking.fqdn
            ];
            # K8s/K3s API virtual IP, see ../microvm/config/*/loadbalancer.nix
            "${
              cluster.publicSubnet
            }${
              cluster.microvmSubnet
            }${
              azLib.math.decToHex serverConf.az.server.id ""
            }::fffe" = ["api.${serverConf.networking.domain}"];
          }
      )
      cluster.servers
    );

    # actual microvm defs
    microvm = {
      host.enable = lib.mkForce true;

      vms =
        #mkIf (!cfg.imperative)
        builtins.listToAttrs (builtins.map (name: {
            inherit name;
            value = {
              flake = inputs.self;
              updateFlake = "git+file:///etc/nixos";
              #restartIfChanged = true;
            };
          })
          vmNames);

      #autostart = optionals cfg.imperative (mapAttrsToList (name: _: "${config.networking.hostName}:${name}") vmsEnabled);
    };
  });
}
