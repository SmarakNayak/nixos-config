{ config, lib, pkgs, ... }:

{
  # Test: GPU enabled with PRIME
  # Baseline + GPU enabled (with PRIME) to test GPU+PRIME power impact
  # Overrides configuration.nix which disables the GPU

  # Disable all power management tools
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;
  powerManagement.powertop.enable = false;
  services.thermald.enable = false;

  # Only change: Enable NVIDIA GPU (PRIME stays enabled from configuration.nix)
  hardware.nvidiaOptimus.disable = lib.mkForce false;
}
