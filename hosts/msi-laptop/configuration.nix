# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, self, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./power-management-auto-cpufreq.nix
      ../../modules/niri.nix
      ../../modules/hyprland.nix
    ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "msi-laptop"; # Define your hostname.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  time.timeZone = "Australia/Sydney";
  users.users.miltu = {
    isNormalUser = true;
    extraGroups = [ "wheel" "adbusers" ]; # Enable 'sudo' for the user.
  };

  # Increase sudo password timeout to 300 minutes
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=300
  '';
  programs.firefox.enable = true;
  programs.steam.enable = true;
  programs.fish.enable = true; # Enable system package completions
  programs.zsh.enable = true; # Enable system package completions
  programs.adb.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git
    powerstat
  ];
  # nvidia settings
  hardware.graphics.enable = true;

  # Completely disable NVIDIA GPU to save power
  hardware.nvidiaOptimus.disable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true; # RTX 3050 Ti Mobile - using proprietary driver
    modesetting.enable = true;
    nvidiaSettings = true;

    # PRIME Offload: Use Intel iGPU by default, NVIDIA on-demand for battery saving
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
  system.stateVersion = "25.05"; # Did you read the comment?

  # Ly TUI login manager
  services.displayManager.ly = {
    enable = true;
    settings = {
      xinitrc = "";   # Hide xinitrc option (X11 not configured)
      setup_cmd = ""; # Don't use xsession-wrapper for shell sessions
    };
  };

  virtualisation.podman.enable = true;

  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  # Bluetooth with blueman applet
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;  # Don't auto-start bluetooth (saves power)
  services.blueman.enable = true;


  # Firewall configuration
  networking.firewall.allowedTCPPorts = [ 8081 ]; # For Expo
}

