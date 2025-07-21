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
  cfg = top.kata;
in {
  options.az.server.rke2.kata = with azLib.opt; {
    enable = optBool false; # TODO
  };

  config = mkIf cfg.enable {
    systemd.services.rke2-server.serviceConfig.DeviceAllow = [
      "/dev/kvm rwm"
      "/dev/kmsg rwm"
      "/dev/vhost-vsock rwm"
      "/dev/vhost-net rwm"
      "/dev/net/tun rwm"
    ];
    systemd.services.rke2-server.serviceConfig.Delegate = "yes";

    systemd.services.rke2-server.path = [pkgs.kata-runtime];
    systemd.tmpfiles.settings."10-rke2"."/var/lib/rancher/rke2/agent/etc/containerd/config-v3.toml.tmpl"."L+".argument = "${pkgs.writeText "config-v3.toml.tmpl" ''
      {{ template "base" . }}

      [plugins.'io.containerd.cri.v1.runtime'.containerd]
        default_runtime_name = "kata"
      [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.'kata']
        runtime_type = "io.containerd.kata.v2"
        privileged_without_host_devices = true
        pod_annotations = ["io.katacontainers.*"]
        container_annotations = ["io.katacontainers.*"]
    ''}";
  };
}
