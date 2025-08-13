{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.mail;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.mail = with azLib.opt; {
    enable = optBool false;
    namespaces = mkOption {
      type = with types; listOf str;
      default = [];
    };
  };

  config = mkIf cfg.enable {
    az.server.rke2.manifests."app-mail" = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "app-mail";
        metadata.labels.name = "app-mail";
        metadata.labels."pod-security.kubernetes.io/enforce" = "baseline"; # https://github.com/bokysan/docker-postfix/issues/199
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "mail-env";
          namespace = "app-mail";
        };
        stringData = {
          ALLOWED_SENDER_DOMAINS = domain;
          RELAYHOST = "smtp.zoho.eu:587";
          RELAYHOST_USERNAME = "noreply@${domain}";
          RELAYHOST_PASSWORD = config.sops.placeholder."rke2/mail/zoho-passwd";
        };
      }
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "mail";
          namespace = "kube-system";
        };
        spec = {
          targetNamespace = "app-mail";
          #createNamespace = true;

          chart = "mail";
          repo = "https://bokysan.github.io/docker-postfix";
          version = "4.4.0";

          valuesContent = builtins.toJSON {
            existingSecret = "mail-env";
          };
        };
      }
    ];

    az.server.rke2.clusterWideSecrets."rke2/mail/zoho-passwd" = {};
  };
}
