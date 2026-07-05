#!/usr/bin/env bash
if [[ $(hyprctl monitors -j | jq -r '.[] | select(.focused) | .specialWorkspace.name') != "special:magic" ]]; then
    ~/.config/hypr/toggle_scratchpad.sh
fi
