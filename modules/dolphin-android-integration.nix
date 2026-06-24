{ pkgs, ... }:

{
  # Recognize Android devices exposed over MTP.
  services.udev.packages = [ pkgs.libmtp.out ];

  # Expose the MTP worker, Qt plugin and D-Bus activation service system-wide,
  # as Plasma does for Dolphin.
  environment.systemPackages = [ pkgs.kdePackages.kio-extras ];
}
