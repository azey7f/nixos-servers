{azLib, ...}: {
  imports = azLib.scanPath ./.;

  az.microvm = {
    kubernetes.enable = false; # while k8s-ca is part of the k8s infra, it's not actually a k8s node
  };

  az.svc.step-ca = {
    enable = true;
    kubernetes.enable = true;
  };
}
