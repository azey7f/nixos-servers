{
  config,
  lib,
  azLib,
  ...
}:
with lib; let
  cfg = config.az.svc.k3s.metallb;
in {
  options.az.svc.k3s.metallb = with azLib.opt; {
    enable = optBool false;
    subnet = optStr "fd33::/124"; # TODO: random ULA?
  };

  config = mkIf cfg.enable {
    az.k3s.charts.metallb = {
      name = "metallb";
      repo = "https://metallb.github.io/metallb";

      version = "v0.15.2";
      hash = "sha256-Tw/DE82XgZoceP/wo4nf4cn5i8SQ8z9SExdHXfHXuHM=";

      targetNamespace = "metallb-system";
      createNamespace = true;

      extraDeploy = [
        {
          apiVersion = "metallb.io/v1beta1";
          kind = "IPAddressPool";
          metadata = {
            name = "metallb-pool";
            namespace = "metallb-system";
          };
          spec.addresses = [cfg.subnet];
        }
        {
          apiVersion = "metallb.io/v1beta1";
          kind = "L2Advertisement"; # TODO: BGP, if/when I get more servers
          metadata = {
            name = "metallb-advert";
            namespace = "metallb-system";
          };
        }
      ];
    };
  };
}
