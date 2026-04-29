#!/bin/bash

# chromium-cava-launcher.sh
# will open Chromium in workspace 2, with a ghostty window under it
# running cava with a smaller window size. 

# 1. Switch to workspace 2 first so the split happens there
hyprctl dispatch workspace 2

# 2. Launch Chromium with a 'movetoworkspacesilent' rule 
# This is a safety net in case the global window rule fails
hyprctl dispatch exec "[workspace 2 silent] chromium"

# 3. Wait for Chromium
while [ -z "$(hyprctl clients | grep "initialClass: chromium")" ]; do
    sleep 0.1
done

# 4. Force the cava window to split under (vertically) the current one
hyprctl dispatch layoutmsg preselect d

# 5. Launch Ghostty for cava into workspace 2 specifically
hyprctl dispatch exec "[workspace 2 silent] ghostty --title=cava -e cava"

# 6. Final cleanup: Ensure we are looking at workspace 2 and resize
sleep 0.5
hyprctl dispatch workspace 2
hyprctl dispatch resizewindowpixel 0 200,class:chromium
