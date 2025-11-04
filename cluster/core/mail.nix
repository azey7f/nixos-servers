{
  pkgs,
  config,
  lib,
  azLib,
  ...
}: let
  cfg = config.az.cluster.core.mail;
in {
  options.az.cluster.core.mail = with azLib.opt; {
    enable = optBool false;

    host = lib.mkOption {type = lib.types.str;};
    port = lib.mkOption {
      type = lib.types.port;
      default = 587;
    };
    username = lib.mkOption {type = lib.types.str;};
    passwordPlaceholder = lib.mkOption {type = lib.types.str;};
  };

  config = lib.mkIf cfg.enable {
    az.server.rke2.namespaces."app-mail" = {
      podSecurity = "baseline"; # https://github.com/bokysan/docker-postfix/issues/199
      networkPolicy.toDomains = [cfg.host];
    };

    services.rke2.autoDeployCharts."mail" = {
      repo = "https://bokysan.github.io/docker-postfix";
      name = "mail";
      version = "4.4.0"; # no update
      hash = "sha256-sBYpD7PGuMMjl0iUWK8ae+KQofyTxnBaHJNlKJJcfQw="; # renovate: https://bokysan.github.io/docker-postfix mail 4.4.0

      targetNamespace = "app-mail";
      values.existingSecret = "mail-env";
    };
    az.server.rke2.secrets = [
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "mail-env";
          namespace = "app-mail";
        };
        stringData = {
          ALLOWED_SENDER_DOMAINS = lib.concatStringsSep " " (builtins.attrNames config.az.cluster.domains);
          POSTFIX_mynetworks = "[${config.az.cluster.net.prefix}::]/${toString config.az.cluster.net.prefixSubnetSize}";

          RELAYHOST = "${cfg.host}:${toString cfg.port}";
          RELAYHOST_USERNAME = cfg.username;
          RELAYHOST_PASSWORD = config.sops.placeholder.${cfg.passwordPlaceholder};
        };
      }
    ];

    az.server.rke2.clusterWideSecrets.${cfg.passwordPlaceholder} = {};
  };
}
