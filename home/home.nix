{ config, pkgs, lib, ... }:

let
  claude-distro = import ../packages/claude-distrobox.nix { inherit pkgs; };
  facefusion = import ../packages/facefusion.nix { inherit pkgs; };
  krita-ai-diffusion = import ../packages/krita-ai-diffusion.nix { inherit pkgs; };
  whatsapp-web = import ../packages/whatsapp-web.nix { inherit pkgs; };
  messenger-web = import ../packages/messenger-web.nix { inherit pkgs; };
  krita-vision-tools = import ../packages/krita-vision-tools.nix { inherit pkgs; };
  krita-with-ai = pkgs.krita.overrideAttrs (old: {
    buildCommand = ''
      ${old.buildCommand or ""}
      wrapProgram $out/bin/krita \
        --prefix QT_PLUGIN_PATH : ${pkgs.qt5.qtimageformats}/${pkgs.qt5.qtbase.qtPluginPrefix} \
        --prefix XDG_DATA_DIRS : ${krita-ai-diffusion}/share \
        --prefix XDG_DATA_DIRS : ${krita-vision-tools}/share
    '';
  });
in
{
  imports = [
    ./core.nix
    ../modules/email.nix
    ../modules/dolphin.nix
  ];

  home.packages = with pkgs; [
    distrobox
    claude-distro
    facefusion
    comfy-ui-cuda
    networkmanagerapplet
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    wl-clipboard
    ollama
    ghostty
    wofi
    waybar
    google-chrome
    pavucontrol
    blueman
    mission-center
    signal-desktop
    discord
    whatsapp-web
    messenger-web
    gamescope
    mangohud
    heroic
    davinci-resolve
    mpv
    spotify
    imv
    zathura
    pinta
    krita-with-ai
    proton-vpn
    qalculate-gtk
    libreoffice
    rstudioWrapper
    stability-matrix
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhsWithPackages (pkgs: with pkgs; [
      rustup
      gcc
      pkg-config
      openssl.dev
    ]);
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # GTK_USE_PORTAL = "1"; #not needed for modern apps i.e. gtk>4
  };

  dconf.settings."org/gnome/desktop/interface" = {
    gtk-enable-primary-paste = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "org.kde.dolphin.desktop";
      "text/csv" = "calc.desktop";
    };
  };

  xdg.configFile."waybar/config.jsonc".source = ../dotfiles/waybar/config.jsonc;
  xdg.configFile."waybar/config-niri.jsonc".source = ../dotfiles/waybar/config-niri.jsonc;
  xdg.configFile."waybar/style.css".source = ../dotfiles/waybar/style.css;
  xdg.configFile."waybar/scripts" = {
    source = ../dotfiles/waybar/scripts;
    recursive = true;
  };
  xdg.configFile."ghostty/config.ghostty".source = ../dotfiles/ghostty/config;
  xdg.configFile."ghostty/hetzner-green.conf".source = ../dotfiles/ghostty/hetzner-green.conf;
  xdg.configFile."ghostty/hetzner-blue.conf".source = ../dotfiles/ghostty/hetzner-blue.conf;
  xdg.configFile."mako/config".source = ../dotfiles/mako/config;

  xdg.desktopEntries.google-chrome = {
    name = "Google Chrome";
    exec = "google-chrome-stable --disable-features=WaylandWpColorManagerV1 %U";
    icon = "google-chrome";
    type = "Application";
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "text/xml" ];
    actions = {};
  };

  xdg.desktopEntries.hetzner-green = {
    name = "Hetzner - Green";
    exec = "ghostty --config-file=${config.xdg.configHome}/ghostty/hetzner-green.conf";
    icon = "com.mitchellh.ghostty";
    type = "Application";
    categories = [ "System" "TerminalEmulator" ];
  };

  xdg.desktopEntries.hetzner-blue = {
    name = "Hetzner - Blue";
    exec = "ghostty --config-file=${config.xdg.configHome}/ghostty/hetzner-blue.conf";
    icon = "com.mitchellh.ghostty";
    type = "Application";
    categories = [ "System" "TerminalEmulator" ];
  };

  home.activation.clearWofiCache = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run rm -f $HOME/.cache/wofi-drun
  '';

  # Use home.activation instead of home.file for Variety script because:
  # - home.file creates read-only symlinks to Nix store
  # - Variety expects to manage its own ~/.config/variety/ directory
  # - Copying the script allows Variety to modify configs without breaking
  home.activation.installVarietyScript = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run mkdir -p $HOME/.config/variety/scripts
    run cp -f ${../dotfiles/variety/scripts/set_wallpaper} $HOME/.config/variety/scripts/set_wallpaper
    run chmod +x $HOME/.config/variety/scripts/set_wallpaper
  '';
}
