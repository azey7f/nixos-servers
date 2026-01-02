{
  pkgs,
  config,
  lib,
  azLib,
  inputs,
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
          # backup ns, uptime status page, legacy IP site mirror & v4 mail proxy
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
      prefix = "2a14:6f44:5608:";
      prefixSize = 56;

      static = "00";
      pods = "01";
      services = "02";
      nodes = "f0";

      mullvad = {
        enable = true;
        ipv6 = "fd33:7b36:fc28:00";
      };
    };

    core = {
      # networking
      nameserver = {
        enable = true;
        zones = ["azey.net" "8.0.6.5.4.4.f.6.4.1.a.2.ip6.arpa"];
      };
      envoyGateway = {
        enable = true;
        domains."azey.net" = {};
        domains."8.0.6.5.4.4.f.6.4.1.a.2.ip6.arpa".httpOnly = true;
      };

      # monitoring, notifs
      metrics = {
        enable = true;
        webuiDomain = "azey.net";
      };

      mailserver = {
        enable = true;
        primaryDomain = "azey.net";
        domains."azey.net".accounts = {
          "admin" = {};
          "me" = {
            fullName = "azey";
            destinations."@azey.net" = {};
          };
          "noreply" = {
            quota = 1;
            destinations = builtins.listToAttrs (builtins.map (
                dest:
                  lib.nameValuePair "${dest}@azey.net" {smtpError = 550;} # noreply means *no* reply, dammit.
              ) (
                [
                  "noreply"
                  "git"
                  "metrics"
                  "status"
                ]
                ++ builtins.attrNames (builtins.readDir ./nodes)
              ));
          };
        };
      };
      mail = {
        enable = true;
        host = "smtp.zoho.eu";
        username = "noreply@azey.net";
        passwordPlaceholder = "rke2/mail/zoho-passwd";
        senderDomains = ["azey.net"];
      };

      # authelia
      auth = {
        enable = true;
        domain = "azey.net";
        authelia.domains = [
          "azey.net"
          "8.0.6.5.4.4.f.6.4.1.a.2.ip6.arpa"
        ];
      };
    };

    domains."8.0.6.5.4.4.f.6.4.1.a.2.ip6.arpa" = {
      certManager.issuer = "selfsigned";
      nginx = {
        enable = true;
        sites.root = {
          git.enable = false;
          nginxExtraConfig = let
            content = builtins.replaceStrings ["\n"] ["\\n"] ''
                  |\__/,|   (`\${" "}
                _.|o o  |_   ) )
              -(((---(((--------

                       meow
            '';
          in ''
            location = / {
              add_header content-type 'text/plain; charset=US-ASCII';
              return 200 '${content}';
            }
          '';
          envoyExtraConfig.gatewaySection = "http";
        };
      };
    };

    domains."azey.net" = {
      certManager.issuer = "letsencrypt";

      # web core
      nginx = {
        enable = true;
        sites.root = {
          git = {
            repo = "infra/azey.net";
            path = "/static";
          };
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
        sites."me" = {
          git.enable = false;
          index = "self.json";
          content = {
            "self.json" = builtins.readFile ((pkgs.formats.json {}).generate "self" inputs.self-meta.outputs);
          };
        };

        sites."miku".git.repo = "mirrors/ifd3f--ooo.eeeee.ooo"; # im thinking miku miku oo eee oo
      };
      searxng.enable = true;

      # media
      navidrome.enable = true;
      feishin.enable = true;
      jellyfin.enable = true;

      # source control, CI
      forgejo.enable = true;
      woodpecker.enable = true;
      renovate.enable = true;
      attic.enable = true;

      # misc
      filebrowser.enable = true;
    };
  };
}
