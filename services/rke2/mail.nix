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
        kind = "Secret";
        metadata = {
          name = "mail-env";
          namespace = "kube-system";
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
          targetNamespace = "kube-system"; # https://github.com/bokysan/docker-postfix/issues/199
          #createNamespace = true;

          chart = "mail";
          repo = "https://bokysan.github.io/docker-postfix";
          version = "4.4.0";

          valuesContent = builtins.toJSON {
            existingSecret = "mail-env";
          };
        };
      }
      {
        apiVersion = "networking.k8s.io/v1";
        kind = "NetworkPolicy";
        metadata = {
          name = "mail-allow";
          namespace = "kube-system";
        };
        spec = {
          podSelector.matchLabels."app.kubernetes.io/name" = "mail";
          policyTypes = ["Ingress"];
          ingress = [
            {from = builtins.map (name: {namespaceSelector.matchLabels.name = name;}) cfg.namespaces;}
          ];
        };
      }
    ];

    az.server.rke2.clusterWideSecrets."rke2/mail/zoho-passwd" = {};
  };
}
