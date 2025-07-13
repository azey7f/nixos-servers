# TODO: https://docs.k3s.io/cli/certificate#using-custom-ca-certificates
{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.server.rke2;
  cluster = outputs.infra.clusters.${config.networking.domain};
in {
  config = mkIf cfg.enable {
    # https://docs.rke2.io/security/hardening_guide#set-kernel-parameters
    boot.kernel.sysctl = {
      "vm.panic_on_oom" = 0;
      "vm.overcommit_memory" = 1;
      "kernel.panic" = 10;
      "kernel.panic_on_oops" = 1;
    };

    # https://docs.rke2.io/security/hardening_guide#etcd-is-configured-properly
    users.users.etcd = {
      uid = 373448431; # random 0 2147483647 - should be unique
      group = "etcd";
      isSystemUser = true;
    };
    users.groups.etcd.gid = 373448431;

    # https://docs.rke2.io/security/hardening_guide#rke2-configuration
    services.rke2.extraFlags = ["--profile=cis"];
  };
}
