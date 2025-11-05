{
  config,
  azLib,
  lib,
  pkgs,
  ...
}: let
  cfg = config.az.svc.mail;
  clusterMail = config.az.cluster.core.mail;
in {
  options.az.svc.mail = with azLib.opt; {
    enable = optBool false;

    host = optStr clusterMail.host;
    port = lib.mkOption {
      type = lib.types.port;
      default = clusterMail.port;
    };
    user = optStr clusterMail.username;
    passwordPlaceholder = optStr clusterMail.passwordPlaceholder;

    domain = optStr "default.invalid";
    from = optStr "${config.networking.hostName}@${cfg.domain}";
    to = optStr "alerts@${cfg.domain}";
  };

  config = lib.mkIf cfg.enable {
    programs.msmtp = {
      enable = true;
      setSendmail = true;
      defaults = {
        aliases = "/etc/aliases";
        #tls_certcheck = false;
        #auth = false;
      };
      accounts.default = {
        tls = true;
        tls_starttls = true;

        auth = true;
        inherit (cfg) host user from;
        port = toString cfg.port;
        passwordeval = "cat /run/secrets/${cfg.passwordPlaceholder}";
      };
    };
    environment.etc.aliases.text = ''
      root: ${cfg.to}
    '';

    services.zfs.zed.settings = lib.mkIf config.az.server.disks.zfs.enable {
      ZED_EMAIL_ADDR = [cfg.to];
      ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
      ZED_EMAIL_OPTS = "@ADDRESS@";

      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = true; # TODO?

      ZED_USE_ENCLOSURE_LEDS = true;
      ZED_SCRUB_AFTER_RESILVER = true;
    };
  };
}
