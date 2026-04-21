{ pkgs, ... }:

let
  icon = pkgs.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/b/be/Facebook_Messenger_logo_2020.svg";
    hash = "sha256-1OXL8XgDKeZLKgVV8o1DfH/rMBnk++yaEUFrDjybdAg=";
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "messenger-web";
    desktopName = "Messenger";
    comment = "Facebook Messenger web wrapper";
    exec = "messenger-web %U";
    icon = "${icon}";
    categories = [ "Network" "InstantMessaging" ];
    startupWMClass = "messenger-web";
  };
in
pkgs.symlinkJoin {
  name = "messenger-web";
  paths = [
    (pkgs.writeShellScriptBin "messenger-web" ''
      exec ${pkgs.google-chrome}/bin/google-chrome-stable \
        --app=https://www.messenger.com \
        --class=messenger-web \
        "$@"
    '')
    desktopItem
  ];
}
