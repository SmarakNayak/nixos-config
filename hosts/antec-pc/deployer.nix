{ config, lib, pkgs, self, ... }:

let
  repo = "SmarakNayak/nixos-config";
  attr = "antec-pc";
  branch = "main";
in

{
  # Separate Telegram bot from Hermes. This token must NOT be reachable by the
  # hermes account - it is the credential that authorizes a real deploy. Owned
  # by root because this service runs nixos-rebuild.
  age.secrets.deployer-telegram-bot-token = {
    file = ../../secrets/deployer-telegram-bot-token.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # The allowlist: the id of YOUR private chat with the deployer bot. Only that
  # chat may drive deploys; messages from anyone else are ignored. A private
  # chat's id equals your Telegram user id, so this holds the same value as the
  # Hermes chat-id - but it is kept as its own dedicated secret so the deployer
  # never reaches into Hermes' files.
  age.secrets.deployer-telegram-chat-id = {
    file = ../../secrets/deployer-telegram-chat-id.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Bake the live flake revision into the system so `/status` can report which
  # commit is actually running. A `github:.../<sha>` build sets self.rev to that
  # SHA; a local working-tree rebuild leaves it unset and shows as "dirty".
  system.configurationRevision =
    if self ? rev then self.rev else "dirty";

  systemd.services.deployer = {
    description = "Telegram-driven nixos-rebuild for ${attr}";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    restartIfChanged = false;

    # Everything as packages, never bare path strings: NixOS feeds `path`
    # through makeBinPath, which appends /bin to each entry - so a string like
    # "/run/current-system/sw/bin" becomes ".../bin/bin" and nixos-rebuild is
    # never found. Use the built derivations instead.
    path = [
      config.system.build.nixos-rebuild  # the nixos-rebuild command itself
      config.nix.package                 # nix
      pkgs.git                           # flake fetch from GitHub
      pkgs.coreutils
      pkgs.systemd                       # nixos-rebuild drives the switch via systemd-run
    ];

    environment = {
      DEPLOYER_BOT_TOKEN_FILE = config.age.secrets.deployer-telegram-bot-token.path;
      DEPLOYER_CHAT_ID_FILE = config.age.secrets.deployer-telegram-chat-id.path;
      DEPLOYER_REPO = repo;
      DEPLOYER_ATTR = attr;
      DEPLOYER_BRANCH = branch;
    };

    # Restart when the token or the bot code changes so updates take effect on
    # the next rebuild without a manual `systemctl restart`.
    restartTriggers = [
      config.age.secrets.deployer-telegram-bot-token.file
      ./deployer-bot.py
    ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.python3}/bin/python3 ${./deployer-bot.py}";
      Restart = "always";
      RestartSec = "10s";

      # Root is required: `nixos-rebuild switch` activates a new system
      # generation, restarts units, and updates the bootloader. The trust
      # boundary for this service is the Telegram allowlist plus the
      # code-owner-gated main branch - not OS sandboxing of the unit itself.
      User = "root";
    };
  };
}
