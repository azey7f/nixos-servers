{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.woodpecker;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.woodpecker = with azLib.opt; {
    enable = optBool false;
    agentCount = mkOpt types.ints.positive 4;
  };

  config = mkIf cfg.enable {
    az.server.rke2.namespaces."app-woodpecker".networkPolicy = {
      fromNamespaces = ["envoy-gateway"];
      toDomains = ["git.${domain}"];
      extraEgress = [{toEntities = ["kube-apiserver"];}];
    };
    az.server.rke2.namespaces."app-forgejo".networkPolicy.toDomains = ["woodpecker.${domain}"]; # push events

    az.server.rke2.namespaces."app-woodpecker-steps" = {
      podSecurity = "baseline"; # TODO: there doesn't seem to be any way to set securityContext for steps
      networkPolicy.toDomains = ["git.${domain}"];
      networkPolicy.toWAN = true; # nix flake updates
    };

    az.server.rke2.images = {
      # pipeline images
      woodpecker-ci-plugin-git = {
        imageName = "woodpeckerci/plugin-git";
        finalImageTag = "2.7.0";
        imageDigest = "sha256:1ce87890a4996596c0f6c28f69afe5e07bf106c294f49fb2cfe5971b4a04f70c";
        hash = "sha256-mB2kjbvIQZFb/FvbySaQ1bs4Zd30MSGJBDdqlugbFcY="; # renovate: woodpeckerci/plugin-git 2.7.0
      };
      nixos-nix = {
        imageName = "nixos/nix";
        finalImageTag = "2.32.0";
        imageDigest = "sha256:a3b5d472ca187c25c87a217bc730cdf7a3df7d07ee09eb37f5bc8c874f173a52";
        hash = "sha256-RXZj3q+VSEFDhdahJGYMzgOUXxk6zDgNB7NxqoWQe5g="; # renovate: nixos/nix 2.32.0
      };
      appleboy-drone-git-push = {
        imageName = "appleboy/drone-git-push";
        finalImageTag = "1.1.1";
        imageDigest = "sha256:1c998f23bbbce2ed57ca75c2cebc695eee203d2e18eacf91a5ff64068337a6d9";
        hash = "sha256-G4pHxMGpVwnwxXlGEPTSMNF0GjWR3Nb/D4a2/4hwe0M="; # renovate: appleboy/drone-git-push 1.1.1
      };
    };
    services.rke2.autoDeployCharts."woodpecker" = {
      repo = "oci://ghcr.io/woodpecker-ci/helm/woodpecker";
      version = "3.4.0";
      hash = "sha256-9W7pxyxBg3XczMn+BJqa2FNXF2XdsMpO7yYXKAiPWOk="; # renovate: ghcr.io/woodpecker-ci/helm/woodpecker 3.4.0

      targetNamespace = "app-woodpecker";
      values = let
        podSecurityContext = {fsGroup = 65534;};
        securityContext = {
          privileged = false;
          allowPrivilegeEscalation = false;
          capabilities.drop = ["ALL"];
          runAsUser = 65534;
          runAsGroup = 65534;
          runAsNonRoot = true;
          fsGroup = 65534;
          seccompProfile.type = "RuntimeDefault";
        };
      in {
        agent = {
          replicaCount = cfg.agentCount;

          inherit securityContext podSecurityContext;
          env.WOODPECKER_BACKEND_K8S_NAMESPACE = "app-woodpecker-steps";
          extraSecretNamesForEnvFrom = ["agent-env"];
        };

        server = {
          inherit securityContext podSecurityContext;
          env = {
            WOODPECKER_OPEN = "true";
            WOODPECKER_HOST = "https://woodpecker.${domain}";
            WOODPECKER_ADMIN = ""; # admin accounts aren't really necessary

            WOODPECKER_FORGEJO = "true";
            WOODPECKER_FORGEJO_URL = "https://git.${domain}";

            WOODPECKER_AUTHENTICATE_PUBLIC_REPOS = "true";

            WOODPECKER_MAX_PIPELINE_TIMEOUT = "10000"; # just under a week... even full nixos system builds shouldn't take that long, right?
            WOODPECKER_DEFAULT_MAX_PIPELINE_TIMEOUT = "10000";
          };
          extraSecretNamesForEnvFrom = ["server-env"];
        };
      };
    };
    az.server.rke2.secrets = [
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "agent-env";
          namespace = "app-woodpecker";
        };
        stringData = {
          WOODPECKER_AGENT_SECRET = config.sops.placeholder."rke2/woodpecker/agent-secret";
        };
      }
      {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "server-env";
          namespace = "app-woodpecker";
        };
        stringData = {
          WOODPECKER_AGENT_SECRET = config.sops.placeholder."rke2/woodpecker/agent-secret";
          # oauth2 client, callback URL https://woodpecker.<domain>/authorize
          WOODPECKER_FORGEJO_CLIENT = config.sops.placeholder."rke2/woodpecker/forgejo-id";
          WOODPECKER_FORGEJO_SECRET = config.sops.placeholder."rke2/woodpecker/forgejo-secret";
        };
      }
    ];

    az.svc.rke2.envoyGateway.httpRoutes = [
      {
        name = "woodpecker";
        namespace = "app-woodpecker";
        hostnames = ["woodpecker.${domain}"];
        rules = [
          {
            backendRefs = [
              {
                name = "woodpecker-server";
                port = 80;
              }
            ];
          }
        ];
      }
    ];

    az.svc.rke2.authelia.rules = [
      {
        domain = ["woodpecker.${domain}"];
        policy = "bypass";
      }
    ];

    az.server.rke2.clusterWideSecrets."rke2/woodpecker/forgejo-id" = {};
    az.server.rke2.clusterWideSecrets."rke2/woodpecker/forgejo-secret" = {};
    az.server.rke2.clusterWideSecrets."rke2/woodpecker/agent-secret" = {};
  };
}
