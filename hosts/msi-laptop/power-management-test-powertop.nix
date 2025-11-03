{ config, lib, pkgs, ... }:

{
  # Test: Only powertop
  # Baseline + powertop to test powertop auto-tune impact

  # Disable all power management tools except powertop
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;
  services.thermald.enable = false;

  # Only change: Enable powertop
  powerManagement.enable = true;
  powerManagement.powertop.enable = true;
}
