{
  config,
  azLib,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.az.svc.mail;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.mail = with azLib.opt; {
    enable = optBool false;
    host = optStr config.az.svc.rke2.envoyGateway.gateways.internal.addresses.ipv6;
  };

  config = mkIf cfg.enable {
    programs.msmtp = {
      enable = true;
      setSendmail = true;
      defaults = {
        aliases = "/etc/aliases";
        port = 587;
        auth = "off";
        tls = "on";
        tls_starttls = "on";
        tls_certcheck = "off";
      };
      accounts.default = {
        host = cfg.host;
        user = "noreply@${domain}";
        from = "${config.networking.hostName}@${domain}";
      };
    };
    environment.etc.aliases.text = ''
      root: alerts@${domain}
    '';

    services.zfs.zed.settings = lib.mkIf config.az.server.disks.zfs.enable {
      ZED_EMAIL_ADDR = ["root"];
      ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
      ZED_EMAIL_OPTS = "@ADDRESS@";

      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = false;

      ZED_USE_ENCLOSURE_LEDS = true;
      ZED_SCRUB_AFTER_RESILVER = true;
    };
  };
}
