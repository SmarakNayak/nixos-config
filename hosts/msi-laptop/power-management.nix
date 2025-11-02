{ config, lib, pkgs, ... }:

{
  # Enable base power management
  powerManagement.enable = true;

  # Thermald - Proactively prevents overheating on Intel CPUs
  services.thermald.enable = true;

  # System76 Power Management
  # Provides simple power profile switching: battery, balanced, performance
  # Use: system76-power profile battery|balanced|performance
  services.power-profiles-daemon.enable = false;  # Conflicts with system76-power

  hardware.system76.power-daemon.enable = true;

  # Enable WiFi power saving in NetworkManager
  networking.networkmanager.wifi.powersave = true;
}
