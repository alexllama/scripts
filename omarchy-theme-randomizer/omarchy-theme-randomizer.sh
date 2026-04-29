#!/bin/bash

# Title: omarchy-theme-randomizer
# Author: Alex Llama (with help from Gemini)
# Date: 16 APR 2026
# Description: changes to a random theme from both default and extra themes
# uses a separate text file for themes to ignore (since you can't delete
# default themes easily). also selects a random wallpaper from the theme.
# I have it set to SUPER+ALT+R for the keyboard shortcut, and in hypridle 
# to change theme after the monitor wakes back up

# add a sleep call to give enough time for the monitor is fully awake
sleep 1

# 1. Setup Paths
# Automatically finds the directory where this script lives
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

LOCAL_THEMES="$HOME/.local/share/omarchy/themes"
CONFIG_THEMES="$HOME/.config/omarchy/themes"
IGNORE_FILE="$SCRIPT_DIR/ignore_themes.txt"

# 2. Build the full list of available themes
ALL_THEMES=$(ls "$LOCAL_THEMES" "$CONFIG_THEMES" 2>/dev/null | sort -u)

# 3. Filter using the ignore file
if [ -f "$IGNORE_FILE" ]; then
    SELECTED_THEME=$(echo "$ALL_THEMES" | grep -vFf "$IGNORE_FILE" | shuf -n 1)
else
    echo "Warning: Ignore file not found at $IGNORE_FILE. Picking from all themes."
    SELECTED_THEME=$(echo "$ALL_THEMES" | shuf -n 1)
fi

# 4. Apply the UI Theme
if [ -n "$SELECTED_THEME" ]; then
    echo "Setting theme: $SELECTED_THEME"
    omarchy-theme-set "$SELECTED_THEME"
    
    # 5. Background Selection Logic
    # Check config first, then fall back to local share
    BG_DIR="$CONFIG_THEMES/$SELECTED_THEME/backgrounds"
    [ ! -d "$BG_DIR" ] && BG_DIR="$LOCAL_THEMES/$SELECTED_THEME/backgrounds"

    if [ -d "$BG_DIR" ] && [ "$(ls -A "$BG_DIR")" ]; then
        SELECTED_BG=$(find "$BG_DIR" -type f | shuf -n 1)
        
        # Use the native Omarchy background setter
        echo "Setting background: $(basename "$SELECTED_BG")"
        omarchy-theme-bg-set "$SELECTED_BG"
        BG_NAME=$(basename "$SELECTED_BG")        
    else
        BG_NAME="Default"
    fi
    notify-send -a "Omarchy" -u normal "Theme Randomizer" "Now active: $SELECTED_THEME\nWallpaper: $BG_NAME"
else
    notify-send -a "Omarchy" -u normal "Theme Randomizer" "Error: No themes detected in search paths."
fi
