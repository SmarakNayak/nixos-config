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

      # Limit CPU frequency on battery - saves 1-2W
      CPU_SCALING_MIN_FREQ_ON_BAT = 800000;
      CPU_SCALING_MAX_FREQ_ON_BAT = 1600000;  # Cap at 1.6GHz (down from 2.3GHz)

      # Energy Performance Preference - most aggressive power saving
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      # Intel CPU HWP (Hardware P-states) - more aggressive
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 30;  # Limit to 30% of max performance

      # Runtime power management for devices
      RUNTIME_PM_ON_BAT = "auto";

      # PCIe Active State Power Management - most aggressive
      PCIE_ASPM_ON_BAT = "powersupersave";

      # WiFi power saving
      WIFI_PWR_ON_BAT = "on";

      # Battery charge thresholds
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 95;

      # Disk power management - most aggressive
      SATA_LINKPWR_ON_BAT = "min_power";
      AHCI_RUNTIME_PM_ON_BAT = "auto";

      # USB autosuspend - more aggressive (1 second timeout)
      USB_AUTOSUSPEND = 1;
      USB_AUTOSUSPEND_DISABLE_ON_SHUTDOWN = 1;

      # Audio power saving - aggressive
      SOUND_POWER_SAVE_ON_BAT = 1;
      SOUND_POWER_SAVE_CONTROLLER = "Y";

      # Disable NMI watchdog (saves ~1% battery, low risk)
      NMI_WATCHDOG = 0;

      # Platform power profiles (if supported by firmware)
      PLATFORM_PROFILE_ON_BAT = "low-power";
      PLATFORM_PROFILE_ON_AC = "performance";

      # Disable wake-on-LAN to save power
      WOL_DISABLE = "Y";

      # More aggressive runtime power management
      RUNTIME_PM_DRIVER_DENYLIST = "";

      # Intel graphics power management
      INTEL_GPU_MIN_FREQ_ON_BAT = 300;
      INTEL_GPU_MAX_FREQ_ON_BAT = 500;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 500;
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
