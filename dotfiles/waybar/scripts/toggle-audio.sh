#!/usr/bin/env bash

# Get current default sink ID (only from Sinks section)
CURRENT=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep "\*" | head -n1 | grep -oP '^\s*\│?\s*\*?\s*\K\d+' | head -1)

# Get sink IDs dynamically by searching for device names
HYPERX_ID=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -i "HyperX" | head -n1 | grep -oP '^\s*\│?\s*\*?\s*\K\d+' | head -1)
STARSHIP_ID=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -i "Starship" | head -n1 | grep -oP '^\s*\│?\s*\*?\s*\K\d+' | head -1)

# Toggle between HyperX and Starship
if [[ "$CURRENT" == "$HYPERX_ID" ]] && [[ -n "$STARSHIP_ID" ]]; then
    wpctl set-default "$STARSHIP_ID"
elif [[ -n "$HYPERX_ID" ]]; then
    wpctl set-default "$HYPERX_ID"
fi

# Send signal to Waybar to update immediately (signal 8)
pkill -RTMIN+8 waybar
