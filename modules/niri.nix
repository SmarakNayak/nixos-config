{ config, pkgs, ... }:
{
  # System-level: Enable niri session
  programs.niri.enable = true;

  # Home-manager: Manage niri config and packages
  home-manager.users.miltu = {
    home.packages = with pkgs; [
      xwayland-satellite
      alacritty
      fuzzel
      swaylock
      swaybg
      variety
      mako
    ];

    xdg.configFile."niri/config.kdl".source = ../dotfiles/niri/config.kdl;
  };
}
