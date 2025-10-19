#!/usr/bin/env bash

# Get CPU name
CPU_NAME=$(lscpu | grep "Model name:" | sed 's/Model name:[[:space:]]*//' | sed 's/(R)//g;s/(TM)//g;s/  */ /g')

# Get CPU usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
CPU_USAGE_INT=$(printf "%.0f" "$CPU_USAGE")

# Get CPU temperature
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP_C=$((TEMP / 1000))
else
    # Fallback to sensors if available
    TEMP_C=$(sensors | grep -i 'Package id 0:' | awk '{print $4}' | sed 's/+//;s/°C//' | cut -d'.' -f1)
    if [ -z "$TEMP_C" ]; then
        TEMP_C=$(sensors | grep -i 'Tdie:' | awk '{print $2}' | sed 's/+//;s/°C//' | cut -d'.' -f1)
    fi
fi

# Get CPU frequency
AVG_FREQ=$(awk '{s+=$1} END {printf "%.2f", s/NR/1000000}' /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null || echo "N/A")

# Output JSON for waybar
printf '{"text":"󰍛 %d%% ", "tooltip":"CPU: %s\\nUsage: %d%%\\nTemp: %d°C\\nAvg Freq: %s GHz"}\n' "$CPU_USAGE_INT" "$CPU_NAME" "$CPU_USAGE_INT" "$TEMP_C" "$AVG_FREQ"
