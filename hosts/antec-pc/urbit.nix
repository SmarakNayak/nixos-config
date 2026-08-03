{ config, lib, pkgs, ... }:

let
  ship = "dalwel-walrum";
  stateDir = "/var/lib/urbit";
  pier = "${stateDir}/${ship}";
  httpPort = 8080;
in
{
  users.groups.urbit = { };
  users.users.urbit = {
    isSystemUser = true;
    group = "urbit";
    home = stateDir;
  };

  age.secrets.dalwel-walrum-key = {
    file = ../../secrets/dalwel-walrum-1.key.age;
    owner = "urbit";
    group = "urbit";
    mode = "0400";
  };

  # The key is consumed only when creating the pier. Once the pier exists this
  # unit is skipped, so a rebuild can never accidentally initialize it twice.
  systemd.services.urbit-bootstrap = {
    description = "Initialize the ~${ship} Urbit pier";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "!${pier}/.urb";

    serviceConfig = {
      Type = "oneshot";
      User = "urbit";
      Group = "urbit";
      StateDirectory = "urbit";
      WorkingDirectory = stateDir;
      ExecStart = lib.concatStringsSep " " [
        (lib.getExe pkgs.urbit)
        "-t"
        "-x"
        "-w ${ship}"
        "-k ${config.age.secrets.dalwel-walrum-key.path}"
        "-c ${pier}"
      ];
      TimeoutStartSec = "infinity";
      UMask = "0077";
    };
  };

  systemd.services.urbit = {
    description = "Urbit ship ~${ship}";
    after = [ "network-online.target" "urbit-bootstrap.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathIsDirectory = "${pier}/.urb";

    serviceConfig = {
      Type = "simple";
      User = "urbit";
      Group = "urbit";
      StateDirectory = "urbit";
      WorkingDirectory = stateDir;
      ExecStart = lib.concatStringsSep " " [
        (lib.getExe pkgs.urbit)
        "-t"
        "-b 0.0.0.0"
        "--http-port ${toString httpPort}"
        pier
      ];
      Restart = "on-failure";
      RestartSec = "10s";
      TimeoutStopSec = "5min";
      UMask = "0077";
    };
  };

  # Landscape is reachable from the local Wi-Fi and tailnet, but not from
  # other network interfaces. Urbit's Ames traffic remains outbound-only.
  networking.firewall.interfaces.wlp2s0.allowedTCPPorts = [ httpPort ];
  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ httpPort ];
}
