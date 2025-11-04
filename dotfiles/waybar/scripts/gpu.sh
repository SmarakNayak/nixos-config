#!/usr/bin/env bash

# Get GPU stats using nvidia-smi
if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
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

# Fallback to Intel GPU tools
elif command -v nvtop &> /dev/null && command -v intel_gpu_top &> /dev/null && command -v jq &> /dev/null; then
    # Get GPU name and MHz from nvtop snapshot mode
    NVTOP_DATA=$(nvtop -s 2>/dev/null)
    GPU_NAME=$(echo "$NVTOP_DATA" | grep -oP '"device_name": "\K[^"]+' | head -1)
    GPU_MHZ=$(echo "$NVTOP_DATA" | grep -oP '"gpu_clock": "\K[0-9]+' | head -1)

    # Get GPU usage from nvtop ncurses output
    NVTOP_RAW=$(timeout 3 nvtop -d 2 -p -P -C 2>&1 | cat -A)
    GPU_USAGE=$(echo "$NVTOP_RAW" | grep -oP '\d+%' | tail -1 | tr -d '%')

    # Debug output
    echo "GPU_MHZ: $GPU_MHZ" >&2
    echo "GPU_USAGE: $GPU_USAGE" >&2
    echo "NVTOP_RAW full output:" >&2
    echo "$NVTOP_RAW" >&2
    echo "=== END NVTOP_RAW ===" >&2

    # Get Package power from intel_gpu_top
    INTEL_DATA=$(timeout 1 intel_gpu_top -J -s 2000 -o - 2>/dev/null)
    PKG_POWER=$(echo "$INTEL_DATA" | sed '1s/^\[//' | jq -r '.power.Package // 0' 2>/dev/null)

    if [ -n "$GPU_NAME" ]; then
        printf '{"text":"󰢮 %d%% ", "tooltip":"GPU: %s\\nUsage: %d%%\\nFreq: %dMHz\\nPower: %.1fW"}\n' \
            "${GPU_USAGE:-0}" "${GPU_NAME:-Unknown GPU}" "${GPU_USAGE:-0}" "${GPU_MHZ:-0}" "${PKG_POWER:-0}"
    else
        printf '{"text":"󰢮 N/A ", "tooltip":"Could not read GPU data"}\n'
    fi

else
    printf '{"text":"󰢮 N/A ", "tooltip":"No GPU monitoring tools found"}\n'
fi
