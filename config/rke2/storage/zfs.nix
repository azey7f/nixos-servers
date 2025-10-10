{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  top = config.az.server.rke2.storage;
  cfg = top.zfs;
in {
  options.az.server.rke2.storage.zfs = with azLib.opt; {
    # https://github.com/openebs/zfs-localpv - good enough for a single node setup
    enable = optBool false;
    disks = mkOption {
      # striped mirror/RAID10 setup
      type = with types; listOf (listOf str);
      default = [];
    };
    poolName = optStr "openebs";
    subvol = optStr "openebs";

    keylocation = optStr "file:///keys/${cfg.poolName}";
    keyformat = optStr "raw";
    ashift = optStr "12";
  };

  config = mkIf cfg.enable {
    disko.devices.disk = builtins.listToAttrs (lib.lists.flatten (
      lib.lists.imap0 (i: vdev: (
        lib.lists.imap0 (j: disk: {
          name = "${cfg.poolName}-${toString i}-${toString j}";
          value = {
            type = "disk";
            device = disk;
            content = {
              type = "gpt";
              partitions.zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = cfg.poolName;
                };
              };
            };
          };
        })
        vdev
      ))
      cfg.disks
    ));

    disko.devices.zpool.${cfg.poolName} = {
      type = "zpool";
      mode.topology = {
        type = "topology";
        vdev =
          lib.lists.imap0 (i: vdev: {
            mode = "mirror";
            members = lib.lists.imap0 (j: _: "${cfg.poolName}-${toString i}-${toString j}") vdev;
          })
          cfg.disks;
      };

      options.ashift = cfg.ashift;
      rootFsOptions = {
        xattr = "sa";
        dnodesize = "auto";
        acltype = "posixacl";
        compression = "lz4";
        relatime = "on";

        encryption = "on";
        inherit (cfg) keylocation keyformat;

        canmount = "off";
        mountpoint = "none";
      };

      datasets.${cfg.subvol}.type = "zfs_fs";
      datasets."${cfg.subvol}/local" = {
        type = "zfs_fs";
        mountpoint = "/var/local/openebs";
      };
    };

    systemd.tmpfiles.rules = [
      # https://github.com/openebs/openebs/issues/3727#issuecomment-2366776183
      "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
    ];
    systemd.services.rke2-server.path = with pkgs; [zfs];

    az.server.rke2.namespaces."openebs-system" = {
      podSecurity = "privileged";
      networkPolicy.extraEgress = [{toEntities = ["kube-apiserver"];}];
    };

    services.rke2.autoDeployCharts."openebs" = {
      repo = "https://openebs.github.io/openebs";
      name = "openebs";
      version = "4.3.0";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # renovate: https://openebs.github.io/openebs openebs

      targetNamespace = "openebs-system";

      # renovate-args: --set engines.replicated.mayastor.enabled=false --set engines.local.lvm.enabled=false --set engines.local.zfs.enabled=true
      values = {
        engines = {
          local = {
            lvm.enabled = false;
            zfs.enabled = true;
          };
          replicated.mayastor.enabled = false;
        };

        loki.singleBinary.replicas = 1;
        loke.loki.commonConfig.replication_factor = 1;
        minio.replicas = 1;
      };
    };
    az.server.rke2.manifests."openebs-sc" = [
      {
        apiVersion = "storage.k8s.io/v1";
        kind = "StorageClass";
        metadata = {
          name = "default";
          annotations."storageclass.kubernetes.io/is-default-class" = "true";
        };
        provisioner = "zfs.csi.openebs.io";
        parameters = {
          fstype = "zfs";
          poolname = "${cfg.poolName}/${cfg.subvol}";
        };
      }
    ];
  };
}
