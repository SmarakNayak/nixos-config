{ config, lib, pkgs, ... }:

{
  # Baseline - Empty power management configuration
  # No power management tools, no kernel params, no special settings
  # This serves as the baseline to compare against other configurations

  # Disable all power management tools
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;
  powerManagement.powertop.enable = false;
  services.thermald.enable = false;
}
