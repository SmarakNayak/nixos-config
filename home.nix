{ config, pkgs, ... }:

{
  home.username = "miltu";
  home.homeDirectory = "/home/miltu";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # tree
  ];
  
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
  home.file.".config/hypr/hyprland.conf".source = ./dotfiles/hypr/hyprland.conf;
  xdg.enable = true;
  xdg.desktopEntries.google-chrome = {
    name = "Google Chrome";
    exec = "google-chrome-stable --disable-features=WaylandWpColorManagerV1 %U";
    icon = "google-chrome";
    type = "Application";
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "text/xml" ];
  };
}
