#!/usr/bin/env bash

# Get current default sink (only from Sinks section, before Sources section)
CURRENT=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep "\*" | head -n1 | sed 's/.*\*[[:space:]]*[0-9]*\.[[:space:]]*//' | sed 's/[[:space:]]*\[vol:.*\]//' | xargs)

# Shorten the names for display
if echo "$CURRENT" | grep -q "HyperX"; then
    OUTPUT="🎧 HyperX"
elif echo "$CURRENT" | grep -q "Starship"; then
    OUTPUT="🔊 Logitech"
else
    OUTPUT="🔊 Audio"
fi

# Escape special characters for JSON
CURRENT_ESCAPED=$(echo "$CURRENT" | sed 's/\\/\\\\/g; s/"/\\"/g')

printf '{"text":"%s", "tooltip":"%s"}\n' "$OUTPUT" "$CURRENT_ESCAPED"
