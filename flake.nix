{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-25.05 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = { self, nixpkgs, agenix, ... }@inputs: {
    nixosConfigurations= {
      louqe-pc = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self; };
        modules = [
          ./hosts/louqe-pc/configuration.nix
          agenix.nixosModules.default
        ];
      };
      antec-pc = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self; };
        modules = [
          ./hosts/antec-pc/configuration.nix
          agenix.nixosModules.default
        ];
      };
    };
  };
}
