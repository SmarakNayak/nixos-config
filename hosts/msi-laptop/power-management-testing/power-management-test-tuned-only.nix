{ config, lib, pkgs, ... }:

{
  # Test: Only tuned daemon
  # Baseline + tuned to test tuned daemon impact in isolation

  # Disable all other power management tools
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;
  powerManagement.powertop.enable = false;
  services.thermald.enable = false;

  # Only change: Enable tuned with laptop profile
  services.tuned.enable = true;
  # Uses the "laptop-battery-powersave" profile by default on battery
}
