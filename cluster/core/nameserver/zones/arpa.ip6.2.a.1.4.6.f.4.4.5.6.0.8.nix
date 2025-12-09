domain: {
  config,
  lib,
  ...
}: ''
  $TTL 3600
  $ORIGIN ${domain}.

  ; zone metadata
  @                     IN  SOA           ns1.azey.net. domain-admin.azey.net. (
                                          0000000000 ; serial number - later overridden by knot
                                          900        ; refresh
                                          300        ; update retry
                                          604800     ; expiry
                                          900        ; minimum
                                          )

  @                     IN  NS            ns1.azey.net.
  @                     IN  NS            ns2.azey.net.

  ; misc
  _discord              IN  TXT           dh=78652b928789fa5a52c6a8a3b1b6af804c7033b0

  ; static IPs
  1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0    IN  PTR    azey.net.
  3.5.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0    IN  PTR    ns1.azey.net.
  0.0.0.0.0.0.0.0.0.0.0.0.5.2.0.0.0.0.0.0    IN  PTR    mx.azey.net.

  ; outgoing mail
  1.0.0.0.0.0.0.0.0.0.0.0.5.2.0.0.0.0.0.0    IN  PTR    mx1.azey.net.
''
