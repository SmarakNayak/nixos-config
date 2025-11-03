{ config, lib, pkgs, ... }:

{
  # Test: Only i915 kernel parameters
  # Baseline + i915 params to test Intel GPU power management impact

  # Disable all power management tools
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;
  powerManagement.powertop.enable = false;
  services.thermald.enable = false;

  # Only change: Intel GPU (i915) power management kernel params
  boot.kernelParams = [
    "i915.enable_guc=3"       # Enable GuC submission and HuC firmware
    "i915.enable_fbc=1"       # Framebuffer compression
    "i915.enable_psr=2"       # Panel Self Refresh (PSR2 if supported)
    "i915.fastboot=1"         # Fast boot by preserving display mode
  ];
}
