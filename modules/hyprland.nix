{ config, pkgs, ... }:
{
  imports = [ ./dolphin-android-integration.nix ];

  # XDG Desktop Portal — consistent file/folder chooser dialogs
  xdg.portal = {
    enable = true;
    extraPortals = []; #Installed at a user level
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
    };
  };

  # Show all disks in dolphin
  services.udisks2.enable = true;

  # GTK apps use dconf for settings such as middle-click primary paste.
  programs.dconf.enable = true;

  # System-level: Enable hyprland session
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  # Home-manager: Manage hyprland config and packages
  home-manager.users.miltu = {
    home.packages = with pkgs; [
      satty
      grim
      slurp
      wf-recorder
      libnotify
      hyprpaper
      hypridle
      swaylock
      dpms-off
      # Portal packages must be in home.packages so their .portal files land in
      # /etc/profiles/per-user/$USER/ — the first XDG_DATA_DIRS entry the daemon scans
      # This is because wayland.windowManager.hyprland puts the hyprland portal there
      kdePackages.xdg-desktop-portal-kde
      xdg-desktop-portal-gtk
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "hyprlang";
      systemd.enable = true;  # Creates hyprland-session.target
      # systemd.enable = false;  # UWSM manages the systemd session
      extraConfig = "# Using manual config file";  # Suppress warning
    };
    
    # Make hyprland-session start XDG autostart apps
    systemd.user.targets.hyprland-session = {
      Unit.Wants = [ "xdg-desktop-autostart.target" ];
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

    xdg.configFile."hypr/toggle_scratchpad.sh" = {
      source = ../dotfiles/hypr/toggle_scratchpad.sh;
      executable = true;
    };

    xdg.configFile."hypr/screenshot.sh" = {
      source = ../dotfiles/hypr/screenshot.sh;
      executable = true;
    };

    xdg.configFile."hypr/toggle_recording.sh" = {
      source = ../dotfiles/hypr/toggle_recording.sh;
      executable = true;
    };

    # hypridle: lock screen before suspend/hibernate
    services.hypridle = {
      enable = true;
      systemdTarget = "hyprland-session.target";  # Pin to Hyprland-specific target
      settings = {
        general = {
          lock_cmd = "${pkgs.swaylock}/bin/swaylock -f";
          on_lock_cmd = "sleep 30 && pidof swaylock && dpms-off";
          before_sleep_cmd = "${pkgs.swaylock}/bin/swaylock -f";
        };
      };
    };

  };
}
