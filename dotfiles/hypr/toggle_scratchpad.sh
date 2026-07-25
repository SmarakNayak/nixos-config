#!/usr/bin/env bash
set -euo pipefail

# Toggle scratchpad on the focused monitor.
#
# Native `hl.dsp.workspace.toggle_special()` handles all of this by itself, but waybar
# only updates a workspace's monitor on explicit moveworkspacetomonitor
# events (Waybar #3731) — so hide, move, show manually. Once that bug is
# fixed, this entire script reduces to the corresponding `hyprctl eval` call.

special="special:magic"

focused="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')"
shown_on="$(hyprctl monitors -j | jq -r --arg s "$special" \
  '.[] | select(.specialWorkspace.name == $s) | .name')"

# State 1 — visible on this monitor: hide it, done.
if [[ "$shown_on" == "$focused" ]]; then
  hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("magic"))'
  exit 0
fi

# State 2 — visible on another monitor: hide it there first. Moving a
# visible special leaves an empty overlay on the old monitor otherwise.
if [[ -n "$shown_on" ]]; then
  hyprctl eval "hl.dispatch(hl.dsp.focus({ monitor = \"$shown_on\" }))"
  hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("magic"))'
  hyprctl eval "hl.dispatch(hl.dsp.focus({ monitor = \"$focused\" }))"
fi

# State 3 — hidden: move it here (fires the event waybar listens to),
# then show it — unless the move already activated it on this monitor,
# which moveworkspacetomonitor sometimes does.
hyprctl eval "hl.dispatch(hl.dsp.workspace.move({ workspace = \"$special\", monitor = \"$focused\" }))" \
  >/dev/null 2>&1 || true
now_shown="$(hyprctl monitors -j | jq -r --arg m "$focused" \
  '.[] | select(.name == $m) | .specialWorkspace.name')"
if [[ "$now_shown" != "$special" ]]; then
  hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("magic"))'
fi
