{
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.microvm.kubernetes;
in {
  options.az.microvm.kubernetes = with azLib.opt; {
    caName = optStr "k8s-ca-0";
  };

  config = mkIf cfg.enable {
    az.microvm.shares = [
      # certs, see ../../services/step-ca/kubernetes.nix
      {
        proto = "virtiofs";
        tag = "k8s-certs";
        source = "/vm/${cfg.caName}/step-ca-k8s/${config.networking.hostName}";
        mountPoint = "/certs";
      }
    ];

    # TODO: renewal
    # https://github.com/smallstep/kubernetes-the-hard-way/blob/master/docs/13-certificate-renewal.md
  };
}
