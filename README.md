Welcome! This is the NixOS flake defining most of the infrastructure hosting https://azey.net & subdomains :3

Everything is hosted on an RKE2 cluster and *fully* defined in Nix;[^1] the K8s manifests are implemented using a combination of sops-nix templates and systemd-tmpfiles, see `config/rke2/manifests.nix`. At time of writing I only have one node and it's behind CGNAT, so everything is proxied through [one of two VPSes](https://git.azey.net/infra/nixos-vps) which also host the domain's public-facing nameservers & [uptime page](https://status.azey.net).

See [the core flake](https://git.azey.net/infra/nixos-core) for the general structure, this is the non-standard stuff:
- `sops/`: a private submodule with all the secrets, passwords, etc, decryptable with a machine-local `age.key` (also stored in bitwarden for backup reasons)
    - not mirrored to codeberg, but most of these are just randomly-generated secrets anyways
- `utils/`: random collection of useful shell scripts
- `infra.nix`: defines domains hosted by this flake, associated RKE2 clusters, VPSes, which servers belong to what, etc. See comment at top of the file for more info.

### Guides for future me:

Setting up a new server:
1. add an entry to `infra.nix`
2. create dir in `hosts/`, note that `domain` and `hostName` are defined automatically
3. generate a new `age.key`, re-encrypt all the stuff in `sops/`
4. done!

Setting up a domain:
1. add an entry to `infra.nix`, incl. at least one cluster & node
2. if selfhosting the nameservers:
    - if <2 nodes with separate public IPs, set up VPSes (see [nixos-vps](https://git.azey.net/infra/nixos-vps)) & add entries to `infra.nix`
        - `exec` into the pod & run `knotc status cert-key` for the primary's pubkey
    - set up glue & DS records with the registar, `exec` into the pod and run `keymgr <zone> ds` for the DS stuff
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

[^1]: I specifically used a semicolon instead of an en dash because I didn't want people to think I used an LLM. what has the world come to
