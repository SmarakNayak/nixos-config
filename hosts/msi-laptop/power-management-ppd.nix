{ config, lib, pkgs, ... }:

{
  # Enable base power management
  powerManagement.enable = true;

  # Thermald - Proactively prevents overheating on Intel CPUs
  services.thermald.enable = true;

  # Intel GPU (i915) power management - saves 1-2W
  boot.kernelParams = [
    "i915.enable_guc=3"       # Enable GuC submission and HuC firmware
    "i915.enable_fbc=1"       # Framebuffer compression
    "i915.enable_psr=2"       # Panel Self Refresh (PSR2 if supported)
    "i915.fastboot=1"         # Fast boot by preserving display mode
  ];

  # Laptop mode for disk power management - saves ~0.5W
  boot.kernel.sysctl = {
    "vm.laptop_mode" = 5;
  };

  # Power Profiles Daemon - Simple profile switching
  services.power-profiles-daemon.enable = true;

  # Disable conflicting services
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;

  # Powertop auto-tune
  powerManagement.powertop.enable = true;

  # Enable WiFi power saving in NetworkManager
  networking.networkmanager.wifi.powersave = true;

  # Set display to 60Hz for better battery life
  # Works with both Niri and Hyprland
  home-manager.users.miltu = {
    systemd.user.services.set-60hz = {
      Unit = {
        Description = "Set display to 60Hz for battery saving";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "set-60hz" ''
          # Wait for compositor to start
          sleep 2

          # Try Niri first
          if ${pkgs.niri}/bin/niri msg outputs &>/dev/null; then
            ${pkgs.niri}/bin/niri msg output eDP-1 mode 1920x1080@60
          # Then try Hyprland
          elif pgrep -x Hyprland &>/dev/null; then
            ${pkgs.hyprland}/bin/hyprctl keyword monitor eDP-1,1920x1080@60,auto,1
          fi
        ''}";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
