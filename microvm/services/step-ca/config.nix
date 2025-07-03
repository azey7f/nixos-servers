{
  config,
  lib,
  azLib,
  pkgs,
  inputs,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.svc.step-ca;
  server = outputs.servers.${config.az.microvm.serverName}.config;
in {
  options.az.svc.step-ca = with azLib.opt; {
    intermediateCerts = mkOption {
      type = with types; listOf str;
      default = [
        # https://smallstep.com/docs/tutorials/intermediate-ca-new-ca/#can-i-have-multiple-intermediate-cas
        #"${azLib.reverseFQDN config.networking.domain}"
        "${azLib.reverseFQDN server.networking.domain}"
      ];
    };
    #intermediateKey = optStr "${azLib.reverseFQDN config.networking.domain}.key";
    intermediateKey = optStr "${azLib.reverseFQDN server.networking.domain}.key";
  };

  config = mkIf cfg.enable {
    az.microvm.sops.secrets = mkIf cfg.kubernetes.enable {
      "${cfg.sopsPrefix}/jwk" = {};
      "${cfg.sopsPrefix}/provisioner_password" = {};
    };

    az.microvm.sops.templates."${cfg.sopsPrefix}/ca.json".file = (pkgs.formats.json {}).generate "ca.json" {
      root = "/etc/ssl/domain-ca.crt";
      ca-url = "https://${config.networking.fqdn}";

      crt = pkgs.writeText "step-ca.intermediate-bundle.crt" (
        lib.strings.concatMapStringsSep "\n" (name: inputs.core.certs.${name}) cfg.intermediateCerts
      );
      key = "/secrets/step-ca/intermediate_key"; # see ./sops.nix

      address = ":443";
      dnsNames = [config.networking.fqdn];
      logger.format = "text";

      db = {
        type = "badgerv2";
        dataSource = "/etc/step-ca/db";
      };

      /*
        ssh = { #TODO
        hostKey = "/secrets/ssh_host.key";
        userKey = "/secrets/ssh_user.key";
      };
      */

      authority = {
        claims = {
          minTLSCertDuration = "5m";
          maxTLSCertDuration = "2160h"; # 90d
          defaultTLSCertDuration = "2160h";
          disableRenewal = false;
          allowRenewalAfterExpiry = false;
        };

        provisioners = [
          (
            if cfg.kubernetes.enable
            then {
              type = "JWK";
              name = "kubernetes";

              key = {
                use = "sig";
                kty = "EC";
                crv = "P-256";
                alg = "ES256";
                inherit (server.az.server.kubernetes.ca.jwk) x y kid;
              };
              encryptedKey = config.sops.placeholder."${cfg.sopsPrefix}/jwk";

              claims = {
                maxTLSCertDuration = "2160h"; # TODO 90d
                defaultTLSCertDuration = "2160h";
              };
              options.x509 = {
                templateFile = pkgs.writeText "x509-kubernetes.tpl" ''
                  {
                  	"subject": {
                  		"commonName": {{ toJson .Subject.CommonName }},
                  {{- if .Insecure.User.Organization }}
                  		"organization": {{ toJson .Insecure.User.Organization }}
                  {{- else }}
                  		"organization": {{ toJson .Organization }}
                  {{- end }}
                  	},
                  	"sans": {{ toJson .SANs }},
                  {{- if typeIs "*rsa.PublicKey" .Insecure.CR.PublicKey }}
                  	"keyUsage": ["keyEncipherment", "digitalSignature"],
                  {{- else }}
                  	"keyUsage": ["digitalSignature"],
                  {{- end }}
                  	"extKeyUsage": ["serverAuth", "clientAuth"]
                  }
                '';
                templateData.Organization = config.networking.domain;
              };
            }
            else {
              /*
              TODO
              */
            }
          )
        ];
      };
    };
  };
}
