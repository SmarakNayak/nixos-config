{ config, lib, pkgs, ... }:

{
  # Test: Only auto-cpufreq daemon
  # Baseline + auto-cpufreq to test auto-cpufreq daemon impact in isolation

  # Disable all other power management tools
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  powerManagement.powertop.enable = false;
  services.thermald.enable = false;

  # Only change: Enable auto-cpufreq
  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    battery = {
      governor = "powersave";
      turbo = "never";
    };
    charger = {
      governor = "performance";
      turbo = "auto";
    };
  };
}
