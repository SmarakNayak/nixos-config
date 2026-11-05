{ ... }:

{
  services.flatpak = {
    enable = true;
    packages = [
      "org.telegram.desktop"
      "com.bambulab.BambuStudio"
    ];

    update.auto = {
      enable = true;
      onCalendar = "daily";
    };
  };
}
