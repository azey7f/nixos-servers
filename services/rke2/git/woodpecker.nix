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
    az.server.rke2.namespaces."app-woodpecker".networkPolicy = {
      fromNamespaces = ["envoy-gateway"];
      toDomains = ["git.${domain}"];

      toWAN = true; # downloads remote images - TODO: local registry
      extraEgress = [{toEntities = ["kube-apiserver"];}];
    };
    az.server.rke2.namespaces."app-forgejo".networkPolicy.toDomains = ["woodpecker.${domain}"]; # push events

    az.server.rke2.namespaces."app-woodpecker-steps" = {
      podSecurity = "baseline"; # TODO: there doesn't seem to be any way to set securityContext for steps
      networkPolicy.toDomains = ["git.${domain}"];
      networkPolicy.toWAN = true; # nix flake updates
    };

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

          chart = "oci://ghcr.io/woodpecker-ci/helm/woodpecker";
          version = "3.2.1";

          valuesContent = let
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
          in
            builtins.toJSON {
              agent = {
                replicaCount = 1;

                inherit securityContext podSecurityContext;
                env = {
                  WOODPECKER_BACKEND_K8S_NAMESPACE = "app-woodpecker-steps";
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

                  WOODPECKER_MAX_PIPELINE_TIMEOUT = "10000"; # just under a week... even full nixos system builds shouldn't take that long, right?
                  WOODPECKER_DEFAULT_MAX_PIPELINE_TIMEOUT = "10000";
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
