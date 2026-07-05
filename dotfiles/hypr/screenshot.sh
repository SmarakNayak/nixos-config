#!/usr/bin/env bash
set -euo pipefail

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"

# Satty prefers its remembered last Save As dir over the output-filename dir;
# clear it so the dialog always opens in $dir
rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/satty/save_as_last_dir"

# A click on the notification reveals the file in Dolphin
notify_saved() {
  local action
  action="$(notify-send -a satty -A default="Open folder" "Screenshot saved" "$1")" || true
  [ "$action" = "default" ] && dolphin --select "$1" &
}

# Copy immediately on capture; satty's --auto-copy only re-copies on annotation.
# Satty logs "File saved to '<path>'." on every save/save-as — notify from that.
grim -g "$(slurp)" - | tee >(wl-copy -t image/png) \
  | satty -f - --output-filename "$file" --disable-notifications --auto-copy 2>&1 \
  | while IFS= read -r line; do
      case "$line" in
        "File saved to '"*)
          saved="${line#File saved to \'}"
          notify_saved "${saved%\'.}" &
          ;;
      esac
    done
