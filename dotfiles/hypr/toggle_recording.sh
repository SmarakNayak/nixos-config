#!/usr/bin/env bash
set -euo pipefail

notify() {
  command -v notify-send >/dev/null && notify-send -a wf-recorder "$@"
}

if pgrep -x wf-recorder >/dev/null; then
  pkill -INT -x wf-recorder
  notify "Screen recording stopped"
  exit 0
fi

mkdir -p "$HOME/Videos"
output="$HOME/Videos/screenrecord-$(date +%Y%m%d-%H%M%S).mp4"
monitor="$(hyprctl monitors | awk '/^Monitor / { name = $2 } /focused: yes/ { print name; exit }')"

if [ -z "$monitor" ]; then
  notify -u critical "Screen recording failed" "Could not detect focused monitor"
  exit 1
fi

# wf-recorder tags output as full-range but swscale defaults to limited-range
# data, washing out colors. Force full-range data to match the tag.
wf-recorder -l -o "$monitor" \
  -F "scale=in_range=pc:out_range=pc:out_color_matrix=bt709,format=yuv420p" \
  -p x264-params=colorprim=bt709:transfer=bt709:colormatrix=bt709 \
  -f "$output" &>/dev/null &
notify "Screen recording started" "$output"
