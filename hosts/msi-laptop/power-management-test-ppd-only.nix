{ config, lib, pkgs, ... }:

{
  # Test: Only Power Profiles Daemon
  # Baseline + PPD to test PPD daemon impact in isolation

  # Disable all other power management tools
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;
  powerManagement.powertop.enable = false;
  services.thermald.enable = false;

  # Only change: Enable Power Profiles Daemon
  services.power-profiles-daemon.enable = true;
}
