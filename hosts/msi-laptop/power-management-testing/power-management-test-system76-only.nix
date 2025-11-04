{ config, lib, pkgs, ... }:

{
  # Test: Only System76 power daemon
  # Baseline + system76-power to test system76 daemon impact in isolation

  # Disable all other power management tools
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;
  powerManagement.powertop.enable = false;
  services.thermald.enable = false;

  # Only change: Enable System76 Power Management
  powerManagement.enable = true;
  hardware.system76.power-daemon.enable = true;
}
