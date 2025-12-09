# see https://www.xmox.nl/config/#hdr-mox-conf
{config, ...}: let
  cfg = config.az.cluster.core.mailserver;
in ''
  DataDir: ../data
  LogLevel: debug
  User: 65534

  Hostname: mx.${cfg.primaryDomain}
  AdminPasswordFile: passwd-admin

  Listeners:
  	http:
  		Hostname: mail.${cfg.primaryDomain}

  		IPs:
  			- ${cfg.prefix}::1

  		# :80 services, reverse-proxied through envoy & blocked in firewall
  		AccountHTTP:
  			Enabled: true
  			Forwarded: true
  			Path: /accounts/
  			Port: 8080
  		AdminHTTP:
  			Enabled: true
  			Forwarded: true
  			Path: /admin/
  			Port: 8080
  		WebmailHTTP:
  			Enabled: true
  			Forwarded: true
  			Path: /
  			Port: 8080

  	mail:
  		Hostname: mx.${cfg.primaryDomain}

  		IPs:
  			- ${cfg.prefix}::1

  		# Directly exposed mail & ACME ports - 25, 465, 993, 443
  		SMTP:
  			Enabled: true
  		Submissions:
  			Enabled: true
  		IMAPS:
  			Enabled: true

  		TLS:
  			ACME: letsencrypt
  			HostPrivateKeyFiles:
  				- host.rsa2048.key
  				- host.ecdsap256.key
  		AutoconfigHTTPS:
  			Enabled: true
  		MTASTSHTTPS:
  			Enabled: true

  ACME:
  	letsencrypt:
  		DirectoryURL: https://acme-v02.api.letsencrypt.org/directory
  		IssuerDomainName: letsencrypt.org
  		ContactEmail: domain-admin@${cfg.primaryDomain}

  Postmaster:
  	Account: admin@${cfg.primaryDomain}
  	Mailbox: postmaster
  HostTLSRPT:
  	Account: admin@${cfg.primaryDomain}
  	Mailbox: TLSRPT
  	Localpart: tlsreports
  InitialMailboxes:
  	SpecialUse:
  		Sent: sent
  		Archive: archive
  		Trash: trash
  		Draft: drafts
  		Junk: junk
  Transports:
  	direct:
  		Direct:
  			DisableIPv4: true
  	smtp2go:
  		Submissions:
  			Host: mail-eu.smtp2go.com
  			Port: 465
  			Auth:
  				Username: ${cfg.primaryDomain}
  				Password: ${config.sops.placeholder."rke2/mailserver/passwd-smtp2go"}
''
