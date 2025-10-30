{ config, pkgs, ... }:
{
  # System-level: Enable hyprland session
  programs.hyprland.enable = true;

  # Home-manager: Manage hyprland config and packages
  home-manager.users.miltu = {
    home.packages = with pkgs; [
      swappy
      grim
      slurp
      hyprpaper
    ];

    xdg.configFile."hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
    xdg.configFile."hypr/hyprpaper.conf".source = ../dotfiles/hypr/hyprpaper.conf;
    xdg.configFile."hypr/random-wallpaper.sh" = {
      source = ../dotfiles/hypr/random-wallpaper.sh;
      executable = true;
    };
  };
}
