#!/usr/bin/env bash
if [[ $(hyprctl monitors -j | jq -r '.[] | select(.focused) | .specialWorkspace.name') == "special:magic" ]]; then
    hyprctl dispatch togglespecialworkspace magic
fi
