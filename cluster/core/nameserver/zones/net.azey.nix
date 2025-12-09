domain: {
  config,
  lib,
  ...
}: let
  pgpPubkey = "mDMEZ/1EchYJKwYBBAHaRw8BAQdAqV4yxw+9cXHvJeK037MNrwnqUNhsBnptvFAXmymSCxS0EmF6ZXkgPG1lQGF6ZXkubmV0PoiZBBMWCgBBFiEELMs0A0P+iiuRzn91+U9KccXCHo8FAmf9RHICGwMFCQWjmoAFCwkIBwICIgIGFQoJCAsCBBYCAwECHgcCF4AACgkQ+U9KccXCHo/m2wEAhYbrg5+fa6ZQT3dOjaSxp9rGJAZnSNPBZfHsda2CHDABAPxFZ9VciZ1FRGscGAHYwUX3N9FQZk4kiwWQmzqFPRMCuDgEZ/1EchIKKwYBBAGXVQEFAQEHQMGURGFScsMEkgYpKnN6cAxFDT1bPrtsgXrTBvlILG9MAwEIB4h+BBgWCgAmFiEELMs0A0P+iiuRzn91+U9KccXCHo8FAmf9RHICGwwFCQWjmoAACgkQ+U9KccXCHo+dngEAoF4P7ovWPrIN/E3bmxWRAEvQ5tw1qUm8K49Dvx8UOLIBAPiHqMUYZtya/Umdh2MK15iotuP+7BiC/70kq6cF8YQO";

  gateway = config.az.cluster.core.envoyGateway.address;
in ''
  $TTL 3600
  $ORIGIN ${domain}.

  ; zone metadata
  @                     IN  SOA           ns1 domain-admin (
                                          0000000000 ; serial number - later overridden by knot
                                          900        ; refresh
                                          300        ; update retry
                                          604800     ; expiry
                                          900        ; minimum
                                          )

  @                     IN  NS            ns1
  @                     IN  NS            ns2

  ; AAAA
  ns1                   IN  A             199.16.241.247
  ns1                   IN  AAAA          ${config.az.cluster.core.nameserver.address}
  @                     IN  AAAA          ${gateway}
  *                     IN  AAAA          ${gateway}

  ; VPS records added in ../default.nix

  ; CAA
  @                     IN  CAA           0 contactemail "${config.az.cluster.contactMail}"
  *                     IN  CAA           0 contactemail "${config.az.cluster.contactMail}"
  @                     IN  CAA           0 iodef "mailto:domain-admin@${domain}"
  *                     IN  CAA           0 iodef "mailto:domain-admin@${domain}"
  @                     IN  CAA           0 issue "letsencrypt.org"
  *                     IN  CAA           0 issue "letsencrypt.org"

  ; PGP keys
  ; gpg --auto-key-locate clear,nodefault,cert,dane --locate-keys me@azey.net
  me                                                                     IN   CERT         PGP 0 0 ${pgpPubkey}
  2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc._openpgpkey   IN   OPENPGPKEY   ${pgpPubkey}

  ; misc
  ; #TODO?: HTTPS, SSHFP, TLSA, SMIMEA?
  _discord              IN  TXT           dh=8e02c1081c96fd004473289694bf381e590c750b
  _discord.v4           IN  TXT           dh=6b2944feeb1b6151daff7e0cca8a787a56d9ce9b


  ; Mail stuff - smtp2go
  ; direct v6 is tried first, but way too many mail servers don't support v6, so...
  em695095              IN  CNAME         return.smtp2go.net.
  s695095._domainkey    IN  CNAME         dkim.smtp2go.net.


  ; Mail stuff - mox
  ; @                     IN  MX            10 mx
  ; @                     IN  MX            99 mx-legacy
  ; mx                    IN  AAAA          ${config.az.cluster.core.mailserver.prefix}::
  ; mx-legacy             IN  A             ${config.az.cluster.meta.vps."ns2".ipv4}

  ;; misc
  ; @                     IN  TXT           "v=spf1 ip6:${config.az.cluster.core.mailserver.prefix}::/72 ~all"
  ; _smtp._tls            IN  TXT           "v=TLSRPTv1; rua=mailto:tlsreports@${domain}"
  ; _dmarc                IN  TXT           "v=DMARC1;p=reject;rua=mailto:dmarcreports@${domain}!10m"
  ; 2025a._domainkey      IN  TXT           "v=DKIM1;h=sha256;k=ed25519;p=vylt3N4vu2LAFO2Ojvylet1VokzjHTS8KdjtL6tfmRg="
  ; _25._tcp.mx           IN  TLSA          3 1 1 a9362111512ea214b1c6cf9ad3e254ff0a001cdfdbc0fc76613c39b283ea9dad
  ; _25._tcp.mx           IN  TLSA          3 1 1 982b6e10f7fe26ad78ef425d665ac640b85cccf6a68597a8d8f272cf8bc682a9

  ;; MTA-STS
  ; _mta-sts              IN  TXT           "v=STSv1; id=20251130T201625;"
  ; mta-sts               IN  AAAA          ${config.az.cluster.core.mailserver.prefix}::
  ; mta-sts               IN  A             ${config.az.cluster.meta.vps."ns2".ipv4}

  ;; autoconfig
  ; _imaps._tcp           IN  SRV           0 1 993 mx
  ; _submissions._tcp     IN  SRV           0 1 465 mx
  ;;; explicitly unavailable
  ; _imap._tcp            IN  SRV           0 0 0 .
  ; _submission._tcp      IN  SRV           0 0 0 .
  ; _pop3._tcp            IN  SRV           0 0 0 .
  ; _pop3s._tcp           IN  SRV           0 0 0 .
  ;;; vendor-specific autoconf
  ; _autodiscover._tcp    IN  SRV           0 1 443 autoconfig
  ; autoconfig            IN  CNAME         mx

  ;; outgoing addrs
  mx1                   IN  AAAA          ${config.az.cluster.core.mailserver.prefix}::1


  ; Mail stuff - zoho mail
  @                     IN  MX            10 mx.zoho.eu.
  @                     IN  MX            20 mx2.zoho.eu.
  @                     IN  MX            50 mx3.zoho.eu.
  @                     IN  TXT           "v=spf1 include:zohomail.eu ~all"
  zmail._domainkey      IN  TXT           "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDgZkWdSVdUKYTOUtkNi6m02ho5Z8bkmSrGPd+4qjHrM992yZjuM4ViHVQ9RPYTGzjoV6ctt0YTm+jd+mWsRc9JWgJGIhwcr35tiVPFdj3aQQwFvZEoh1akPOlL3kUUTGJEw4o26bKhJnYkI9wZN9608sGoX3wv/Dw3YR02cabKLwIDAQAB"
''
