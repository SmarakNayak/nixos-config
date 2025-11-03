{ config, lib, pkgs, ... }:

{
  # Test: Only WiFi power save
  # Baseline + WiFi power save to test WiFi power management impact

  # Disable all power management tools
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;
  powerManagement.powertop.enable = false;
  services.thermald.enable = false;

  # Only change: Enable WiFi power saving
  networking.networkmanager.wifi.powersave = true;
}
