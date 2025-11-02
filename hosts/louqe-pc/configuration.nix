# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, self, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/niri.nix
      ../../modules/hyprland.nix
    ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "louqe-pc"; # Define your hostname.
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
  ];
  # nvidia settings
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = false; # for anything prior to 2000 series (1660ti)
    modesetting.enable = true;
    nvidiaSettings = true;
  };
  system.stateVersion = "25.05"; # Did you read the comment?

  virtualisation.podman.enable = true;

  # Ollama service with GPU acceleration
  services.ollama = {
    enable = true;
    acceleration = "cuda"; # NVIDIA GPU acceleration
  };

  # Ly TUI login manager
  services.displayManager.ly = {
    enable = true;
    settings = {
      xinitrc = "";   # Hide xinitrc option (X11 not configured)
      setup_cmd = ""; # Don't use xsession-wrapper for shell sessions
    };
  };

  # Firewall configuration
  networking.firewall.allowedTCPPorts = [ 8081 ]; # For Expo
}

