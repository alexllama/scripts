#!/usr/bin/env zsh

# --- Configuration ---
# Set the network interface name (as specified in your request)
INTERFACE="wlp2s0"
# --- End Configuration ---

# 1. Check for the correct number of arguments (SSID and Password are required)
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "🚨 Usage: $0 <SSID> <Password> [Username]"
    echo ""
    echo "Note: The nmcli command in this script only requires SSID and Password."
    echo "The [Username] is included for scripts that might need it later (e.g., Enterprise WPA)."
    exit 1
fi

# 2. Assign the arguments to descriptive variables
SSID="$1"
PASSWORD="$2"
USERNAME="$3" # Optional, not used in the 'nmcli device wifi connect' command below

# 3. Display the action to the user
echo "Attempting to connect to Wi-Fi network:"
echo "  SSID: **$SSID**"
echo "  Interface: **$INTERFACE**"
if [ ! -z "$USERNAME" ]; then
    echo "  Username (ignored by this specific command): **$USERNAME**"
fi
echo "---"

# 4. Execute the nmcli command with 'sudo'
# The '-i' option is often recommended for nmcli to handle special characters correctly.
echo "Executing: sudo nmcli device wifi connect \"$SSID\" password \"$PASSWORD\" ifname $INTERFACE"
sudo nmcli device wifi connect "$SSID" password "$PASSWORD" ifname "$INTERFACE"

# 5. Check the exit status of the nmcli command
if [ $? -eq 0 ]; then
    echo "---"
    echo "✅ **SUCCESS:** Successfully initiated connection to '$SSID'."
    echo "You may need to wait a few seconds for the connection to fully establish."
else
    echo "---"
    echo "❌ **FAILURE:** The nmcli command failed. Please check the following:"
    echo "  1. If you entered the **SSID** and **Password** correctly."
    echo "  2. If the **interface ($INTERFACE)** name is correct for your system."
    echo "  3. If **NetworkManager** service is running."
    echo "  4. If your user is allowed to run **sudo** without a password (or be ready to enter it)."
    exit 1
fi
