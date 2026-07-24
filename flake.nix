{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-25.05 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      # Keep llm-agents on its own pinned nixpkgs so Codex matches Numtide's
      # binary cache. Following the root nixpkgs changes the Codex store path
      # and forces slow local Rust builds on laptops.
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    comfyui-nix = {
      url = "github:utensils/comfyui-nix";
    };

    stability-matrix-nix = {
      url = "github:SmarakNayak/stability-matrix-nix";
    };

  };

  outputs = { self, nixpkgs, agenix, hermes-agent, home-manager, nix-flatpak, claude-code, llm-agents, ghostty, comfyui-nix, stability-matrix-nix, ... }@inputs: {
    nixosConfigurations= {
      louqe-pc = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self; };
        modules = [
          ./hosts/louqe-pc/configuration.nix
          nix-flatpak.nixosModules.nix-flatpak
          ./modules/flatpak.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [
              claude-code.overlays.default
              ghostty.overlays.default
              comfyui-nix.overlays.default
              stability-matrix-nix.overlays.default
            ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.miltu = import ./home/home.nix;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [ agenix.homeManagerModules.default ];
            home-manager.extraSpecialArgs = { inherit llm-agents; };
          }
        ];
      };
      antec-pc = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self; };
        modules = [
          ./hosts/antec-pc/configuration.nix
          agenix.nixosModules.default
          hermes-agent.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [
              claude-code.overlays.default
              hermes-agent.overlays.default
              ghostty.overlays.default
              comfyui-nix.overlays.default
              stability-matrix-nix.overlays.default
            ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.miltu = import ./home/home-server.nix;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [ agenix.homeManagerModules.default ];
            home-manager.extraSpecialArgs = { inherit llm-agents; };
          }
        ];
      };
      test-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/test-vm/configuration.nix
        ];
      };
      msi-laptop = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self; };
        modules = [
          ./hosts/msi-laptop/configuration.nix
          nix-flatpak.nixosModules.nix-flatpak
          ./modules/flatpak.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [
              claude-code.overlays.default
              ghostty.overlays.default
              comfyui-nix.overlays.default
              stability-matrix-nix.overlays.default
            ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.miltu = import ./home/home.nix;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [ agenix.homeManagerModules.default ];
            home-manager.extraSpecialArgs = { inherit llm-agents; };
          }
        ];
      };
    };
    packages.x86_64-linux.test-vm = self.nixosConfigurations.test-vm.config.system.build.vm;
  };
}
