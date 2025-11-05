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
      hypridle
      swaylock
    ];

   wayland.windowManager.hyprland = {
     enable = true;
     systemd.enable = true;  # Creates hyprland-session.target
     extraConfig = "# Using manual config file";  # Suppress warning
   };

    xdg.configFile."hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
    xdg.configFile."hypr/hyprpaper.conf".source = ../dotfiles/hypr/hyprpaper.conf;
    xdg.configFile."hypr/random-wallpaper.sh" = {
      source = ../dotfiles/hypr/random-wallpaper.sh;
      executable = true;
    };

    xdg.configFile."hypr/show_special_workspace.sh" = {
      source = ../dotfiles/hypr/show_special_workspace.sh;
      executable = true;
    };

    xdg.configFile."hypr/hide_special_workspace.sh" = {
      source = ../dotfiles/hypr/hide_special_workspace.sh;
      executable = true;
    };

    # hypridle: lock screen before suspend/hibernate
    services.hypridle = {
      enable = true;
      systemdTarget = "hyprland-session.target";  # Pin to Hyprland-specific target
      settings = {
        general = {
          before_sleep_cmd = "${pkgs.swaylock}/bin/swaylock -f";
        };
      };
    };
  };
}
