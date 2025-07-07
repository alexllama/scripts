#!/bin/bash

CITIES_FILE="./cities.json"

# Initialize a counter to track minutes for weather updates
weather_update_counter=180 # Set to 180 to force update on first run

# Declare arrays to hold data
declare -a names
declare -a tzs
declare -a times
declare -a weathers

while true; do
    # --- Weather Update (every 3 hours) ---
    if (( weather_update_counter >= 180 )); then
        # Read city data into arrays
        mapfile -t names < <(jq -r '.[].name' "$CITIES_FILE")
        mapfile -t tzs < <(jq -r '.[].tz' "$CITIES_FILE")

        # Reset weathers array for fresh data
        weathers=()
        # Fetch new weather data
        for i in "${!names[@]}"; do
            encoded_city_name=$(printf %s "${names[i]}" | jq -s -R -r @uri)
            weather_data=$(curl -s "wttr.in/$encoded_city_name?format=%C+%t")
            weathers+=("$(echo "$weather_data" | xargs)")
        done
        # Reset counter
        weather_update_counter=0
    fi

    # --- Time Update (every minute) ---
    times=()
    for i in "${!names[@]}"; do
        times+=("$(TZ="${tzs[$i]}" date +'%a, %b %d %I:%M %p')")
    done

    # --- Display Update (every minute) ---
    clear
    num_cities=${#names[@]}

    # --- PASS 1: Calculate maximum column widths across ALL rows ---
    max_width1=0
    max_width2=0
    for ((i=0; i<num_cities; i++)); do
        len_name=${#names[i]}
        len_time=${#times[i]}
        len_weather=${#weathers[i]}
        max_len=$(( len_name > len_time ? len_name : len_time ))
        max_len=$(( max_len > len_weather ? max_len : len_weather ))

        if (( i % 2 == 0 )); then # First column city
            if (( max_len > max_width1 )); then max_width1=$max_len; fi
        else # Second column city
            if (( max_len > max_width2 )); then max_width2=$max_len; fi
        fi
    done

    # --- PASS 2: Build and print the table using max widths ---
    for ((i=0; i<num_cities; i+=2)); do
        has_second_col=0
        if (( i + 1 < num_cities )); then
            has_second_col=1
        fi

        # Build border line
        border="+-"
        for ((j=0; j<max_width1; j++)); do border+="-"; done
        border+="-+"
        if (( has_second_col )); then
            for ((j=0; j<max_width2; j++)); do border+="-"; done
            border+="-+"
        fi

        # Build data lines
        if (( has_second_col )); then
            line_names=$(printf "| %-${max_width1}s | %-${max_width2}s |" "${names[i]}" "${names[i+1]}")
            line_times=$(printf "| %-${max_width1}s | %-${max_width2}s |" "${times[i]}" "${times[i+1]}")
            line_weathers=$(printf "| %-${max_width1}s | %-${max_width2}s |" "${weathers[i]}" "${weathers[i+1]}")
        else
            line_names=$(printf "| %-${max_width1}s |" "${names[i]}")
            line_times=$(printf "| %-${max_width1}s |" "${times[i]}")
            line_weathers=$(printf "| %-${max_width1}s |" "${weathers[i]}")
        fi

        # Print the row
        echo "$border"
        echo "$line_names"
        echo "$line_times"
        echo "$line_weathers"
        echo "$border"
    done

    # Increment the counter and sleep for a minute
    ((weather_update_counter++))
    sleep 60
done
