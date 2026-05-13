#!/bin/bash

# brave-cava-launcher.sh
# will open Brave Origin in workspace 2, with a ghostty window under it
# running cava with a smaller window size. 

# 1. Switch to workspace 2 first so the split happens there
hyprctl dispatch workspace 2

# 2. Launch Brave Beta into workspace 2 specifically
hyprctl dispatch exec "[workspace 2 silent] brave-origin-beta"

# 3. Wait for Brave Beta to be recognized by the compositor
while [ -z "$(hyprctl clients | grep "initialClass: brave-origin-beta")" ]; do
    sleep 0.1
done

# 4. Force the cava window to split vertically (underneath)
hyprctl dispatch layoutmsg preselect d

# 5. Launch Ghostty for cava into workspace 2
hyprctl dispatch exec "[workspace 2 silent] ghostty --title=cava -e cava"

# 6. Wait for the cava window to appear
while [ -z "$(hyprctl clients | grep "title: cava")" ]; do
    sleep 0.1
done

# 7. Final cleanup and resize
sleep 0.5
hyprctl dispatch workspace 2
hyprctl dispatch resizewindowpixel 0 200,class:brave-origin-beta
