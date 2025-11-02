{ config, lib, pkgs, ... }:

{
  # Enable base power management
  powerManagement.enable = true;

  # Thermald - Proactively prevents overheating on Intel CPUs
  services.thermald.enable = true;

  # Auto-cpufreq - Automatic CPU frequency scaling (commented out)
  # services.auto-cpufreq.enable = true;
  # services.auto-cpufreq.settings = {
  #   battery = {
  #     governor = "powersave";
  #     turbo = "never";
  #   };
  #   charger = {
  #     governor = "performance";
  #     turbo = "auto";
  #   };
  # };

  # TLP + powertop
  powerManagement.powertop.enable = true;
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Energy Performance Preference - most aggressive power saving
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      # Runtime power management for devices
      RUNTIME_PM_ON_BAT = "auto";

      # PCIe Active State Power Management
      PCIE_ASPM_ON_BAT = "powersupersave";

      # WiFi power saving
      WIFI_PWR_ON_BAT = "on";

      # Battery charge thresholds
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 95;

      # Disk power management
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";

      # USB autosuspend for power saving
      USB_AUTOSUSPEND = 1;

      # Audio power saving
      SOUND_POWER_SAVE_ON_BAT = 1;

      # Disable NMI watchdog (saves ~1% battery, low risk)
      NMI_WATCHDOG = 0;

      # Platform power profiles (if supported by firmware)
      PLATFORM_PROFILE_ON_BAT = "low-power";
      PLATFORM_PROFILE_ON_AC = "performance";
    };
  };

  # System76 Power Management (commented out in favor of auto-cpufreq/TLP)
  # Provides simple power profile switching: battery, balanced, performance
  # Use: system76-power profile battery|balanced|performance
  # services.power-profiles-daemon.enable = false;  # Conflicts with system76-power
  # hardware.system76.power-daemon.enable = true;

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
