#!/usr/bin/env sh
if [[ $(hyprctl monitors -j | jq -r ".[] | .specialWorkspace.name") != "special:magic" ]]; then
    hyprctl dispatch togglespecialworkspace magic
fi
