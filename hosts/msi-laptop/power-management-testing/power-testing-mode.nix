{ config, lib, pkgs, ... }:

{
  # TEMPORARY MODULE FOR AUTOMATED POWER TESTING
  # WARNING: This enables autologin and passwordless sudo - SECURITY RISK!
  #
  # To enable: Import this module in configuration.nix
  # To disable: Remove the import and rebuild

  # Disable Ly (doesn't support autologin) and use greetd instead
  services.displayManager.ly.enable = lib.mkForce false;

  # Use greetd with autologin for automated testing
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "miltu";
      };
      initial_session = {
        command = "niri-session";
        user = "miltu";
      };
    };
  };

  # Allow passwordless sudo for nixos-rebuild during testing
  security.sudo.enable = true;
  security.sudo.extraRules = [
    {
      users = [ "miltu" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Install powerstat for testing
  environment.systemPackages = with pkgs; [
    powerstat
  ];

  # Enable the power-test service to run automatically on login
  systemd.user.services.power-test = {
    enable = true;
    description = "Automated Power Management Testing";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    path = with pkgs; [ bash coreutils gnused jq systemd powerstat ] ++ [ "/run/wrappers" ];
    script = ''
      ${pkgs.bash}/bin/bash /home/miltu/nixos-config/hosts/msi-laptop/power-management-testing/power-test.sh
    '';
    serviceConfig = {
      Type = "oneshot";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };
}
