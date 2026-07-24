{ config, lib, pkgs, ... }:

let
  cfg = config.miltu.btrfs.snapshots;
in
{
  options.miltu.btrfs.snapshots.enable = lib.mkEnableOption "/home and /var/lib Btrfs snapshots";

  config = lib.mkMerge [
    {
      # zstd gives a good space/speed trade-off. Compression only affects new
      # or rewritten extents; existing data is left untouched.
      fileSystems."/".options = [ "compress=zstd:3" ];

      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [ "/" ];
        interval = "monthly";
      };
    }

    (lib.mkIf cfg.enable {
      services.snapper = {
        # Long-term calendar history is created hourly. /home's short-term
        # 15-minute history is handled by the numbered snapshot timer below.
        snapshotInterval = "hourly";
        cleanupInterval = "1d";
        persistentTimer = true;

        configs.home = {
          SUBVOLUME = "/home";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = 24;
          TIMELINE_LIMIT_DAILY = 14;
          TIMELINE_LIMIT_WEEKLY = 8;
          TIMELINE_LIMIT_MONTHLY = 12;
          TIMELINE_LIMIT_QUARTERLY = 0;
          TIMELINE_LIMIT_YEARLY = 0;
          NUMBER_CLEANUP = true;
          NUMBER_MIN_AGE = 0;
          # Six numbered quarter-hour points plus the hourly timeline points
          # provide complete 15-minute coverage over the latest two hours.
          NUMBER_LIMIT = 6;
          NUMBER_LIMIT_IMPORTANT = 0;
        };

        configs."var-lib" = {
          SUBVOLUME = "/var/lib";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = 12;
          TIMELINE_LIMIT_DAILY = 14;
          TIMELINE_LIMIT_WEEKLY = 4;
          TIMELINE_LIMIT_MONTHLY = 6;
          TIMELINE_LIMIT_QUARTERLY = 0;
          TIMELINE_LIMIT_YEARLY = 0;
        };
      };

      # Snapper expects these directories to already be subvolumes.
      systemd.services.prepare-snapper-subvolumes = {
        description = "Create Snapper snapshot subvolumes";
        wantedBy = [ "multi-user.target" ];
        before = [ "snapper-timeline.service" "snapper-cleanup.service" ];
        requiredBy = [ "snapper-timeline.service" "snapper-cleanup.service" ];
        after = [ "local-fs.target" ];
        unitConfig.RequiresMountsFor = [ "/home" "/var/lib" ];
        serviceConfig.Type = "oneshot";
        script = ''
          for snapshot_dir in /home/.snapshots /var/lib/.snapshots; do
            if ! ${pkgs.btrfs-progs}/bin/btrfs subvolume show "$snapshot_dir" >/dev/null 2>&1; then
              ${pkgs.btrfs-progs}/bin/btrfs subvolume create "$snapshot_dir"
              ${pkgs.coreutils}/bin/chmod 0750 "$snapshot_dir"
            fi
          done
        '';
      };

      systemd.services.snapper-home-quarter-hour = {
        description = "Create the short-term /home Snapper snapshot";
        requires = [ "prepare-snapper-subvolumes.service" ];
        after = [ "prepare-snapper-subvolumes.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "snapper-home-quarter-hour" ''
            ${pkgs.snapper}/bin/snapper --config home create \
              --cleanup-algorithm number --description "15-minute"
            ${pkgs.snapper}/bin/snapper --config home cleanup number
          '';
        };
      };

      systemd.timers.snapper-home-quarter-hour = {
        description = "Create a /home snapshot every 15 minutes";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          # The timeline snapshot at :00 is the fourth point each hour.
          OnCalendar = "*:15,30,45";
          Persistent = true;
        };
      };
    })
  ];
}
