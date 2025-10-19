#!/usr/bin/env bash

# Get GPU stats using nvidia-smi
if command -v nvidia-smi &> /dev/null; then
    GPU_USAGE=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1)
    GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -n1)
    GPU_MEM_USED=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -n1)
    GPU_MEM_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1)
    GPU_MEM_PERCENT=$(awk "BEGIN {printf \"%.0f\", ($GPU_MEM_USED / $GPU_MEM_TOTAL) * 100}")
    GPU_POWER=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits | head -n1)
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)

    # Output JSON for waybar
    printf '{"text":"󰢮 %d%% ", "tooltip":"GPU: %s\\nUsage: %d%%\\nTemp: %d°C\\nVRAM: %dMB / %dMB (%d%%)\\nPower: %.1fW"}\n' \
        "$GPU_USAGE" "$GPU_NAME" "$GPU_USAGE" "$GPU_TEMP" "$GPU_MEM_USED" "$GPU_MEM_TOTAL" "$GPU_MEM_PERCENT" "$GPU_POWER"
else
    printf '{"text":"󰢮 N/A ", "tooltip":"nvidia-smi not found"}\n'
fi
