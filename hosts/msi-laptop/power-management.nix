{ config, lib, pkgs, ... }:

{
  # Completely disable NVIDIA GPU to save power, since d3 doesnt work
  hardware.nvidiaOptimus.disable = true;
  hardware.nvidia = {
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;  # Provides 'nvidia-offload' command
      };
      intelBusId = "PCI:0:2:0";   # Intel TigerLake-H GT1
      nvidiaBusId = "PCI:1:0:0";  # RTX 3050 Ti Mobile
    };

    # Aggressive power management for better battery life
    powerManagement.enable = true;
    powerManagement.finegrained = true;  # Runtime D3 power state (deep sleep)
  };

  # enable cpu powersaving
  powerManagement.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      # Minimal TLP config - let TLP use its defaults
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };

  powerManagement.powertop.enable = true;
}
