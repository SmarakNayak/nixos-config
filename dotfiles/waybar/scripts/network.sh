#!/usr/bin/env bash

# Cache file for speedtest results
CACHE_FILE="/tmp/waybar-speedtest-cache"
LOCK_FILE="/tmp/waybar-speedtest.lock"
CACHE_AGE_LIMIT=3600  # 1 hour in seconds

# Get network name
NETWORK=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
if [ -z "$NETWORK" ]; then
    # Try ethernet
    NETWORK=$(nmcli -t -f DEVICE,STATE,CONNECTION dev | grep ':connected:' | head -n1 | cut -d':' -f3)
fi

if [ -z "$NETWORK" ]; then
    NETWORK="Disconnected"
fi

# Check if cache exists and is fresh
if [ -f "$CACHE_FILE" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
    if [ $CACHE_AGE -lt $CACHE_AGE_LIMIT ]; then
        # Cache is fresh, use it
        SPEED=$(cat "$CACHE_FILE")
        printf '{"text":"%s", "tooltip":"%s"}\n' "$SPEED" "$NETWORK"
        exit 0
    fi
fi

# No cache or cache expired - show network name immediately
printf '{"text":"%s", "tooltip":"Running speedtest..."}\n' "$NETWORK"

# Start speedtest in background if not already running
if [ ! -f "$LOCK_FILE" ] && command -v speedtest-go &> /dev/null; then
    touch "$LOCK_FILE"
    (
        SPEEDTEST_OUTPUT=$(speedtest-go 2>&1)
        if [ $? -eq 0 ]; then
            DOWNLOAD=$(echo "$SPEEDTEST_OUTPUT" | awk '/^✓ Download:/ {print $3}')
            UPLOAD=$(echo "$SPEEDTEST_OUTPUT" | awk '/^✓ Upload:/ {print $3}')
            LATENCY=$(echo "$SPEEDTEST_OUTPUT" | awk '/^✓ Latency:/ {gsub(/ms/, "", $3); printf "%.0f", $3; exit}')
            SPEED="${DOWNLOAD}/${UPLOAD} ${LATENCY}ms"
            echo "$SPEED" > "$CACHE_FILE"
        fi
        rm -f "$LOCK_FILE"
    ) >/dev/null 2>&1 &
    disown
fi
