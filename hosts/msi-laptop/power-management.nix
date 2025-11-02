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
      STOP_CHARGE_THRESH_BAT0 = 95;
    };
  };

  # System76 Power Management (commented out in favor of auto-cpufreq/TLP)
  # Provides simple power profile switching: battery, balanced, performance
  # Use: system76-power profile battery|balanced|performance
  # services.power-profiles-daemon.enable = false;  # Conflicts with system76-power
  # hardware.system76.power-daemon.enable = true;

  # Enable WiFi power saving in NetworkManager
  networking.networkmanager.wifi.powersave = true;
}
