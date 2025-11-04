{ config, lib, pkgs, ... }:

{
  # Test: All features combined WITHOUT any power daemon
  # This tests the cumulative effect of all manual optimizations
  # thermald + i915 + laptop-mode + wifi + 60Hz (NO daemon, NO powertop)

  # Enable base power management
  powerManagement.enable = true;

  # Thermald
  services.thermald.enable = true;

  # Intel GPU (i915) power management
  boot.kernelParams = [
    "i915.enable_guc=3"
    "i915.enable_fbc=1"
    "i915.enable_psr=2"
    "i915.fastboot=1"
  ];

  # Laptop mode for disk power management
  boot.kernel.sysctl = {
    "vm.laptop_mode" = 5;
  };

  # NO powertop auto-tune (testing manual optimizations only)
  powerManagement.powertop.enable = false;

  # NO power daemon
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;

  # WiFi power saving
  networking.networkmanager.wifi.powersave = true;

  # 60Hz display
  home-manager.users.miltu = {
    systemd.user.services.set-60hz = {
      Unit = {
        Description = "Set display to 60Hz for battery saving";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "set-60hz" ''
          sleep 2
          if ${pkgs.niri}/bin/niri msg outputs &>/dev/null; then
            ${pkgs.niri}/bin/niri msg output eDP-1 mode 1920x1080@60
          elif pgrep -x Hyprland &>/dev/null; then
            ${pkgs.hyprland}/bin/hyprctl keyword monitor eDP-1,1920x1080@60,auto,1
          fi
        ''}";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
