# TODO: would violate PodSecurity "restricted:latest" - apparently RKE2 w/ CIS is too secure for a vuln scanner...
{
  pkgs,
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.rke2.trivy;
  domain = config.az.server.rke2.baseDomain;
in {
  options.az.svc.rke2.trivy = with azLib.opt; {
    enable = optBool false;
  };

  config = mkIf cfg.enable {
    az.server.rke2.manifests."trivy" = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "trivy-system";
        metadata.labels.name = "trivy-system";
        metadata.labels."pod-security.kubernetes.io/enforce" = "privileged"; # too many moving parts to secure properly, plus it's literally a vulnerability scanner it *really* should be reasonably secured by default
      }
      {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "trivy";
          namespace = "kube-system";
        };
        spec = {
          targetNamespace = "trivy-system";
          #createNamespace = true;

          chart = "oci://ghcr.io/aquasecurity/helm-charts/trivy-operator";
          version = "0.30.0";
        };
      }
    ];
  };
}
