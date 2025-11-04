{ config, lib, pkgs, ... }:

{
  # Completely disable NVIDIA GPU to save power
  # hardware.nvidiaOptimus.disable = true;

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
}
