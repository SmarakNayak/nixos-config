{ config, lib, pkgs, ... }:

{
  # Test: Only thermald
  # Baseline + thermald to test thermal management impact

  # Disable all power management tools except thermald
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;
  powerManagement.powertop.enable = false;

  # Only change: Enable thermald
  services.thermald.enable = true;
}
