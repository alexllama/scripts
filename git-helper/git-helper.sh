#!/bin/bash

## git-helper.sh
## Author: Alex Llama
## Runs various git commands to streamline checking in files in the current project
## Generated with Gemini CLI

# Function to print a message in a box
print_boxed() {
    local message="$1"
    local border_char="="
    # Create a border of the same length as the message
    local top_bottom_border=$(printf '%*s' "${#message}" '' | tr ' ' "$border_char")

    echo "$top_bottom_border"
    echo "$message"
    echo "$top_bottom_border"
}

# STAGING
echo "Checking git status..."

# Get the list of changed files using git status --porcelain.
# The output is parsed to differentiate between 'modified' and 'untracked' files.
untracked_files=()
modified_files=()
while IFS= read -r line; do
    # Extract the two-character status code and the file path.
    status=${line:0:2}
    filepath=${line:3}

    # Untracked files are marked with '??'.
    if [[ $status == '??' ]]; then
        untracked_files+=("$filepath")
    # A non-space character in the second position of the status (the work tree)
    # indicates a file that is modified but not staged.
    elif [[ ${status:1:1} != ' ' && ${status:1:1} != '?' ]]; then
        modified_files+=("$filepath")
    fi
done < <(git status --porcelain)

# Combine the arrays for selection purposes
files=("${modified_files[@]}" "${untracked_files[@]}")

# Check if there are any files to commit
if [ ${#files[@]} -eq 0 ]; then
    echo "No changes to commit."
    exit 0
fi

# Display the files with numbers in a box
echo "========================================="
echo "        Changes not staged for commit     "
echo "========================================="
file_num=1
for file in "${modified_files[@]}"; do
    printf "%-4s %s\n" "[$file_num]" "$file"
    ((file_num++))
done
echo "========================================="
echo "              Untracked files             "
echo "========================================="
for file in "${untracked_files[@]}"; do
    printf "%-4s %s\n" "[$file_num]" "$file"
    ((file_num++))
done
echo "========================================="


# Prompt for file selection
echo "Select files to stage:"
echo "  (e.g., '1 3 4' for specific files, or 'A' for all)"
read -p "Enter your selection: " selection

selected_files=()
# Process user selection
if [[ "$selection" == "A" || "$selection" == "a" ]]; then
    selected_files=("${files[@]}")
else
    # Loop through space-delimited numbers
    for num in $selection; do
        # Basic validation to ensure it's a number within the correct range
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#files[@]}" ]; then
            selected_files+=("${files[$((num-1))]}")
        else
            echo "Invalid selection: $num. It will be ignored."
        fi
    done
fi

# Check if any files were actually selected
if [ ${#selected_files[@]} -eq 0 ]; then
    echo "No files selected. Exiting."
    exit 0
fi

# Confirm selection with the user
echo "You have selected the following files to stage:"
for file in "${selected_files[@]}"; do
    echo "  - $file"
done

read -p "Proceed? (Y/N): " confirm
if [[ "$confirm" != "Y" && "$confirm" != "y" ]]; then
    echo "Aborting."
    exit 0
fi

# Stage the selected files
git add "${selected_files[@]}"
echo "Selected files have been staged."

# COMMIT
read -p "Enter commit message: " commit_message

echo "Committing with message: '$commit_message'"
# Capture both stdout and stderr
commit_output=$(git commit -m "$commit_message" 2>&1)
print_boxed "$commit_output"

# PUSH
echo "Pushing to remote repository..."
# Capture both stdout and stderr
push_output=$(git push 2>&1)
print_boxed "$push_output"

echo "Script finished."
