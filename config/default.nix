{
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; {
  imports = azLib.scanPath ./.;

  options.az.server = {
    # server index in outputs.infra.clusters.*.servers
    id = mkOption {
      type = types.ints.unsigned;
      default = lists.findFirstIndex (server: server == config.networking.hostName) null (builtins.attrNames outputs.infra.clusters.${config.networking.domain}.servers);
    };
  };
}
