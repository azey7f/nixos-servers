{
  inputs = {
    self.submodules = true;
    core.url = "./core";

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

    # defines which servers belong to what k8s clusters/domains
    infra = import ./infra.nix lib;

    nixosConfigurations = lib.attrsets.concatMapAttrs (domain: cluster:
      builtins.listToAttrs (
        lib.lists.imap0 (i: hostName: {
          name = hostName;
          value =
            core.mkHostConf {
              path = ./hosts;

              modules = [
                inputs.sops-nix.nixosModules.sops
                ./config
                ./services
                ./preset.nix
                {networking = {inherit domain hostName;};}
              ];

              extraArgs = {inherit inputs outputs;};
            }
            hostName; # TODO?: fqdn for derivation name?
        })
        (builtins.attrNames cluster.nodes)
      ))
    infra.clusters;

    hydraJobs = core.mkHydraJobs nixosConfigurations;
  };
}
