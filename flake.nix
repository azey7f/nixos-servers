{
  inputs = {
    self.submodules = true;
    core.url = "./core";

    rke2-k3s-merge.url = "github:azey7f/nixpkgs/rke2-k3s-merge";
    rke2_1_34.url = "github:rorosen/nixpkgs/rke2_1_34";

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

    nixosConfigurations = builtins.listToAttrs (
      lib.concatMap (
        domain:
        # TODO: reverseFQDN
          builtins.map (hostName: {
            #name = "${domain}.${hostName}"; # TODO?
            name = hostName;
            value =
              core.mkHostConf {
                path = ./hosts/${domain}/nodes;

                modules = [
                  inputs.sops-nix.nixosModules.sops
                  ./config
                  ./services
                  ./cluster
                  ./preset.nix

                  ./hosts/${domain}
                  {networking = {inherit domain hostName;};}
                ];

                specialArgs = {inherit inputs outputs;};
              }
              hostName;
          })
          (builtins.attrNames (builtins.readDir ./hosts/${domain}/nodes))
      )
      (builtins.attrNames (builtins.readDir ./hosts))
    );
  };
}
