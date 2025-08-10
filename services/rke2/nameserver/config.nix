# knot uses a special yaml-like format, so (pkgs.formats.yaml {}).generate doesn't work
{
  id,
  domain,
  zonefile,
  secondaryServers,
  acmeTsig,
  ...
}: {
  config,
  lib,
  azLib,
  ...
}: let
  cfg = config.az.svc.rke2.nameserver;
  identity = "master-ns.${domain}";

  optionalStr = pred: str:
    if pred
    then str
    else "";

  hasSecondaries = (builtins.length secondaryServers) != 0;
in ''
  ${optionalStr acmeTsig ''
    key:
      - id: acme
        algorithm: hmac-sha256
        secret: ${config.sops.placeholder."rke2/nameserver/${id}/tsig-secret"}
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
  ${lib.strings.concatImapStringsSep "\n" (i: remote: ''
        - id: "ns${toString i}"
          address: "${
        remote.ipv4
        /*
        #TODO: .ipv6
        */
      }@853"
          cert-key: ${remote.knotPubkey}
          quic: "on"
      # <- indent here, nix
    '')
    secondaryServers}

  acl:
  ${optionalStr hasSecondaries ''
      - id: "allow-secondary"
        cert-key: [ ${lib.strings.concatMapStringsSep ", " (remote: ''"${remote.knotPubkey}"'') secondaryServers} ]
        action: [ "transfer", "notify" ]
    # <- indent here, nix
  ''}
  ${optionalStr acmeTsig ''
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

  zone:
    - domain: "${domain}"
      file: "/config/${zonefile}.zone"${{
      # TODO: jesus this is such an ugly solution
      "00" = "";
      "10" = "\n    acl: [ \"allow-secondary\" ]";
      "01" = "\n    acl: [ \"acme\" ]";
      "11" = "\n    acl: [ \"allow-secondary\", \"acme\" ]";
    }."${
      if hasSecondaries
      then "1"
      else "0"
    }${
      if acmeTsig
      then "1"
      else "0"
    }"}
  ${optionalStr hasSecondaries ''
        notify: [ ${lib.strings.concatImapStringsSep ", " (i: _: ''"ns${toString i}"'') secondaryServers} ]
    # <- indent here, nix
  ''}
''
