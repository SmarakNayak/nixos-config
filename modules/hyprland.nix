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
    ];

    xdg.configFile."hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
  };
}
