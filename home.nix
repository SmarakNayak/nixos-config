{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "miltu";
  home.homeDirectory = "/home/miltu";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "25.05";

  # Packages that should be installed to the user profile
  home.packages = with pkgs; [
    # tree
    # Add more user-specific packages here
  ];

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Example: Configure git (you can remove this from configuration.nix if you move it here)
  # programs.git = {
  #   enable = true;
  #   userName = "Smarak Nayak";
  #   userEmail = "miltu.s.nayak@gmail.com";
  #   extraConfig = {
  #     init.defaultBranch = "main";
  #   };
  # };

  # Example: Configure shell
  # programs.bash = {
  #   enable = true;
  #   shellAliases = {
  #     ll = "ls -la";
  #     ".." = "cd ..";
  #   };
  # };

  # Example: Configure helix
  # programs.helix = {
  #   enable = true;
  #   settings = {
  #     theme = "onedark";
  #   };
  # };
}
