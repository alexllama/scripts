#!/bin/bash

CITIES_FILE="./cities.json"
WEATHER_UPDATE_INTERVAL=180  # 3 hours in minutes
TIME_UPDATE_INTERVAL=1       # 1 minute

# Colors (cycle through a few)
COLORS=("\033[0;31m" "\033[0;32m" "\033[0;34m" "\033[1;33m" "\033[0;35m" "\033[0;36m")
NC="\033[0m"

WEATHER_CACHE_DIR="/tmp/clox_weather_cache_simple"
mkdir -p "$WEATHER_CACHE_DIR"

weather_update_counter=180
last_weather_update=""

# Fetch weather with caching
fetch_weather() {
    local wttrname="$1"
    local displayname="$2"
    local cache_file="$WEATHER_CACHE_DIR/${wttrname// /_}"
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $((WEATHER_UPDATE_INTERVAL*60)) ]]; then
            cat "$cache_file"
            return 0
        fi
    fi
    local encoded_city_name=$(printf %s "$wttrname" | jq -s -R -r @uri)
    local weather_data=$(curl -s --max-time 10 "wttr.in/$encoded_city_name?format=3")
    # Replace wttrname with displayname in the weather output (only at the start)
    weather_data=$(echo "$weather_data" | sed "s/^$wttrname/$displayname/")
    echo "$weather_data" > "$cache_file"
    echo "$weather_data"
}

main() {
    while true; do
        mapfile -t displaynames < <(jq -r '.[].displayname' "$CITIES_FILE")
        mapfile -t wttrnames < <(jq -r '.[].wttrname' "$CITIES_FILE")
        mapfile -t tzs < <(jq -r '.[].tz' "$CITIES_FILE")

        # Weather update (every 3 hours)
        if (( weather_update_counter >= WEATHER_UPDATE_INTERVAL )) || [[ -z "$last_weather_update" ]]; then
            for i in "${!displaynames[@]}"; do
                fetch_weather "${wttrnames[i]}" "${displaynames[i]}" > /dev/null
            done
            last_weather_update=$(date +'%a, %b %d %I:%M %p')
            weather_update_counter=0
        fi

        clear
        echo "-----------------------------"
        for i in "${!displaynames[@]}"; do
            color=${COLORS[$((i%${#COLORS[@]}))]}
            displayname="${displaynames[i]}"
            wttrname="${wttrnames[i]}"
            tz="${tzs[i]}"
            weather=$(cat "$WEATHER_CACHE_DIR/${wttrname// /_}")
            time=$(TZ="$tz" date +'%a, %b %d %I:%M %p')
            echo -e "${color}${weather}${NC}"
            echo -e "${color}${time}${NC}"
            echo "-----------------------------"
        done
        echo -e "Last weather update: $last_weather_update"
        ((weather_update_counter++))
        sleep $((TIME_UPDATE_INTERVAL * 60))
    done
}

main "$@" 