{ config, lib, pkgs, ... }:

{
  # Test: GPU enabled without PRIME and without GPU power management
  # Tests GPU with no NVIDIA power management features at all
  # Baseline + GPU - PRIME - GPU power management

  # Disable all power management tools
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;
  powerManagement.powertop.enable = false;
  services.thermald.enable = false;

  # Enable NVIDIA GPU but disable PRIME and all power management
  hardware.nvidiaOptimus.disable = lib.mkForce false;

  # Disable PRIME offload
  hardware.nvidia.prime.offload.enable = lib.mkForce false;
  hardware.nvidia.prime.offload.enableOffloadCmd = lib.mkForce false;

  # Disable NVIDIA GPU power management features
  hardware.nvidia.powerManagement.enable = lib.mkForce false;
  hardware.nvidia.powerManagement.finegrained = lib.mkForce false;
}
