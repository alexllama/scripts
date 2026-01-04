#!/bin/bash

# System update checker. 
# Checks for any Manjaro/Arch updates. Is intended to be run when the system
# starts up and sends a popup notification with notify-send, which the Caelestia
# system will display on the top right of the screen

# Give the desktop environment a moment to initialize the notification server
sleep 1

# Check for both Pacman and AUR updates using yay -Qu
# This is the most efficient way for Arch/Manjaro packages.
# The 2>/dev/null suppresses any error messages from the command.
UPDATE_COUNT=$(checkupdates 2>/dev/null | wc -l)

# --- Send Notification ---

if [ "$UPDATE_COUNT" -gt 0 ]; then
    # Use notify-send, which the Caelestia/Quickshell notification daemon will pick up
    /usr/bin/notify-send --icon /home/alexl/Pictures/llamalogo/llamalogo_icon_black.gif \
        -u normal -a "System Updates"  \
        "$UPDATE_COUNT Manjaro Update(s) Available!" 
else
    # Optional: Send a success notification (use -u low if you want it subtle/to auto-close)
    /usr/bin/notify-send --icon /home/alexl/Pictures/llamalogo/llamalogo_icon_black.gif \
        -u low -a "System Updates" \
        "System is Up-to-Date." \
        "Last check: $(date +%H:%M)"
fi
