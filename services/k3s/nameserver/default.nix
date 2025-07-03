{
  config,
  lib,
  azLib,
  outputs,
  ...
} @ args:
with lib; let
  cfg = config.az.svc.k3s.nameserver;
in {
  options.az.svc.k3s.nameserver = with azLib.opt; {
    enable = optBool false;
    domain = mkOption {
      type = types.str;
      default = lib.lists.findFirst (domain:
        outputs.infra.domains.${
          domain
        }.clusters ? "${
          lib.strings.removeSuffix ".${domain}" config.networking.domain
        }")
      (builtins.attrNames outputs.infra.domains);
    };
    secondaryServers = mkOption {
      type = with types; listOf attrs;
      default = builtins.filter (remote: remote ? knotPubkey) outputs.infra.domains.${cfg.domain}.vps;
    };
  };

  config = mkIf cfg.enable {
    az.k3s.namespaces = ["app-knot-dns"];

    az.k3s.manifests = {
      knot-dns.content = {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "knot-dns";
          namespace = "app-knot-dns";
        };
        spec = {
          replicas = 1; # hidden master, doesn't need HA
          template.spec.containers = [
            {
              name = "knot-dns";
              image = "cznic/knot";
              command = ["knotd" "-c" "/config/knot.conf"];
              volumeMounts = [
                {
                  name = "knot-dns-cm";
                  mountPath = "/config";
                }
                {
                  name = "sops-secrets-rendered";
                  mountPath = "/secrets";
                  readOnly = true; # critical, since in the backend it's a writable virtiofs mount shared between nodes
                }
              ];
            }
          ];
          template.spec.volumes = [
            {
              # since all nodes run off the same flake,
              # this is possible (and *should* be safe)
              name = "sops-secrets-rendered";
              hostPath = {
                path = "/secrets/rendered/k3s/nameserver";
                type = "Directory";
              };
            }
          ];
        };
      };

      knot-dns-cm.content = {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "knot-dns-cm";
          namespace = "app-knot-dns";
        };
        data = let
          revDomain = azLib.reverseFQDN cfg.domain;
        in {
          "${revDomain}.zone" = import ./zones/${revDomain}.nix args;
          "knot.conf" = import ./config.nix args;
        };
      };

      sops.secrets."k3s/acme/tsig-secret" = {
        # cluster-wide
        sopsFile = "${config.az.server.sops.path}/${azLib.reverseFQDN config.networking.domain}/default.yaml";
      };
      sops.templates."k3s/nameserver/acme.conf".content = ''
        key:
          - id: acme
            algorithm: hmac-sha256
            secret: ${config.sops.placeholder."k3s/acme/tsig-secret"}
      '';
    };
  };
}
