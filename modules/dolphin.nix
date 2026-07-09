# Dolphin file manager + KIO integration for a standalone Wayland session
# (no full Plasma). Self-contained: installs Dolphin and the two bits of glue a
# full KDE Plasma session would otherwise provide for free.
#
# 1. applications.menu
#    KService builds its KSycoca cache - the application database behind
#    Dolphin's "Open With" - from a top-level freedesktop menu. Standalone
#    compositors ship none, so Dolphin's "Open With" list comes up empty. This
#    minimal menu just exposes every installed .desktop file. KF6 rebuilds the
#    cache in-process, so no kbuildsycoca6/kservice on PATH is needed; placing
#    it in ~/.config/menus (XDG_CONFIG_HOME, searched first) is enough.
#
# 2. Default terminal (ghostty)
#    KDE apps - e.g. Dolphin's F4 "Open Terminal" - read the terminal from
#    kdeglobals. We merge-write only those two keys with kwriteconfig6 rather
#    than owning the whole (KDE-mutable) file, which is all plasma-manager was
#    doing here anyway.
{ pkgs, lib, ... }:

{
  home.packages = with pkgs.kdePackages; [
    dolphin
    ark
    ffmpegthumbs # Video thumbnails.
    kdegraphics-thumbnailers # Extra document/graphics thumbnailers.
    kimageformats # AVIF/HEIF/JXL and other KDE image format plugins.
    qtimageformats # WebP and other Qt image format plugins.
  ];

  home.sessionVariables.QT_PLUGIN_PATH =
    lib.makeSearchPath pkgs.kdePackages.qtbase.qtPluginPrefix [
      pkgs.kdePackages.kdegraphics-thumbnailers
      pkgs.kdePackages.kimageformats
      pkgs.kdePackages.qtimageformats
    ];

  xdg.configFile."menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
      "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <Include>
        <All/>
      </Include>
    </Menu>
  '';

  home.activation.kdeDefaultTerminal =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # KIO spawns the terminal with cwd set but ghostty's single-instance
      # launch drops it; the flag makes it use the cwd (and any CLI arg
      # forces a dedicated instance). A TerminalService key would take
      # priority over this and launch via desktop file, bypassing the flag.
      run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
        --file kdeglobals --group General --key TerminalApplication \
        'ghostty --working-directory=inherit'
    '';
}
