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
      swaylock
    ];

    xdg.configFile."hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
    xdg.configFile."hypr/hyprpaper.conf".source = ../dotfiles/hypr/hyprpaper.conf;
    xdg.configFile."hypr/random-wallpaper.sh" = {
      source = ../dotfiles/hypr/random-wallpaper.sh;
      executable = true;
    };
  };

  # System-level service to lock screen before suspend/hibernate
  systemd.services.swaylock-on-sleep = {
    description = "Lock screen before suspend/hibernate";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];

    serviceConfig = {
      Type = "forking";
      User = "miltu";
      Environment = "XDG_RUNTIME_DIR=/run/user/1000";
      ExecStart = "${pkgs.bash}/bin/bash -c 'export WAYLAND_DISPLAY=$(ls /run/user/1000/wayland-* 2>/dev/null | head -n1 | xargs basename); ${pkgs.swaylock}/bin/swaylock -f'";
      TimeoutStartSec = "infinity";
    };
  };
}
