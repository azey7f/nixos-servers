{
  config,
  lib,
  azLib,
  ...
}: let
  cfg = config.az.svc.rke2.resolver;
  domain = config.az.server.rke2.baseDomain;
in {
  imports = azLib.scanPath ./.;

  options.az.svc.rke2.resolver = with azLib.opt; {
    enable = optBool false;
  };

  config = lib.mkIf cfg.enable {
    az.svc.rke2.nameserver.domains.internal = {
      inherit domain;
      id = "internal";
      zonefile = "internal";
      secondaryServers = lib.mkForce [];
      acmeTsig = false;
    };
  };
}
