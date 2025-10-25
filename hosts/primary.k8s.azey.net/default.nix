{
  config,
  lib,
  azLib,
  ...
}: {
  imports = lib.subtractLists [./nodes] (azLib.scanPath ./.);

  config.az.svc.mail = {
    enable = true;
    domain = "azey.net";
  };

  config.az.cluster = {
    meta = {
      # IDs used for auto-setting IP addrs in config/rke2/default.nix
      # ID 0 is reserved for routing infra
      nodes = {
        "astra".id = 1;
      };

      # VPS defs, used in nameserver & frp
      vps = {
        "ns1" = {
          # ns, http proxy
          zones."azey.net" = {
            external = ["ns1" "@" "*"];
            internal = ["ns1.vps"];
          };

          ipv4 = "188.245.84.161";
          ipv6 = "2a01:4f8:c013:f05f::53";
          knotPubkey = "Dz14HoMs3cuczSYTUscntbB7ZRb7JAGg98/pP+Rv0tk=";
        };
        "ns2" = {
          # ns, uptime status page
          zones."azey.net" = {
            external = ["ns2" "status"];
            internal = ["ns2.vps"];
          };

          ipv4 = "95.217.221.156";
          ipv6 = "2a01:4f9:c012:dc23::53";
          knotPubkey = "jLWkMn4g5XD8oC4HRDzwGY8eWCkExNb/lDUPoiafyis=";
        };
      };
    };

    contactMail = "me@azey.net";

    publicSubnet = "fd95:3a23:dd1f"; # no native IPv6 :c
    clusterCidr = "172.30.0.0/16,fd01::/48"; # TODO: proper IPv6 addrs
    serviceCidr = "172.31.0.0/16,fd98::/108";

    core = {
      # networking
      nameserver.external.enable = true; # rTODO: changed names, resetup
      nameserver.internal.enable = true;
      nameserver.internal.acmeTsig = false; # rTODO
      resolver.enable = true; # rTODO: can't reach nameserver because envoy ipv6 doesn't work

      envoyGateway.gateways.external = {
        enable = true;
        addresses.ipv4 = "10.33.1.1"; # rTODO: remove v4
      };
      envoyGateway.gateways.internal = {
        enable = true;
        addresses.ipv4 = "10.33.1.2"; # rTODO: remove v4
      };
      frp.enable = true;

      # monitoring, notifs
      metrics = {
        enable = true;
        webuiDomain = "azey.net";
      };

      mail = {
        enable = true;
        host = "smtp.zoho.eu:587";
        username = "noreply@azey.net";
        passwordPlaceholder = "rke2/mail/zoho-passwd";
      };

      # authelia
      auth = {
        enable = true;
        domain = "azey.net";
      };
    };

    domains."azey.net" = {
      certManager.enable = true; # TODO: handle deployment without local nameserver, internal step-ca

      # web core
      nginx = {
        enable = true;
        sites.root = {
          repo = "infra/azey.net";
          path = "/static";

          index = "________________none";
          nginxExtraConfig = ''
            rewrite ^(?<path>.*)/__autoindex\.json$	$path/			last;
            rewrite ^(?<path>.*)/$			$path/index.html	last;

            autoindex on;
            autoindex_exact_size on;
            autoindex_format json;
          '';

          envoyExtraConfig = {
            csp = "strict";
            customCSP = {
              worker-src = ["'self'" "blob:"];
              script-src = ["'self'" "blob:"];
            };
            responseHeaders.x-robots-tag = "all";
          };
        };
        sites."miku".repo = "mirrors/ifd3f--ooo.eeeee.ooo"; # im thinking miku miku oo eee oo
      };
      searxng.enable = true; # rTOOD: recreate ns

      # media
      navidrome.enable = true; # rTODO: namespace renamed
      feishin.enable = true; # rTODO: namespace renamed
      jellyfin.enable = true; # rTODO: namespace renamed

      # source control, CI
      forgejo.enable = true; # rTODO: namespace renamed
      woodpecker.enable = true; # rTODO: namespace renamed
      renovate.enable = true; # rTODO: namespace renamed
      attic.enable = true;
    };
  };
}
