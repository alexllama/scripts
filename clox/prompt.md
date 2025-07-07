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




A couple of fixes:
- the weather is not showing at all
- do not show the year
- remove the labels City: and Time
- display the information for each city in a box, from left to right


to do
- if the cities file is not there it just hangs. error correct for this
+ json file should be relative to the script, not hardcoded to my home
- weather update time should be in the json file
- just display the city name, not the country
- refresh weather every 3 hours, not every minute
- change to format=3 to see the weather icon
- consider getting the forecast to show the nice recap for the weather at the city
- move everything to clox folder
- check in clox folder
- update README to include all scripts in folder
- make simlink to /usr/local/bin (i think)

