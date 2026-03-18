{ pkgs, ... }: {
  virtualisation.vmVariant.virtualisation = {
    graphics = true;
    memorySize = 4096;
    cores = 2;
    diskSize = 512000;
    sharedDirectories = {
      stability-matrix-nix = {
        source = "/home/miltu/stability-matrix-nix";
        target = "/mnt/stability-matrix-nix";
      };
    };
  };

  # Minimal system — no extra overlays so nothing leaks in from the host
  environment.systemPackages = with pkgs; [
    # Add packages under test here, e.g.:
    # (pkgs.callPackage ../../packages/my-package.nix {})
  ];

  users.users.test = {
    isNormalUser = true;
    password = "test";
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = "test";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Required for VM boot
  system.stateVersion = "25.05";
}
