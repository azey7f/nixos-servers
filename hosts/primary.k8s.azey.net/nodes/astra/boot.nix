{
  lib,
  config,
  ...
}:
with lib; {
  boot.extraModprobeConfig = ''
    options vfio-pci ids=10de:220a,10de:1aef,1022:15b6,1022:15b7,1022:15e3,1022:43f7,1002:164e,1002:1640
    options ixgbe allow_unsupported_sfp=1 # allow unsupported SFP modules on Intel X520-DA2
  '';
  boot.blacklistedKernelModules = ["amdgpu" "radeon" "nvidia" "nouveau" "xhci_pci"];

  boot.kernelParams = [
    "isolcpus=0-7,16-23"
    "nohz_full=0-7,16-23"
    "rcu_nocbs=0-7,16-23"
    "rcu_nocb_poll"
    "irqaffinity=8,9,10,11,12,13,14,15,24,25,26,27,28,29,30,31"
  ];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "r8169" "ixgbe"];
  boot.kernelModules = ["nct6775"]; # fan PWM
}
