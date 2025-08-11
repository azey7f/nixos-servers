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
  };

  config = mkIf cfg.enable {
    az.server.rke2.manifests."app-woodpecker" = [
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "woodpecker";
          namespace = "kube-system";
        };
        spec = {
          targetNamespace = "app-woodpecker";
          createNamespace = true;

          chart = "oci://ghcr.io/woodpecker-ci/helm/woodpecker";
          version = "3.2.1";

          valuesContent = let
            podSecurityContext = {fsGroup = 65532;};
            securityContext = {
              privileged = false;
              allowPrivilegeEscalation = false;
              capabilities.drop = ["ALL"];
              runAsUser = 65532;
              runAsGroup = 65532;
              runAsNonRoot = true;
              fsGroup = 65532;
              seccompProfile.type = "RuntimeDefault";
            };
          in
            builtins.toJSON {
              agent = {
                replicaCount = 1;

                inherit securityContext podSecurityContext;
                env = {
                  WOODPECKER_BACKEND_K8S_NAMESPACE = "kube-system"; # CRITICAL TODO: https://github.com/woodpecker-ci/woodpecker/issues/4975
                  WOODPECKER_AGENT_SECRET = config.sops.placeholder."rke2/woodpecker/agent-secret";
                };
              };

              server = {
                inherit securityContext podSecurityContext;
                env = {
                  WOODPECKER_OPEN = true;
                  WOODPECKER_HOST = "https://woodpecker.${domain}";
                  WOODPECKER_AGENT_SECRET = config.sops.placeholder."rke2/woodpecker/agent-secret";
                  WOODPECKER_ADMIN = ""; # admin accounts aren't really necessary

                  WOODPECKER_FORGEJO = true;
                  WOODPECKER_FORGEJO_URL = "https://git.${domain}";
                  # oauth2 client, callback URL https://woodpecker.<domain>/authorize
                  WOODPECKER_FORGEJO_CLIENT = config.sops.placeholder."rke2/woodpecker/forgejo-id";
                  WOODPECKER_FORGEJO_SECRET = config.sops.placeholder."rke2/woodpecker/forgejo-secret";

                  WOODPECKER_AUTHENTICATE_PUBLIC_REPOS = true;
                };
              };
            };
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
