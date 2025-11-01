domain: {
  config,
  lib,
  ...
}: let
  pgpPubkey = "mDMEZ/1EchYJKwYBBAHaRw8BAQdAqV4yxw+9cXHvJeK037MNrwnqUNhsBnptvFAXmymSCxS0EmF6ZXkgPG1lQGF6ZXkubmV0PoiZBBMWCgBBFiEELMs0A0P+iiuRzn91+U9KccXCHo8FAmf9RHICGwMFCQWjmoAFCwkIBwICIgIGFQoJCAsCBBYCAwECHgcCF4AACgkQ+U9KccXCHo/m2wEAhYbrg5+fa6ZQT3dOjaSxp9rGJAZnSNPBZfHsda2CHDABAPxFZ9VciZ1FRGscGAHYwUX3N9FQZk4kiwWQmzqFPRMCuDgEZ/1EchIKKwYBBAGXVQEFAQEHQMGURGFScsMEkgYpKnN6cAxFDT1bPrtsgXrTBvlILG9MAwEIB4h+BBgWCgAmFiEELMs0A0P+iiuRzn91+U9KccXCHo8FAmf9RHICGwwFCQWjmoAACgkQ+U9KccXCHo+dngEAoF4P7ovWPrIN/E3bmxWRAEvQ5tw1qUm8K49Dvx8UOLIBAPiHqMUYZtya/Umdh2MK15iotuP+7BiC/70kq6cF8YQO";

  gateway = config.az.cluster.core.envoyGateway.address;
in ''
  $TTL 3600
  $ORIGIN azey.net.

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
  _discord              IN  TXT           dh=8e02c1081c96fd004473289694bf381e590c750b

  ; SSH - # TODO?
  ;@                    IN  SSHFP         1 1 BA6B9A49143417A3AEF2F1757C1DAC0029271105
  ;@                    IN  SSHFP         1 2 C5B2FFBD7B5FFB44A97E541B72E2324EBAD474E828C0441445427B02A71663CD
  ;@                    IN  SSHFP         4 1 10F4803601771CE8E21A220B4A83553C1170DAF2
  ;@                    IN  SSHFP         4 2 DCDB72D050EC403BF7136BBCCF0AB5F55EACB01755D9ABE1E7689405E35F799E

  ; Mail stuff - zoho mail
  @                      IN  MX            10 mx.zoho.eu.
  @                      IN  MX            20 mx2.zoho.eu.
  @                      IN  MX            50 mx3.zoho.eu.
  @                      IN  TXT           "v=spf1 include:zohomail.eu ~all"
  zmail._domainkey       IN  TXT           "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDgZkWdSVdUKYTOUtkNi6m02ho5Z8bkmSrGPd+4qjHrM992yZjuM4ViHVQ9RPYTGzjoV6ctt0YTm+jd+mWsRc9JWgJGIhwcr35tiVPFdj3aQQwFvZEoh1akPOlL3kUUTGJEw4o26bKhJnYkI9wZN9608sGoX3wv/Dw3YR02cabKLwIDAQAB"
''
