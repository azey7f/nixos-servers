# TODO: temp container that proxies traffic to azey.net, since the node & pods can't route to it normally for some reason
{
  pkgs,
  lib,
  config,
  ...
}: let
  nodePrefix = "${config.az.cluster.net.prefix}${config.az.cluster.net.nodes}";
  contAddr = "${nodePrefix}::ffff";
  hostAddr = "${nodePrefix}::${toString config.az.cluster.meta.nodes.${config.networking.hostName}.id}";
in {
  az.core.net.interfaces."vbr-uplink".extraRoutes = [
    {
      Destination = "${config.az.cluster.net.prefix}${config.az.cluster.net.static}::/64";
      Gateway = contAddr;
    }
  ];

  containers.proxy = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;

    hostBridge = "vbr-uplink";
    localAddress6 = "${contAddr}/64";

    config = {config, ...}: {
      system.stateVersion = config.system.nixos.release;
      boot.kernel.sysctl = {
        "net.ipv6.conf.default.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
      };
      networking.firewall = {
        enable = true;
        extraCommands = "ip6tables -I POSTROUTING -t nat -o eth0 -j MASQUERADE";
        extraStopCommands = "ip6tables -D POSTROUTING -t nat -o eth0 -j MASQUERADE";
      };
      networking.defaultGateway.address = hostAddr;
    };
  };
}
