Make a command line application that will display the time and weather at a number of world locations. Here are the requirements
1. It will update every minute
2. The list of cities will be stored in a json file. the configuration file will include the following 
- name of city to be displayed
- Initial file will include information for the following cities:
    - Hamlin, NY
    - Perth, Western Australia
    - Seattle, WA
    - Honolulu, HI
3. Displays the following information for each city: 
- Name of city
- Local time
- Local date
- Weather using wttr.in. It should just display the current conditions, not the full forecast





to do
+ add timestamp for last weather update
- if the cities file is not there it just hangs. error correct for this
+ json file should be relative to the script, not hardcoded to my home
- weather update time should be displayed
+ just display the city name, not the country
+ refresh weather every 3 hours, not every minute
+ change to format=3 to see the weather icon
- update README to include all scripts in folder
+ make simlink to /usr/local/bin (i think)

