{ config, ... }:

{
  # This selects the proprietary driver without enabling X11.
  services.xserver.videoDrivers = [ "nvidia" ];

  nixpkgs.config.nvidia.acceptLicense = true;

  hardware = {
    graphics.enable = true;

    nvidia = {
      modesetting.enable = true;

      # Last proprietary driver branch supporting Kepler GPUs.
      package = config.boot.kernelPackages.nvidiaPackages.legacy_470;

      # nvidia-settings is graphical and is unnecessary on this headless host.
      nvidiaSettings = false;
    };
  };
}
