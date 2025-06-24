{
  inputs = {
    self.submodules = true;
    core.url = "./core";

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
  in rec {
    formatter.x86_64-linux = core.inputs.nixpkgs.legacyPackages.x86_64-linux.alejandra;
    formatter.aarch64-linux = core.inputs.nixpkgs.legacyPackages.aarch64-linux.alejandra;

    nixosConfigurations = core.mkHostConfigurations {
      path = ./hosts;

      modules = [
	inputs.sops-nix.nixosModules.sops
        ./config
        ./preset.nix
      ];
    };

    hydraJobs = core.mkHydraJobs nixosConfigurations;
  };
}
