{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-25.05 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, agenix, home-manager, ... }@inputs: {
    nixosConfigurations= {
      louqe-pc = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self; };
        modules = [
          ./hosts/louqe-pc/configuration.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.miltu = import ./home.nix;
            home-manager.backupFileExtension = "backup";
          }
        ];
      };
      antec-pc = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self; };
        modules = [
          ./hosts/antec-pc/configuration.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.miltu = import ./home.nix;
            home-manager.backupFileExtension = "backup";
          }
        ];
      };
    };
  };
}
