Welcome! This is the NixOS flake defining most of the infrastructure hosting https://azey.net & subdomains :3

Everything is hosted on an RKE2 cluster and *fully* defined in Nix; all images and helm charts are fetched using `docker.pullImage`, and the whole cluster is running as if it was airgapped[^1] (except for services which explicitly need internet access, like [searxng](https://search.azey.net)).  Everything is also automatically updated through renovate (including nix hashes! just don't look at the .renovaterc script, it's a mess...)

In addition to just being for selfhosting services, my end goal for this is to be pretty much a fully offline-ready infrastructure that doesn't rely on the internet for anything but updating itself (& interop, obviously I still need stuff like CA-approved certs for the public TLS proxy[^2]). Thanks to the power of Nix *everything* is built & cached via CI into a local cache, which means that theoretically it should be possible to install new systems, create configs & generally do everything except for downloading brand new software/updates fully offline.

See [the core flake](https://git.azey.net/infra/nixos-core) for the general structure, this is the non-standard stuff:
- `cluster/`: `az.cluster` defs, options to be set cluster-wide
- `hosts/`: instead of each dir being a host, each dir is a cluster with a `nodes/` subdir
- `sops/`: a private submodule with all the secrets, passwords, etc, decryptable with a machine-local `age.key` (also stored in bitwarden for backup reasons)
    - not mirrored to codeberg, but most of these are just randomly-generated secrets anyways

The core infra is IPv6-only routed through a wireguard tunnel (courtesy of [as200242](https://as200242.net)!), but I also have [a VPS](https://git.azey.net/infra/nixos-vps) for the domain's secondary nameserver, [uptime page](https://status.azey.net) and a [mirror of the root site](https://v4.azey.net) on legacy IP[^3] for the people with ISPs still stuck in the 90s.

Network layout:
- `2a14:6f44:5608::/48` - public prefix
  - `:0000::/52` - k8s clusters
    - `:000::/56` - primary.k8s.azey.net
      - `:00::/64` - reserved static IPs & ExternalIPs for gateways
        - `::1` - envoy gateway
        - `::53` - knot.app-nameserver.svc, aka ns1.azey.net
        - `::ffff` - k8s apiserver VIP
        - `:25::/72` - mail servers - collectively exposed as mx.azey.net
          - `:25::` itself is used for the k8s service, `:25::1` and up for individual pods
      - `:01::/64` - pods CIDR
      - `:02::/64` - services CIDR (though only the first /112 of that is actually used because RKE2)
      - `:f0::/60` - node addrs, really a /64 but reserved as /60 for possible future routing shenanigans
        - `:f0::1` - astra
  - `:1000::/52` - misc personal devices - desktops/laptops/etc
- `fd33:7b36:fc28::/48` - ULA prefix routed through mullvad
  - uses same addressing scheme as public prefix, though only the /64 pod CIDRs are actually used
- `2a01:4f9:c012:dc23::1/64` - ns2.azey.net, also hosts the legacy mirror + status page & proxies IPv4 mail

### Guides for future me:

Setting up a new server:
1. add an entry to the relevant `hosts/` dir
2. create dir in `hosts/*/nodes/`, note that `domain` and `hostName` are defined automatically
3. generate a new `age.key`, re-encrypt all the stuff in `sops/`
4. done!

Setting up a domain:
1. configure stuff in the relevant `hosts/` dir
2. if selfhosting the nameservers:
    - if <2 nodes with separate public IPs, set up VPSes (see [nixos-vps](https://git.azey.net/infra/nixos-vps)) & add entries to `clusters.nix`
        - `exec` into the pod & run `knotc status cert-key` for the primary's pubkey
    - set up glue & DS records with the registrar, `exec` into the pod and run `keymgr <zone> ds` for the DS stuff
3. done!

Setting up cluster from scratch:
1. enable nothing but the `az.server.rke2` modules & `az.svc.nameserver`
2. wait for nameserver to come online, follow `Setting up a domain` step 2
3. enable `svc.envoyGateway` & `svc.lldap`, login to [lldap](https://lldap.azey.net) using the init-passwd, then:
    - create `lldap-admin` account with `lldap_admin` group
    - delete default `admin` account
    - create `authelia` account with `lldap_password_manager` group
    - create `admin` group, user account(s)
4. enable `svc.mail` & `svc.authelia`, setup 2FA (at time of writing mail doesn't work, `exec` into pod and `cat /tmp/notifier`)
5. enable everything else as needed, manual steps for specific services:
    - forgejo: temporarily modify `gitea.admin` & enable internal auth in the chart's `valuesContent`, delete account when done with setup
      - OIDC: additional scopes `email profile groups`, auto-discovery URL `https://auth.azey.net/.well-known/openid-configuration`
    - navidrome: no default auth, IMMEDIATELY connect & create admin user
    - woodpecker: create `Integrations > Applications` in forgejo (`https://woodpecker.azey.net/authorize`), modify sops secrets
      - create `woodpecker-ci` user in forgejo & add as collaborator to repos
      - `REMOTE_URL` secrets in woodpecker: `https://woodpecker-ci:<passwd>@git.azey.net/<repo>`, available for `appleboy/drone-git-push`
      - create `daily` cron in each repo
    - grafana: delete default admin user
    - renovate bot: create user (restricted account), add as collaborator
      - login & create personal token in `Applications`, put into sops - just the password might also work
    - attic:
      - client: `attic login az https://attic.azey.net <token> && attic cache create main --upstream-cache-key-name "" --public --priority 1000`
        - the cache is public so feel free to use it if you want, just be aware that at time of writing my upload is like 10mbps, so... yeah
      - server: `kubectl exec -n app-attic attic-0 -- /bin/sh -c 'atticadm -f /config/config.toml make-token --pull main --push main --validity 100y --sub woodpecker-ci'`
        - add to woodpecker as `ATTIC_TOKEN`
    - jellyfin: enable `legacyIP` for the media namespace, run the initial setup & enable IPv6
    - files: first access sets admin OIDC username, all users also have to be created manually - note that / means actual root, use /srv

[^1]: See `config/rke2/default.nix`, but the TLDR is that it's possible to use the RKE2 [embedded registry](https://docs.rke2.io/install/registry_mirror) to completely disable pulling any images and rely on those preinstalled on the node(s). Runtime airgappiness is handled with network policies.
[^2]: In this example specifically I mean *only* for the public proxy, at time of writing this isn't implemented yet but eventually I'd like to run a local step-ca instance for local network connections
[^3]: version four of the Internet Protocol as defined in RFC 791 (three digit RFC! and we're still using it in $YEAR).
