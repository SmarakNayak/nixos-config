{ config, lib, pkgs, ... }:

{
  # Test: All features + TLP with aggressive settings
  # This is the "kitchen sink" approach - everything combined
  # (This is essentially your current power-management-tlp.nix)

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

  # TLP with aggressive settings + powertop
  powerManagement.powertop.enable = true;
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_SCALING_MIN_FREQ_ON_BAT = 800000;
      CPU_SCALING_MAX_FREQ_ON_BAT = 1600000;

      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 30;

      RUNTIME_PM_ON_BAT = "auto";
      PCIE_ASPM_ON_BAT = "powersupersave";
      WIFI_PWR_ON_BAT = "on";

      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 95;

      SATA_LINKPWR_ON_BAT = "min_power";
      AHCI_RUNTIME_PM_ON_BAT = "auto";

      USB_AUTOSUSPEND = 1;
      USB_AUTOSUSPEND_DISABLE_ON_SHUTDOWN = 1;

      SOUND_POWER_SAVE_ON_BAT = 1;
      SOUND_POWER_SAVE_CONTROLLER = "Y";

      NMI_WATCHDOG = 0;

      PLATFORM_PROFILE_ON_BAT = "low-power";
      PLATFORM_PROFILE_ON_AC = "performance";

      WOL_DISABLE = "Y";
      RUNTIME_PM_DRIVER_DENYLIST = "";

      INTEL_GPU_MIN_FREQ_ON_BAT = 300;
      INTEL_GPU_MAX_FREQ_ON_BAT = 500;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 500;
    };
  };

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
