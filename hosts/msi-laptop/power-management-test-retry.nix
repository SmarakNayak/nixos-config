{ config, lib, pkgs, ... }:

{
  # Test config that will intentionally fail to test retry logic
  # This assertion will always fail

  assertions = [
    {
      assertion = false;
      message = "Intentional failure to test retry logic - this should retry 3 times then skip";
    }
  ];

  # Disable all power management
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;
  powerManagement.powertop.enable = false;
  services.thermald.enable = false;
}
