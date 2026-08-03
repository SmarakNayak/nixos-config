{ ... }:

{
  # Device and folder IDs are intentionally left mutable. Syncthing generates a
  # unique device ID on first start, and the Android peer is paired through the
  # web UI after installation.
  services.syncthing = {
    enable = true;
    user = "miltu";
    group = "users";
    dataDir = "/home/miltu/shared";
    configDir = "/home/miltu/.config/syncthing";

    # Open direct sync and LAN discovery ports. Public connectivity helpers are
    # disabled below; remote peers will use explicit Tailscale addresses.
    openDefaultPorts = true;
    settings.options = {
      relaysEnabled = false;
      natEnabled = false;
      globalAnnounceEnabled = false;
      localAnnounceEnabled = true;
      urAccepted = -1;
      crashReportingEnabled = false;
    };

    # Device names will be added after each peer has generated its identity.
    settings.folders.shared = {
      path = "/home/miltu/shared";
      devices = [ ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/miltu/shared 0750 miltu users -"
  ];
}
