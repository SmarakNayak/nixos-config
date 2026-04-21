{ pkgs, ... }:

let
  icon = pkgs.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg";
    hash = "sha256-6gBB5VXMxOVSGzOJ7W2GpI2sAPtOiMZxb+RYUNbZD1I=";
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "whatsapp-web";
    desktopName = "WhatsApp";
    comment = "WhatsApp Web wrapper";
    exec = "whatsapp-web %U";
    icon = "${icon}";
    categories = [ "Network" "InstantMessaging" ];
    startupWMClass = "whatsapp-web";
  };
in
pkgs.symlinkJoin {
  name = "whatsapp-web";
  paths = [
    (pkgs.writeShellScriptBin "whatsapp-web" ''
      exec ${pkgs.chromium}/bin/chromium \
        --app=https://web.whatsapp.com \
        --class=whatsapp-web \
        "$@"
    '')
    desktopItem
  ];
}
