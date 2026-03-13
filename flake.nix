{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-25.05 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

  };

  outputs = { self, nixpkgs, agenix, home-manager, claude-code, llm-agents, ghostty, ... }@inputs: {
    nixosConfigurations= {
      louqe-pc = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self llm-agents ghostty; };
        modules = [
          ./hosts/louqe-pc/configuration.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [ claude-code.overlays.default llm-agents.overlays.default ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.miltu = import ./home.nix;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [ agenix.homeManagerModules.default ];
            home-manager.extraSpecialArgs = { inherit llm-agents ghostty; };
          }
        ];
      };
      antec-pc = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self llm-agents ghostty; };
        modules = [
          ./hosts/antec-pc/configuration.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [ claude-code.overlays.default llm-agents.overlays.default ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.miltu = import ./home.nix;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [ agenix.homeManagerModules.default ];
            home-manager.extraSpecialArgs = { inherit llm-agents ghostty; };
          }
        ];
      };
      msi-laptop = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self llm-agents ghostty; };
        modules = [
          ./hosts/msi-laptop/configuration.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [ claude-code.overlays.default llm-agents.overlays.default ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.miltu = import ./home.nix;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [ agenix.homeManagerModules.default ];
            home-manager.extraSpecialArgs = { inherit llm-agents ghostty; };
          }
        ];
      };
    };
  };
}
