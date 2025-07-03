{
  inputs = {
    self.submodules = true;
    core.url = "./core";

    # vm stuff
    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "core/nixpkgs";

    # secrets management
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "core/nixpkgs";
  };

  outputs = {
    self,
    core,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = core.inputs.nixpkgs.lib;
  in rec {
    formatter.x86_64-linux = core.inputs.nixpkgs.legacyPackages.x86_64-linux.alejandra;
    formatter.aarch64-linux = core.inputs.nixpkgs.legacyPackages.aarch64-linux.alejandra;

    nixosConfigurations = servers // microvm;
    hydraJobs = core.mkHydraJobs servers; # TODO: maybe also microVMs?

    # defines which servers belong to what k8s clusters/domains, how many VMs to create, etc etc
    # k8s-workers use the k8s-controllers from their own cluster, even if they're on a different server
    # microvm internal IP addrs are dynamically created from this, see microvmSubnet
    infra = import ./infra.nix core.inputs.nixpkgs.lib;

    servers =
      lib.attrsets.concatMapAttrs (domain: cluster: (
        builtins.mapAttrs (hostName: _: (
          core.mkHostConf {
            path = ./hosts;

            modules = [
              inputs.sops-nix.nixosModules.sops
              inputs.microvm.nixosModules.host
              ./config
              ./services
              ./preset.nix
              {networking = {inherit domain hostName;};}
            ];

            extraArgs = {inherit inputs outputs;};
          }
          hostName
        ))
        cluster.servers
      ))
      infra.clusters;

    microvm =
      lib.attrsets.concatMapAttrs (domainName: domain: (
        lib.attrsets.concatMapAttrs (clusterName: cluster: (
          lib.attrsets.concatMapAttrs (serverName: server: (
            lib.attrsets.concatMapAttrs (baseName: vm: (
              builtins.listToAttrs (
                builtins.map (
                  i: let
                    hostName = "${baseName}-${builtins.toString i}";
                  in {
                    name = "${serverName}:${hostName}";
                    value =
                      core.mkHostConf {
                        path = ./microvm/hosts;

                        modules = [
                          inputs.microvm.nixosModules.microvm

                          ./microvm/config
                          ./microvm/services
                          ./microvm/preset.nix

                          ({azLib, ...}: let
                            cert = core.certs.${azLib.reverseFQDN domainName};
                          in {
                            networking = {
                              inherit hostName;
                              domain = "${serverName}.${clusterName}.${domainName}";
                            };

                            az.microvm = {
                              enable = true;

                              serverName = serverName;
                              name = baseName;
                              index = i;

                              mem = vm.mem or 512;
                              vcpu = vm.vcpu or 2;
                            };

                            az.svc.ssh.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMnFDhRTJyoFdhs31OHXvQwcQY3SlB9WX0bUCTlJKdJO root@astra"]; # TODO

                            # domain cert
                            security.pki.certificates = [cert];
                            environment.etc."ssl/domain-ca.crt".text = cert;
                          })
                        ];

                        extraArgs = {inherit inputs outputs;};
                      }
                      baseName;
                  }
                ) (lib.lists.range 0 (vm.count - 1))
              )
            ))
            server.vms
          ))
          cluster.servers
        ))
        domain.clusters
      ))
      infra.domains;
  };
}
