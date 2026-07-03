{ pkgs, ... }:

{
  # antec-pc root over sshfs, mounted on demand via Tailscale MagicDNS (works on LAN and
  # remote). Access is enforced remotely as miltu, whose hermes group membership covers
  # /var/lib/hermes (2770).
  system.fsPackages = [ pkgs.sshfs ];
  fileSystems."/mnt/antec-pc" = {
    device = "miltu@antec-pc:/";
    fsType = "sshfs";
    options = [
      "noauto"
      "x-systemd.automount"          # mount on first access
      "x-systemd.idle-timeout=300"   # unmount after 5 min idle
      "x-systemd.mount-timeout=15"   # fail fast when antec-pc is off
      "_netdev"
      "reconnect"
      "ServerAliveInterval=15"
      "ServerAliveCountMax=3"
      "IdentityFile=/home/miltu/.ssh/antec-admin"
      "UserKnownHostsFile=/home/miltu/.ssh/known_hosts"
      "allow_other"                  # mount runs as root; map access back to miltu
      "uid=1000"
      "gid=100"
    ];
  };
}
