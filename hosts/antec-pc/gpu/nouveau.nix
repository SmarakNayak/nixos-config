{
  services.xserver.videoDrivers = [ "nouveau" ];

  hardware.graphics.enable = true;

  # Load Nouveau in the initrd so it can take over the framebuffer early and
  # provide its native-resolution console rather than retaining simpledrm.
  boot.initrd.kernelModules = [ "nouveau" ];
}
