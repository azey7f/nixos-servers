{
  lib,
  outputs,
  ...
}: let
  domain = "azey.net";
  optionalStr = pred: str:
    if pred
    then str
    else "";

  pgpPubkey = "mDMEZ/1EchYJKwYBBAHaRw8BAQdAqV4yxw+9cXHvJeK037MNrwnqUNhsBnptvFAXmymSCxS0EmF6ZXkgPG1lQGF6ZXkubmV0PoiZBBMWCgBBFiEELMs0A0P+iiuRzn91+U9KccXCHo8FAmf9RHICGwMFCQWjmoAFCwkIBwICIgIGFQoJCAsCBBYCAwECHgcCF4AACgkQ+U9KccXCHo/m2wEAhYbrg5+fa6ZQT3dOjaSxp9rGJAZnSNPBZfHsda2CHDABAPxFZ9VciZ1FRGscGAHYwUX3N9FQZk4kiwWQmzqFPRMCuDgEZ/1EchIKKwYBBAGXVQEFAQEHQMGURGFScsMEkgYpKnN6cAxFDT1bPrtsgXrTBvlILG9MAwEIB4h+BBgWCgAmFiEELMs0A0P+iiuRzn91+U9KccXCHo8FAmf9RHICGwwFCQWjmoAACgkQ+U9KccXCHo+dngEAoF4P7ovWPrIN/E3bmxWRAEvQ5tw1qUm8K49Dvx8UOLIBAPiHqMUYZtya/Umdh2MK15iotuP+7BiC/70kq6cF8YQO";
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

  ; vps
  ${lib.strings.concatImapStrings (i: addr: ''
      @                   IN  AAAA          ${addr.ipv6}
      *                   IN  AAAA          ${addr.ipv6}
      ns${toString i}     IN  AAAA          ${addr.ipv6}
      ${optionalStr (addr ? ipv4) ''
        @                   IN  A             ${addr.ipv4}
        *                   IN  A             ${addr.ipv4}
        ns${toString i}     IN  A             ${addr.ipv4}
      ''}
      _dns.ns${toString i}          IN  SVCB          2 ns${toString i} alpn=dot
      ;_dns.ns${toString i}          IN  SVCB          1 ns${toString i} alpn=h2,h3 dohpath=/dns-query{?dns}
    '')
    outputs.infra.domains.${domain}.vps}

  ; CAA
  @                     IN  CAA           0 contactemail "me@${domain}"
  *                     IN  CAA           0 contactemail "me@${domain}"
  @                     IN  CAA           0 iodef "mailto:domain-admin@${domain}"
  *                     IN  CAA           0 iodef "mailto:domain-admin@${domain}"
  @                     IN  CAA           0 issue "letsencrypt.org"
  *                     IN  CAA           0 issue "letsencrypt.org"

  ; PGP keys
  ; gpg --auto-key-locate clear,nodefault,cert,dane --locate-keys me@azey.net
  me                                                                     IN   CERT         PGP 0 0 ${pgpPubkey}
  2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc._openpgpkey   IN   OPENPGPKEY   ${pgpPubkey}

  ; TLSA
  ;_443._tcp             IN  TLSA          3 1 1 ''${TLSA}
  ;_25._tcp.mail         IN  TLSA          3 1 1 ''${TLSA}
  ;_465._tcp.mail        IN  TLSA          3 1 1 ''${TLSA}
  ;_993._tcp.mail        IN  TLSA          3 1 1 ''${TLSA}

  ; SSH - # TODO
  ;@                    IN  SSHFP         1 1 BA6B9A49143417A3AEF2F1757C1DAC0029271105
  ;@                    IN  SSHFP         1 2 C5B2FFBD7B5FFB44A97E541B72E2324EBAD474E828C0441445427B02A71663CD
  ;@                    IN  SSHFP         4 1 10F4803601771CE8E21A220B4A83553C1170DAF2
  ;@                    IN  SSHFP         4 2 DCDB72D050EC403BF7136BBCCF0AB5F55EACB01755D9ABE1E7689405E35F799E

  ; DAV
  ;_caldav._tcp          IN  SRV           0 0 0 .
  ;_caldavs._tcp         IN  TXT           "path=/dav"
  ;_caldavs._tcp         IN  SRV           0 1 443 dav
  ;_carddav._tcp         IN  SRV           0 0 0 .
  ;_carddavs._tcp        IN  TXT           "path=/dav"
  ;_carddavs._tcp        IN  SRV           0 1 443 dav

  ; Mail stuff - zoho mail
  @                      IN  MX            10 mx.zoho.eu.
  @                      IN  MX            20 mx2.zoho.eu.
  @                      IN  MX            50 mx3.zoho.eu.
  @                      IN  TXT           "v=spf1 include:zohomail.eu ~all"
  zmail._domainkey       IN  TXT           "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDgZkWdSVdUKYTOUtkNi6m02ho5Z8bkmSrGPd+4qjHrM992yZjuM4ViHVQ9RPYTGzjoV6ctt0YTm+jd+mWsRc9JWgJGIhwcr35tiVPFdj3aQQwFvZEoh1akPOlL3kUUTGJEw4o26bKhJnYkI9wZN9608sGoX3wv/Dw3YR02cabKLwIDAQAB"

  ; Mail stuff
  ;@                     IN  HTTPS         1 . alpn=h2,h3
  ;@                     IN  MX            10 mail
  ;@                     IN  TXT           "v=spf1 {spfAddrs} ~all"
  ;*                     IN  HTTPS         1 . alpn=h2,h3
  ;*                     IN  TXT           "v=spf1 {spfAddrs} -all"
  ;_dmarc                IN  TXT           "v=DMARC1;p=reject;rua=mailto:dmarc-reports@${domain}!10m"
  ;2024a._domainkey      IN  TXT           "v=DKIM1;h=sha256;k=ed25519;p=M0Gvhf9JeT9QqnlSY492QWKqwOv9MXEfCbXL1n9owoI="
  ;2024b._domainkey      IN  TXT           "v=DKIM1;h=sha256;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1AYaoSc3XRiUNZgNvZeAZT43KbT0NMuKWtVQI/EC83d144OxcEvtOXreGM/s4IHkOpNEv1HFPvr1WioWUTDN6/hNQTNABeOKOcSfeYyaCaAsoPLz9jVaiwfjqAO5OgiQ+JpmyrQiKpQCws27ww//pshMGpzZlncLaUBZuedtsDQwRPmg1RRBOeCS2+9M08+fLeakzkhAJXQW8XXLhGDTvQC7rzTZuZoaX/JvaXBDidaU4QrMajyuMRnmWb5j4DvZKSirHURKH+dw2B9A+7Kr3LgKpU50591q8C8bBhTrSihu5JyJ/k8kwM457W/xT2QDaSxtt/YO5XkL9qcY3gyltwIDAQAB"
  ;2024c._domainkey      IN  TXT           "v=DKIM1;h=sha256;k=ed25519;p=TuL5zLOo7jvY/whF1JLCHVQiocD8mMoZmEGFHLrAgmk="
  ;2024d._domainkey      IN  TXT           "v=DKIM1;h=sha256;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3AqwiCCQujRTjtBAoWCfwIFDPH8ZM6SxQPvKdiKq6hS48Sddtdk+6dS2PkDcfNx8NHrGN4mzOsdusr/TZ95SjT23CsP8cOUW8EDXhkXyux/RKJEoE5M4sNFW8FxM2vekm16GdUb9UIt7d8cOUJ8qrAUnRgpUgLo0WX3tes6YLyKIfhNilTB9nRiu0irooYZeFx5/sqwyzgXtPV+//rLiMlW24PUhv0PLE1GeQGCGWpe3fF3lFnswerR2gk4AUzCWxXV/C+zUvQVzEwBxMByqITvzrzeFlVHD7uTehEcx1+1u0xmQVtg/1lyHvySBED2FedxaTNI9YB91awuhpfG61QIDAQAB"
  ;_mta-sts              IN  TXT           "v=STSv1; id=20240901T000625"
  ;_autodiscover._tcp    IN  SRV           0 1 443 mail
  ;_imap._tcp            IN  SRV           0 1 143 .
  ;_imaps._tcp           IN  SRV           0 1 993 mail
  ;_pop3._tcp            IN  SRV           0 1 110 .
  ;_pop3s._tcp           IN  SRV           0 1 995 .
  ;_submission._tcp      IN  SRV           0 1 587 .
  ;_submissions._tcp     IN  SRV           0 1 465 mail
  ;_smtp._tls            IN  TXT           "v=TLSRPTv1; rua=mailto:tls-reports@${domain}"
  ;mail                  IN  TXT           "v=spf1 {spfAddrs} -all"
  ;_smtp._tls.mail       IN  TXT           "v=TLSRPTv1; rua=mailto:tls-reports@mail.${domain}"
''
