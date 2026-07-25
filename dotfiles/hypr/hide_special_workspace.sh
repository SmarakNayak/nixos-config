#!/usr/bin/env bash
if [[ $(hyprctl monitors -j | jq -r '.[] | select(.focused) | .specialWorkspace.name') == "special:magic" ]]; then
    hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("magic"))'
fi
