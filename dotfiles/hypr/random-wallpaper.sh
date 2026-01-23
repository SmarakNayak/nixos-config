#!/usr/bin/env bash

# Wait for hyprpaper to be ready
sleep 1

WALLPAPER_DIR="$HOME/nixos-config/wallpapers/catppuccin-mocha"

# Pick a random wallpaper (excluding README.md and gifs)
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)

# Set wallpaper on all monitors
for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do
    hyprctl hyprpaper wallpaper "$monitor,$WALLPAPER"
done
