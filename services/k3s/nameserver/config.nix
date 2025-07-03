# knot uses a special yaml-like format, so (pkgs.formats.yaml {}).generate doesn't work
{
  config,
  lib,
  azLib,
  ...
}: let
  cfg = config.az.svc.k3s.nameserver;
  identity = "master-ns.${cfg.domain}";
in ''
  include: "/secrets/acme.conf"

  server:
    identity: "${identity}"
    listen: "::@53"
    listen-quic: "::@853"
    nsid: "${identity}"
    version: "KnotDNS"
    tcp-io-timeout: "100"

  remote:
  ${lib.strings.concatImapStringsSep "\n" (i: remote: ''
        - id: "ns${toString i}"
          address: "${remote.ipv6}@853"
          cert-key: ${remote.knotPubkey}
      # <- indent here, nix
    '')
    cfg.secondaryServers}

  acl:
    - id: "allow-secondary"
      cert-key: [ ${lib.strings.concatMapStringsSep ", " (remote: ''"${remote.knotPubkey}"'') cfg.secondaryServers} ]
      action: [ "transfer", "notify" ]
    - id: "acme"
      key: "acme"
      action: "update"
      update-type: "TXT"
      update-owner: "name"
      update-owner-match: "equal"
      update-owner-name: "_acme-challenge"

  policy:
    - id: "ecc"
      algorithm: "ed25519"
      reproducible-signing: "on"
      nsec3: "on"

  mod-rrl:
    - id: "default"
      rate-limit: "1000"
      slip: "2"

  template:
    - id: "default"
      global-module: "mod-rrl/default"
      journal-content: "all"
      zonefile-sync: "-1"
      zonefile-load: "difference-no-serial"
      dnssec-signing: "on"
      dnssec-signing: "ecc"
      serial-policy: "dateserial"

  zone:
    - domain: "${cfg.domain}"
      file: "/config/${azLib.reverseFQDN cfg.domain}.zone"
      notify: [ ${lib.strings.concatImapStringsSep ", " (i: _: ''"ns${toString i}"'') cfg.secondaryServers} ]
      acl: [ "allow-secondary", "acme" ]
''
