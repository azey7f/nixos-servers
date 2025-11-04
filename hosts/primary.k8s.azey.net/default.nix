{
  config,
  lib,
  azLib,
  ...
}: {
  config.az.svc.mail = {
    enable = true;
    domain = "azey.net";
  };

  config.az.cluster = rec {
    meta = {
      # IDs used for auto-setting IP addrs in config/rke2/default.nix
      # IDs 0xffff and above are reserved
      nodes = {
        "astra".id = 1;
      };

      vps = {
        "ns2" = {
          # backup ns, uptime status page & legacy IP site mirror
          zones."azey.net" = ["ns2" "status" "v4"];
          ip = "2a01:4f9:c012:dc23::1";
          ipv4 = "95.217.221.156";
          knotPubkey = "jLWkMn4g5XD8oC4HRDzwGY8eWCkExNb/lDUPoiafyis=";
        };
      };
    };

    contactMail = "me@azey.net";

    net = {
      # see ../../README.md for full breakdown
      prefix = "2a14:6f44:5608";
      prefixSubnetSize = 48;

      static = ""; # :00
      pods = ":1"; # :01
      services = ":2"; # :02
      nodes = ":f0"; # :f0
    };

    core = {
      # networking
      nameserver.enable = true; # rTODO namespace
      envoyGateway.enable = true; # rTODO Gateway rename

      # monitoring, notifs
      metrics = {
        enable = true;
        webuiDomain = "azey.net";
      };

      mail = {
        enable = true;
        host = "smtp.zoho.eu";
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
      searxng.enable = true;

      # media
      navidrome.enable = true;
      feishin.enable = true;
      # TODO: jellyfin.enable = true;

      # source control, CI
      forgejo.enable = true;
      woodpecker.enable = true;
      renovate.enable = true;
      attic.enable = true;
    };
  };
}
