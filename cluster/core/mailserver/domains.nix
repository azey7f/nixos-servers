# see https://www.xmox.nl/config/#hdr-domains-conf
{
  config,
  lib,
  azLib,
  ...
}: let
  cfg = config.az.cluster.core.mailserver;
in ''
  Domains:
  ${lib.concatStringsSep "\n" (lib.mapAttrsToList (domain: dcfg: ''
      # <- indent here, nix
      	${domain}:
      		ClientSettingsDomain: mx.${domain}
      		LocalpartCatchallSeparator: +

      		DKIM:
      			Selectors:
      				2025a:
      					Expiration: 72h
      					PrivateKeyFile: ${azLib.reverseFQDN domain}.2025a.key
      			Sign:
      				- 2025a
      		DMARC:
      			Localpart: dmarcreports
      			Account: admin@${cfg.primaryDomain}
      			Mailbox: DMARC

      		MTASTS:
      			PolicyID: 20251130T201625
      			Mode: enforce
      			MaxAge: 72h0m0s
      			MX:
      				- mx.${domain}

      		TLSRPT:
      			Localpart: tlsreports
      			Account: admin@${cfg.primaryDomain}
      			Mailbox: TLSRPT
    '')
    cfg.domains)}

  Accounts:
  ${lib.concatStringsSep "\n" (lib.mapAttrsToList (domain: dcfg:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (name: acc: ''
        # <- indent here, nix
        	${name}@${domain}:
        		Domain: ${domain}
        		Destinations:
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (destName: dest: ''
            # <- indent here, nix
            			${destName}:
            ${
              if (dest.smtpError == null)
              then "				Mailbox: ${dest.mailbox}"
              else "				SMTPError: ${toString dest.smtpError}"
            }
            ${
              lib.optionalString (dest.fullName != null)
              "				FullName: ${dest.fullName}"
            }
            ${
              lib.optionalString (dest.rulesets != []) ''
                # <- indent here, nix
                				Rulesets:
                					-
                						${
                  # why must every bit of software use its own specific obscure config language
                  # JSON/YAML/TOML are *right* there.
                  lib.concatStringsSep "\n\t\t\t\t\t-\n\t\t\t\t\t\t" (builtins.map (
                      builtins.replaceStrings ["\n"] ["\n\t\t\t\t\t\t"]
                    )
                    dest.rulesets)
                }
              ''
            }
          '')
          acc.destinations)}

        		SubjectPass:
        			Period: 24h0m0s

        		RejectsMailbox: rejects
        		KeepRejects: true

        ${lib.optionalString (acc.fullName != null) "		FullName: ${acc.fullName}"}
        ${lib.optionalString (acc.quota != null) "		QuotaMessageSize: ${toString acc.quota}"}

        		AutomaticJunkFlags:
        			Enabled: true
        			JunkMailboxRegexp: ^(junk|spam)
        			NeutralMailboxRegexp: .*

        		JunkFilter:
        			Threshold: 0.950000
        			Params:
        				Onegrams: true

        				MaxPower: 0.010000
        				TopWords: 10
        				IgnoreWords: 0.100000
        				RareWords: 2

        		NoCustomPassword: ${lib.boolToString acc.noCustomPasswd}
      '')
      dcfg.accounts))
  cfg.domains)}

  Routes:
  	-
  		MinimumAttempts: 1
  		Transport: smtp2go
  	-
  		Transport: direct

  MonitorDNSBLs:
  	- sbl.spamhaus.org
  	- bl.spamcop.net
''
