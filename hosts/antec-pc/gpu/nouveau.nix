{
  services.xserver.videoDrivers = [ "nouveau" ];

  hardware.graphics.enable = true;

  # Load Nouveau explicitly after mounting the real root. Including it in the
  # initrd pulled in enough NVIDIA firmware to exhaust the /boot ESP.
  boot.kernelModules = [ "nouveau" ];
}
