{ config, pkgs, lib, ... }:

let
  claude-distro = import ./distrobox-packages/claude-code.nix { inherit pkgs; };
in
{
  home.username = "miltu";
  home.homeDirectory = "/home/miltu";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    # tree
    curl
    distrobox
    claude-distro
    claude-code
  ];
  
  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
    };
  };

  # Example: Configure git (you can remove this from configuration.nix if you move it here)
  # programs.git = {
  #   enable = true;
  #   userName = "Smarak Nayak";
  #   userEmail = "miltu.s.nayak@gmail.com";
  #   extraConfig = {
  #     init.defaultBranch = "main";
  #   };
  # };
  xdg.configFile."waybar/config.jsonc".source = ./dotfiles/waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./dotfiles/waybar/style.css;
  xdg.configFile."waybar/scripts" = {
    source = ./dotfiles/waybar/scripts;
    recursive = true;
  };
  xdg.desktopEntries.google-chrome = {
    name = "Google Chrome";
    exec = "google-chrome-stable --disable-features=WaylandWpColorManagerV1 %U";
    icon = "google-chrome";
    type = "Application";
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "text/xml" ];
    actions = {};
  };
  home.activation.clearWofiCache = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo 'HELLLO'
    run rm -f $HOME/.cache/wofi-drun
  '';
}
