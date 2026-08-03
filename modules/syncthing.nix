{ config, lib, ... }:

let
  devices = {
    antec-pc = {
      id = "65CPDZ5-R6AFPR7-YLK534U-UYP737R-XMV7RJD-YXJHEJF-CKL6DLK-FJB6JA2";
      addresses = [
        "tcp://antec-pc:22000"
        "quic://antec-pc:22000"
      ];
    };

    louqe-pc = {
      id = "T7ETYJZ-PQ3ZXFO-6GCU6ZI-65OIZ4F-BDCOQLV-CIHSXUR-3OGWHDC-2VTC6AX";
      addresses = [
        "tcp://louqe-pc:22000"
        "quic://louqe-pc:22000"
      ];
    };

    msi-laptop = {
      id = "FQ7RMTI-DOTBJV2-4YCXXXL-DHX2Y3P-5YQQFJU-I3CJLSW-ZOCJBF3-FMBARQG";
      addresses = [
        "tcp://msi-laptop:22000"
        "quic://msi-laptop:22000"
      ];
    };

    oneplus-12 = {
      id = "BLGNS36-WXSO5HJ-DH73CXB-PMZJVRF-67ZUJOD-Z6SMCJK-47DVBS6-NJKCVAP";
      addresses = [
        "tcp://oneplus-12:22000"
        "quic://oneplus-12:22000"
      ];
    };
  };

  remoteDevices = removeAttrs devices [ config.networking.hostName ];
in
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

    settings.devices = remoteDevices;

    settings.folders.shared = {
      path = "/home/miltu/shared";
      devices = lib.attrNames remoteDevices;
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/miltu/shared 0750 miltu users -"
  ];
}
