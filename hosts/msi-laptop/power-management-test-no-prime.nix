{ config, lib, pkgs, ... }:

{
  # Test: GPU enabled without PRIME
  # Baseline + GPU enabled but PRIME disabled to test PRIME overhead
  # Overrides configuration.nix settings

  # Disable all power management tools
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;
  powerManagement.powertop.enable = false;
  services.thermald.enable = false;

  # Only change: Enable GPU but disable PRIME offload
  hardware.nvidiaOptimus.disable = lib.mkForce false;
  hardware.nvidia.prime.offload.enable = lib.mkForce false;
  hardware.nvidia.prime.offload.enableOffloadCmd = lib.mkForce false;
}
