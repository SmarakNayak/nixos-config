#!/usr/bin/env bash

# Get current default sink (only from Sinks section, before Sources section)
CURRENT_LINE=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep "\*" | head -n1)
CURRENT=$(echo "$CURRENT_LINE" | sed 's/.*\*[[:space:]]*[0-9]*\.[[:space:]]*//' | sed 's/[[:space:]]*\[vol:.*\]//' | xargs)

# Get volume percentage
VOLUME=$(echo "$CURRENT_LINE" | grep -oP 'vol: \K[0-9.]+' | awk '{printf "%.0f", $1 * 100}')

# Shorten the names for display
if echo "$CURRENT" | grep -q "HyperX"; then
    OUTPUT="🎧 HyperX ${VOLUME}%"
elif echo "$CURRENT" | grep -q "Starship"; then
    OUTPUT="🔊 Logitech ${VOLUME}%"
else
    OUTPUT="🔊 Audio ${VOLUME}%"
fi

# Escape special characters for JSON
CURRENT_ESCAPED=$(echo "$CURRENT" | sed 's/\\/\\\\/g; s/"/\\"/g')

printf '{"text":"%s", "tooltip":"%s"}\n' "$OUTPUT" "$CURRENT_ESCAPED"
