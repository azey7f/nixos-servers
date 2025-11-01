# knot uses a special yaml-*like* format, so (pkgs.formats.yaml {}).generate doesn't work
{
  zones,
  secondaryServers,
  acmeTsig,
  ...
}: {
  config,
  lib,
  azLib,
  ...
}: let
  identity = "ns.${config.networking.fqdn}";

  hasSecondaries = secondaryServers != {};
in ''
  ${lib.optionalString acmeTsig ''
    key:
      - id: acme
        algorithm: hmac-sha256
        secret: ${config.sops.placeholder."rke2/nameserver/tsig-secret"}
  ''}

  server:
    identity: "${identity}"
    listen: "0.0.0.0@53"
    listen: "::@53"
    listen-quic: "0.0.0.0@853"
    listen-quic: "::@853"
    nsid: "${identity}"
    version: "KnotDNS"
    tcp-io-timeout: "100"

  remote:
  ${lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: remote: ''
        - id: "${name}"
          address: "${remote.ip}@853"
          cert-key: ${remote.knotPubkey}
          quic: "on"
      # <- indent here, nix
    '')
    secondaryServers
  )}

  ${lib.optionalString (hasSecondaries || acmeTsig) "acl:"}
  ${lib.optionalString hasSecondaries ''
      - id: "allow-secondary"
        cert-key: [ ${lib.concatMapStringsSep ", " (remote: ''"${remote.knotPubkey}"'') (builtins.attrValues secondaryServers)} ]
        action: [ "transfer", "notify" ]
    # <- indent here, nix
  ''}
  ${lib.optionalString acmeTsig ''
    - id: "acme"
      key: "acme"
      action: "update"
      update-type: "TXT"
      update-owner: "name"
      update-owner-match: "equal"
      update-owner-name: "_acme-challenge"
    # <- indent here, nix
  ''}

  policy:
    - id: "ecc"
      algorithm: "ed25519"
      reproducible-signing: "on"
      nsec3: "on"
      nsec3-salt-length: "0"

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
      dnssec-policy: "ecc"
      serial-policy: "dateserial"

  ${lib.concatMapStringsSep "\n" (zone: ''
      zone:
        - domain: "${zone}"
          file: "/config/${zone}.zone"
      ${
        let
          acl =
            lib.optional hasSecondaries ''"allow-secondary"''
            ++ lib.optional acmeTsig ''"acme"'';
        in
          lib.optionalString (hasSecondaries || acmeTsig)
          "    acl: [ ${lib.concatStringsSep ", " acl} ]"
      }
      ${lib.optionalString hasSecondaries ''
            notify: [ ${lib.concatMapStringsSep ", " (name: ''"${name}"'') (builtins.attrNames secondaryServers)} ]
        # <- indent here, nix
      ''}
    '')
    zones}
''
