#!/bin/bash

# unlock-listener.sh
# used to change to a random theme when the screen unlocks
# though could be used to trigger other things on an unlock

#!/bin/bash

# Path to your shuffle script
SHUFFLE_SCRIPT="$HOME/dev/scripts/omarchy-theme-randomizer/omarchy-theme-randomizer.sh"
WAS_LOCKED=false

echo "Unlock listener started at $(date)"

while true; do
    # Check if any hyprlock process is running
    if pgrep -x "hyprlock" > /dev/null; then
        WAS_LOCKED=true
    else
        # If it was locked but hyprlock is now gone, it's an unlock event
        if [ "$WAS_LOCKED" = true ]; then
            echo "Unlock detected! Shuffling theme..."
            $SHUFFLE_SCRIPT &
            WAS_LOCKED=false
        fi
    fi
    # Check every 2 seconds (very low CPU usage)
    sleep 2
done
