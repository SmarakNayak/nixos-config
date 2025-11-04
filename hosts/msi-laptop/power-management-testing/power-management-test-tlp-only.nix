{ config, lib, pkgs, ... }:

{
  # Test: Only TLP daemon
  # Baseline + TLP to test TLP daemon impact in isolation (minimal config)

  # Disable all other power management tools
  services.power-profiles-daemon.enable = false;
  services.auto-cpufreq.enable = false;
  powerManagement.powertop.enable = false;
  services.thermald.enable = false;

  # Only change: Enable TLP with minimal settings
  powerManagement.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      # Minimal TLP config - let TLP use its defaults
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };
}
