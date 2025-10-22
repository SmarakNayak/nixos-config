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
      ../../modules/blesh.nix
    ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "louqe-pc"; # Define your hostname.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  time.timeZone = "Australia/Sydney";
  users.users.miltu = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };
  programs.firefox.enable = true;
  programs.steam.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    helix
    ghostty
    wofi
    waybar
    google-chrome
    git
    pavucontrol
    mission-center
    signal-desktop
    discord
    vscode
  ];
  age.identityPaths = [ "/home/miltu/.config/age/master.key" ];
  age.secrets.ssh-key = {
    file =  "${self}/secrets/ssh-key.age";
    path = "/home/miltu/.ssh/id_ed25519";
    mode = "600";
    owner = "miltu";
  };
  programs.git = {
    enable = true;
    config = {
      user = {
        name = "Smarak Nayak";
        email = "miltu.s.nayak@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };

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
}

