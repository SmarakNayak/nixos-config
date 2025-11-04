{ config, lib, pkgs, ... }:

{
  # Test: Only laptop mode
  # Baseline + laptop mode to test disk power management impact

  # Disable all power management tools
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;
  powerManagement.powertop.enable = false;
  services.thermald.enable = false;

  # Only change: Laptop mode for disk power management
  boot.kernel.sysctl = {
    "vm.laptop_mode" = 5;
  };
}
