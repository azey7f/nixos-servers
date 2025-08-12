{domain, ...}: {
  config,
  lib,
  outputs,
  ...
}: let
  optionalStr = pred: str:
    if pred
    then str
    else "";

  gateways = {
    external = {
      inherit (config.az.svc.rke2.envoyGateway.gateways.external.addresses) ipv4 ipv6;
    };
    internal = {
      inherit (config.az.svc.rke2.envoyGateway.gateways.internal.addresses) ipv4 ipv6;
    };
  };
in ''
  $TTL 3600
  $ORIGIN ${domain}.

  ; zone metadata
  @            IN  SOA           ns1 domain-admin (
                                 0000000000 ; serial number - later overridden by knot
                                 900        ; refresh
                                 300        ; update retry
                                 604800     ; expiry
                                 900        ; minimum
                                 )

  @            IN  NS            ns1

  ns1          IN  A             ${gateways.external.ipv4}
  ns1          IN  AAAA          ${gateways.external.ipv6}

  @            IN  A             ${gateways.internal.ipv4}
  @            IN  AAAA          ${gateways.internal.ipv6}
  *            IN  A             ${gateways.internal.ipv4}
  *            IN  AAAA          ${gateways.internal.ipv6}

  ${optionalStr config.az.svc.rke2.resolver.enable ''
    _dns.dns     IN  SVCB          2 dns alpn=dot
    _dns.dns     IN  SVCB          1 dns alpn=h2,h3 dohpath=/dns-query{?dns}
  ''}
''
