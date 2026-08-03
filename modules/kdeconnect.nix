{ ... }:

{
  # KDE Connect daemon + tray indicator: cross-device clipboard, file transfer
  # and notification sync between the desktops and the phone. Peers are paired
  # by Tailscale IP through the indicator (the tailnet has no UDP broadcast, so
  # LAN auto-discovery only works when devices share a physical network).
  #
  # This opens the default 1714-1764 range for LAN peers. Inbound over the
  # tailnet is opened separately in tailscale-client.nix, after that module's
  # blanket DROP on the tailscale interface.
  #
  # Clipboard auto-share is a per-device toggle set after pairing; until it is
  # enabled a copy stays local and is pushed only via the "Send clipboard"
  # action. Nothing here forces auto-share on.
  programs.kdeconnect.enable = true;
}
