# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, self, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./power-management.nix
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
    intel-gpu-tools
    nvtopPackages.intel
  ];
  # Grant CAP_PERFMON to intel_gpu_top for GPU monitoring
  security.wrappers.intel_gpu_top = {
    owner = "root";
    group = "root";
    capabilities = "cap_perfmon=ep";
    source = "${pkgs.intel-gpu-tools}/bin/intel_gpu_top";
  };

  # nvidia settings
  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    open = false; # RTX 3050 Ti Mobile - using proprietary driver
    modesetting.enable = true;
    nvidiaSettings = true;
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

  swapDevices = [{
    device = "/swap/swapfile";
    size = 32 * 1024; # Creates a 32GB swap file
  }];

  # Hibernation configuration
  boot.resumeDevice = "/dev/disk/by-uuid/ce9d6127-ce90-4480-8a86-b9d075e5e943";
  boot.kernelParams = [
    "resume_offset=11837774"
  ];

  # Lid and power button behavior
  services.logind.settings.Login = {
    HandleLidSwitch = "hibernate";              # Close lid → hibernate
    HandleLidSwitchExternalPower = "suspend";   # Close lid on AC → suspend
    HandlePowerKey = "hibernate";
  };

  # Performance specialisation - disables power-management optimizations
  specialisation.performance = {
    inheritParentConfig = true;
    configuration = {
      # Disable the power-management module
      disabledModules = [ ./power-management.nix ];
    };
  };
}

