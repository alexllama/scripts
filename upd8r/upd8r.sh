#!/bin/bash

# upd8r: Manjaro System Update Script

# --- IMPORTANT NOTES AND DISCLAIMERS ---
# 1.  BACKUP FIRST: Always create a system backup (e.g., with Timeshift) before
#     performing major system updates. This script can help create one if Timeshift is installed.
# 2.  CHECK FORUM ANNOUNCEMENTS: For major Manjaro Stable updates, it is HIGHLY
#     recommended to visit the official Manjaro forum (forum.manjaro.org) and
#     check the "Stable Updates" section. There might be crucial information
#     about manual interventions and known issues.
# 3.  TTY FOR MAJOR UPDATES: For large system updates (especially those involving
#     kernels, graphics drivers, or desktop environment components), it is
#     safer to log out of your graphical session and run this script from a
#     TTY (text-only terminal, usually accessed via Ctrl+Alt+F2 to F6).
#     This script will run in your current terminal, but consider switching to TTY
#     for maximum safety.
# 4.  .PACNEW FILES: This script does NOT automatically handle .pacnew files.
#     After a pacman update, you should manually check for and merge/manage
#     these files using 'sudo pacdiff'.
# 5.  INTERNET CONNECTION: Ensure you have a stable internet connection.
# 6.  DO NOT INTERRUPT: Once the update process begins, do not interrupt it.

echo "----------------------------------------------------"
echo "  Manjaro System Update Script"
echo "----------------------------------------------------"
echo ""
echo "This script will guide you through updating:"
echo "  1. Official Manjaro packages (via pacman)"
echo "  2. AUR packages (via yay, if installed)"
echo "  3. Flatpak applications (if installed)"
echo "  4. Snap applications (if installed)"
echo ""

# Create restore point with Timeshift
if command -v timeshift &> /dev/null; then
    read -p "Timeshift is installed. Do you want to create a Timeshift snapshot now? (y/N): " create_timeshift
    if [[ "$create_timeshift" =~ ^[Yy]$ ]]; then
        echo "Attempting to create a Timeshift snapshot..."
        sudo timeshift --create --comments "Pre-update snapshot by script"
        if [ $? -eq 0 ]; then
            echo "Timeshift snapshot created successfully."
        else
            echo "Error creating Timeshift snapshot. Please check Timeshift logs."
            read -p "Do you want to continue with the update WITHOUT a successful backup? (y/N): " continue_without_backup
            if [[ ! "$continue_without_backup" =~ ^[Yy]$ ]]; then
                echo "Exiting as no successful backup was created and you chose not to proceed."
                exit 1
            fi
        fi
    else
        echo "No Timeshift snapshot created. Proceeding without a backup."
    fi
else
    echo "Timeshift is not installed. Cannot create a backup automatically."
    echo "It is strongly recommended to create a backup manually before proceeding. Exiting."
    exit 1
fi

echo ""
echo "Starting system update steps..."
echo "You will be prompted for your password and for confirmation by each package manager."
echo ""

# --- 1. Update Official Manjaro Packages (pacman) ---
echo "--- Updating official Manjaro packages (pacman) ---"
# pacman -Syu synchronizes package databases and upgrades all out-of-date packages.
# User will be prompted for confirmation by pacman itself.
sudo pacman -Syu
if [ $? -eq 0 ]; then
    echo "pacman done. Official Manjaro packages are up to date."
else
    echo "Error updating official Manjaro packages via pacman. Please check the output above."
    echo "Consider running 'sudo pacman -Syyu' manually if you suspect mirror issues, or check forum announcements."
    read -p "Do you want to continue with other updates despite the pacman error? (y/N): " continue_on_pacman_error
    if [[ ! "$continue_on_pacman_error" =~ ^[Yy]$ ]]; then
        echo "Exiting due to pacman update error."
        exit 1
    fi
fi
echo ""

# --- 2. Handle .pacnew files (Manual Step Reminder) ---
echo "--- Important: Manual .pacnew file handling ---"
echo "After a system update, new configuration files (.pacnew) might be created."
echo "You should manually check for and merge/manage these files using 'sudo pacdiff'."
echo "Example: 'sudo DIFFPROG=meld pacdiff' (if meld is installed)"
echo "Press Enter to continue..."
read -r

echo ""

# --- 3. Update AUR Packages (yay) ---
echo "--- Updating AUR packages (yay) ---"
if command -v yay &> /dev/null; then
    # yay -Sua updates AUR packages. User will be prompted for confirmation by yay.
    yay -Sua
    if [ $? -eq 0 ]; then
        echo "AUR packages updated successfully."
    else
        echo "Error updating AUR packages. Please check the output above."
    fi
else
    echo "yay is not installed. Skipping AUR package update."
    echo "To install yay: 'sudo pacman -S yay' (then you can use it to install other AUR packages)."
fi
echo ""

# --- 4. Update Flatpak Applications ---
echo "--- Updating Flatpak applications ---"
if command -v flatpak &> /dev/null; then
    # flatpak update updates Flatpak applications. User will be prompted for confirmation by flatpak.
    flatpak update
    if [ $? -eq 0 ]; then
        echo "Flatpak applications updated successfully."
    else
        echo "Error updating Flatpak applications. Please check the output above."
    fi
else
    echo "Flatpak is not installed. Skipping Flatpak application update."
fi
echo ""

# --- 5. Update Snap Applications ---
echo "--- Updating Snap applications ---"
if command -v snap &> /dev/null; then
    # snap refresh updates Snap applications. User will be prompted for confirmation by snap.
    sudo snap refresh
    if [ $? -eq 0 ]; then
        echo "Snap applications updated successfully."
    else
        echo "Error updating Snap applications. Please check the output above."
    fi
else
    echo "Snap is not installed. Skipping Snap application update."
fi
echo ""

echo "----------------------------------------------------"
echo "  Update process complete!"
echo "----------------------------------------------------"
echo ""

read -p "A reboot is often recommended after system updates. Do you want to reboot now? (y/N): " confirm_reboot
if [[ "$confirm_reboot" =~ ^[Yy]$ ]]; then
    echo "Rebooting system..."
    sudo reboot
else
    echo "Reboot skipped. Please remember to reboot your system soon for changes to take full effect."
fi

echo "Script finished."
