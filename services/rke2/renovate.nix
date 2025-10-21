{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.renovate;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.renovate = with azLib.opt; {
    enable = optBool false;
    schedule = optStr "0 */2 * * *"; # bi-hourly

    autoUpgrade = {
      enable = optBool true;
      gpgTrustedKey = optStr "me@${domain}";
    };
  };

  config = mkIf cfg.enable {
    az.server.rke2.namespaces."app-renovate" = {
      networkPolicy.fromNamespaces = ["envoy-gateway"];
      networkPolicy.toDomains = ["git.${domain}"];
      networkPolicy.toWAN = true;
    };

    services.rke2.autoDeployCharts."renovate" = {
      targetNamespace = "app-renovate";

      repo = "https://docs.renovatebot.com/helm-charts";
      name = "renovate";
      version = "44.15.1";
      hash = "sha256-d0YLoW8mzjLXyRrTbnUrEge88ilpc98sCgeQ03dwHSU="; # renovate: https://docs.renovatebot.com/helm-charts renovate 44.15.1

      # renovate-args: --set renovate.config=\"{}\" --set image.useFull=true
      values = {
        image.useFull = true; # include all external tools in image

        renovate.securityContext = {
          privileged = false;
          allowPrivilegeEscalation = false;
          capabilities.drop = ["ALL"];
          runAsUser = 65534;
          runAsGroup = 65534;
          runAsNonRoot = true;
          fsGroup = 65534;
          seccompProfile.type = "RuntimeDefault";
        };

        extraVolumes = builtins.map (name: {
          inherit name;
          emptyDir = {};
        }) ["home" "nix" "nonexistent"];

        extraVolumeMounts = [
          # Fatal: can't create directory '/home/ubuntu/.gnupg': Permission denied
          {
            name = "home";
            mountPath = "/home/ubuntu";
          }
          # rootless nix in postUpgradeTasks
          {
            name = "nix";
            mountPath = "/nix";
          }
          # warning: $HOME ('/nix') is not owned by you, falling back to the one defined in the 'passwd' file ('/nonexistent')
          # not stupid if it works, right?
          {
            name = "nonexistent";
            mountPath = "/nonexistent";
          }
        ];

        cronjob = {
          schedule = cfg.schedule;
          timeZone = config.az.core.locale.tz;

          # https://github.com/kubernetes/kubernetes/issues/74741
          failedJobsHistoryLimit = 0;
          successfulJobsHistoryLimit = 0;
        };

        existingSecret = "renovate-env";
        #envFrom = [{secretRef.name = "renovate-env";}];
        renovate.config = builtins.toJSON {
          platform = "forgejo";
          endpoint = "https://git.${domain}/api/v1";
          token = "{{ secrets.RENOVATE_TOKEN }}";
          gitAuthor = "renovate-bot <renovate-bot@${domain}>";
          gitPrivateKey = "{{ secrets.RENOVATE_GIT_PRIVATE_KEY }}";
          autodiscover = true; # restricted account in forgejo

          allowedCommands = [
            # too complex to be worth checking.
            "^.*$"
          ];

          # envoy-gateway causes https://codeberg.org/forgejo/forgejo/issues/1929 because it 307s any %2F URIs to /
          # TODO: make an issue about this
          branchNameStrict = true;
          branchPrefix = "renovate#";
        };
      };
    };
    az.server.rke2.secrets = [
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "renovate-env";
          namespace = "app-renovate";
        };
        stringData = {
          RENOVATE_TOKEN = config.sops.placeholder."rke2/renovate/forgejo-pat";
          RENOVATE_GITHUB_COM_TOKEN = config.sops.placeholder."rke2/renovate/github-ro-pat";
          RENOVATE_GIT_PRIVATE_KEY = config.sops.placeholder."rke2/renovate/gpg-key";
          #RENOVATE_LOG_LEVEL = "debug";
        };
      }
    ];

    az.server.rke2.clusterWideSecrets."rke2/renovate/forgejo-pat" = {};
    az.server.rke2.clusterWideSecrets."rke2/renovate/github-ro-pat" = {};
    az.server.rke2.clusterWideSecrets."rke2/renovate/gpg-key" = {};

    az.svc.cron.enable = lib.mkDefault cfg.autoUpgrade.enable;
    az.svc.cron.jobs = lib.lists.optionals cfg.autoUpgrade.enable [
      # TODO: put this in a script in the repo
      "0 4 * * *  root  ${pkgs.writeScript "system-update" ''
        #!/usr/bin/env sh
        sleep $(shuf -i 0-60 -n 1)m # random delay 0-60m
        cd /etc/nixos

        # make sure repo is clean & fetch
        if ! [ "$(git status --porcelain=v1 -b | sed 's/ \[behind [0-9]*\]//')" = "## main...origin/main" ]
        then
        	echo "dirty repo, skipping auto-update"
        	echo
        	git status
        	exit 1
        fi
        git fetch -q

        # import pubkeys
        gpg --auto-key-locate cert,dane --locate-keys ${cfg.autoUpgrade.gpgTrustedKey}
        gpg --import ${pkgs.writeText "renovate-gpg-pubkey" ''
          -----BEGIN PGP PUBLIC KEY BLOCK-----

          mDMEaKh6wBYJKwYBBAHaRw8BAQdAoHIfgeW8agi/rxFq9IfKJ5Q50u/RoiuFjnws
          ugyMPM+0JHJlbm92YXRlLWJvdCA8cmVub3ZhdGUtYm90QGF6ZXkubmV0PoiZBBMW
          CgBBFiEEhZfBIfkFS/4Q+Rt4nVdyrHTmNWgFAmioesACGwMFCQWjmoAFCwkIBwIC
          IgIGFQoJCAsCBBYCAwECHgcCF4AACgkQnVdyrHTmNWhlBQD6A+sSYaw5jIwYonBz
          U0v6E4mPW0LVrvwbHpGX/7V0BtwA/0UyA1LBwCtw+y/gzFd/IBqHOP/vTkD7AbCo
          cNRK9gACuDgEaKh6wBIKKwYBBAGXVQEFAQEHQCJkx55iltzTPjqtv/wuIH1uT1w2
          Q9khY5iyUn/Oz7MvAwEIB4h+BBgWCgAmFiEEhZfBIfkFS/4Q+Rt4nVdyrHTmNWgF
          AmioesACGwwFCQWjmoAACgkQnVdyrHTmNWhXWAEAsjMriCntruU2u4VaYyVq3ntb
          pmHgCbRO0Hal3E244IcA/3m2VNIkApZzomUBXIPbiCl8rRHOeDWmY3cNUS0KyIsJ
          =ojFq
          -----END PGP PUBLIC KEY BLOCK-----
        ''}

        # check commits against signature
        # userid doesn't seem spoofable in a way that'd make verify-commit --raw match the pattern, since newlines in it get output as \n
        echo -n "processing origin/HEAD ($(git rev-parse origin/HEAD))..."
        i=0
        while ! git verify-commit --raw origin/HEAD~$i 2>&1 | grep -q '^\[GNUPG:\] VALIDSIG 2CCB340343FE8A2B91CE7F75F94F4A71C5C21E8F '
        do
        	# if no match, check if it matches renovate's signature & commit pattern (changing strings for "version", "image" or "revision")
        	# I really can't be bothered trying to parse .renovaterc and applying it to git diff, this should be more than good enough
        	{ git verify-commit --raw origin/HEAD~$i 2>&1 | grep -q '^\[GNUPG:\] VALIDSIG 8597C121F9054BFE10F91B789D5772AC74E63568 '; } || {
        		echo -e "FAIL\nSECURITY ERROR: commit not signed by any trusted key"
        		exit 1
        	}

        	{ ! git diff origin/HEAD~$((i+1)) origin/HEAD~$i --name-status | grep -vqE '^M'; } || {
        		echo -e "FAIL\nSECURITY ERROR: signed renovate-bot commit moved/deleted/added files"
        		echo
        		git diff origin/HEAD~$((i+1)) origin/HEAD~$i --name-status
        		exit 1
        	}

        	# remove diff headers based on colors
        	#   technically it's possible to add a color ANSI code that then gets removed by the sed, but
        	#   at worst that'd cause the later nixos-rebuild to fail on eval & send a notif anyways
        	diff="$(git diff HEAD -U0 --color | grep -Pv '^\e\[1m' | grep -Pv '^\e\[36m' | sed 's/\x1b\[[0-9;]*m//g')"

        	# remove OK lines from $diff & check if it's empty
        	for name in version image imageDigest finalImageTag revision hash
        	do
        		diff="$(echo "$diff" | grep -vE "^[+|-]\s+$name\s+=\s+\"\S+\";")"
        	done

        	if [ "$diff" != "" ]
        	then
        		echo -e "FAIL\nSECURITY ERROR: signed renovate-bot commit changed something it shouldn't be allowed to"
        		echo
        		echo "$diff"
        		exit 1
        	fi

        	# commit seems safe enough, continue
        	echo "OK [renovate-bot]"
        	echo -n "processing origin/HEAD~$((++i)) ($(git rev-parse origin/HEAD~$i))..."
        done
        echo "OK [${cfg.autoUpgrade.gpgTrustedKey}]"
        echo "COMMIT CHAIN VERIFIED"

        # commits are good, pull & apply
        git pull || exit 1
        nixos-rebuild switch || exit 1
        systemctl restart rke2-server
      ''}"
    ];
  };
}
