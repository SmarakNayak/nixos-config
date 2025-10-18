#!/usr/bin/env bash

# Get current default sink ID (only from Sinks section)
CURRENT=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep "\*" | head -n1 | awk '{print $3}' | tr -d '.')

# Toggle between HyperX (48) and Starship (59)
if [[ "$CURRENT" == "48" ]]; then
    wpctl set-default 59
else
    wpctl set-default 48
fi

# Send signal to Waybar to update immediately (signal 8)
pkill -RTMIN+8 waybar
