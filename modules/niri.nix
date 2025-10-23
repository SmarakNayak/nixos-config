{ config, pkgs, ... }:
{
  # System-level: Enable niri session
  programs.niri.enable = true;

  # XDG Desktop Portal config override for niri
  # xdg.portal = {
  #   enable = true;
  #   configPackages = [ pkgs.niri ];
  #   config.niri = {
  #     "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
  #   };
  # };

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
      nautilus
    ];

    xdg.configFile."niri/config.kdl".source = ../dotfiles/niri/config.kdl;
  };
}
