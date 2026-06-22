{ ... }:

{
  services.flatpak = {
    enable = true;
    packages = [ "org.telegram.desktop" ];

    update.auto = {
      enable = true;
      onCalendar = "daily";
    };
  };
}
