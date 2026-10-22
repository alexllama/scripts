#!/bin/bash
#
## git-helper.sh
## Author: Alex Llama
## Runs various git commands to streamline checking in files in the current project
## Generated with Gemini CLI
#

set -uo pipefail

# Colors
if [ -t 1 ] && [ "${NO_COLOR:-0}" != "1" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' BOLD='' DIM='' NC=''
fi

print_header() {
    local title="$1"
    local width=60
    local padding=$(( (width - ${#title} - 2) / 2 ))
    local padleft="" padright=""
    printf -v padleft '%*s' "$padding" ''
    printf -v padright '%*s' "$((width - ${#title} - 2 - padding))" ''
    echo -e "${CYAN}╭$(printf '─%.0s' $(seq 1 $width))╮${NC}"
    echo -e "${CYAN}│${NC}${BOLD}${padleft} ${title} ${padright}${NC}${CYAN}│${NC}"
    echo -e "${CYAN}╰$(printf '─%.0s' $(seq 1 $width))╯${NC}"
}

print_section() {
    local title="$1"
    local color="$2"
    echo -e "\n${color}${BOLD}▸ ${title}${NC}"
    echo -e "${DIM}$(printf '─%.0s' $(seq 1 50))${NC}"
}

print_box() {
    local message="$1"
    local color="${2:-$BLUE}"
    echo -e "\n${color}╭$(printf '─%.0s' $(seq 1 58))╮${NC}"
    while IFS= read -r line || [ -n "$line" ]; do
        # Pad/truncate to fit
        local len=${#line}
        if [ "$len" -gt 56 ]; then
            line="${line:0:53}..."
            len=56
        fi
        local pad=$((56 - len))
        printf -v spaces '%*s' "$pad" ''
        echo -e "${color}│${NC} ${line}${spaces} ${color}│${NC}"
    done <<< "$message"
    echo -e "${color}╰$(printf '─%.0s' $(seq 1 58))╯${NC}\n"
}

usage() {
    print_header "git-helper"
    echo -e "${BOLD}Usage:${NC} $(basename "$0") [OPTIONS]\n"
    echo -e "${BOLD}Interactive helper to stage, commit, and push selected changes.${NC}\n"
    echo -e "${BOLD}Options:${NC}"
    echo -e "  ${CYAN}--no-push${NC}      Skip pushing after commit"
    echo -e "  ${CYAN}-h, --help${NC}     Show this help message\n"
    echo -e "${BOLD}Notes:${NC}"
    echo -e "  ${DIM}•${NC} Already staged files are displayed for visibility but not auto-staged"
    echo -e "  ${DIM}•${NC} Commits use ${CYAN}git commit --only${NC} so only selected files go into the commit"
    echo -e "  ${DIM}•${NC} Filenames with spaces, quotes, or unusual characters are handled safely\n"
}

NO_PUSH=0
while [ $# -gt 0 ]; do
    case "$1" in
        --no-push)
            NO_PUSH=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo -e "${RED}✗ Unknown option: $1${NC}" >&2
            usage >&2
            exit 1
            ;;
        *)
            echo -e "${RED}✗ Unexpected argument: $1${NC}" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# Ensure we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "${RED}✗ Error: not inside a git repository.${NC}" >&2
    exit 1
fi

# Always operate from the repository root to handle paths correctly
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || {
    echo -e "${RED}✗ Error: failed to cd to repository root.${NC}" >&2
    exit 1
}

print_header "Git Helper"
echo -e "${DIM}Repository: ${REPO_ROOT}${NC}"
echo -e "${DIM}Scanning for changes...${NC}\n"

# Arrays to hold files
staged_files=()
unstaged_modified=()
untracked_files=()
conflicted_files=()

# Parse with NUL delimiter to safely handle any filename
while IFS= read -r -d '' entry; do
    [ -z "$entry" ] && continue
    status="${entry:0:2}"
    # For renames/copies, the next NUL entry is the original path
    if [[ "$status" == R* || "$status" == C* ]]; then
        filepath="${entry:3}"
        staged_files+=("[renamed/copied] $filepath")
        # Skip the original path entry that follows
        IFS= read -r -d '' _orig >/dev/null || true
        continue
    fi
    filepath="${entry:3}"

    # Conflicts
    if [[ "$status" == "UU" || "$status" == "AA" || "$status" == "DD" ]]; then
        conflicted_files+=("$filepath")
        continue
    fi

    # Staged changes (first char is not space and not '?')
    if [[ "${status:0:1}" != ' ' && "${status:0:1}" != '?' ]]; then
        staged_files+=("$filepath")
    fi

    # Unstaged modifications (second char indicates worktree change)
    if [[ "${status:1:1}" != ' ' && "${status:1:1}" != '?' ]]; then
        unstaged_modified+=("$filepath")
    fi

    # Untracked
    if [[ "$status" == '??' ]]; then
        untracked_files+=("$filepath")
    fi
done < <(git status --porcelain -z)

# Display staged files
print_section "Staged Files" "$GREEN"
if [ ${#staged_files[@]} -eq 0 ]; then
    echo -e "  ${DIM}(none)${NC}"
else
    for file in "${staged_files[@]}"; do
        echo -e "  ${GREEN}✓${NC} $file"
    done
fi

# Combine selectable files (unstaged modified + untracked)
files=("${unstaged_modified[@]}" "${untracked_files[@]}")

# Display unstaged modified
print_section "Changes Not Staged for Commit" "$YELLOW"
file_num=1
if [ ${#unstaged_modified[@]} -eq 0 ]; then
    echo -e "  ${DIM}(none)${NC}"
else
    for file in "${unstaged_modified[@]}"; do
        echo -e "  ${YELLOW}[$file_num]${NC} $file"
        ((file_num++))
    done
fi

# Display untracked
print_section "Untracked Files" "$CYAN"
if [ ${#untracked_files[@]} -eq 0 ]; then
    echo -e "  ${DIM}(none)${NC}"
else
    for file in "${untracked_files[@]}"; do
        echo -e "  ${CYAN}[$file_num]${NC} $file"
        ((file_num++))
    done
fi

# Display conflicts if any
if [ ${#conflicted_files[@]} -gt 0 ]; then
    print_section "Conflicted Files" "$RED"
    for file in "${conflicted_files[@]}"; do
        echo -e "  ${RED}✗${NC} $file"
    done
    echo -e "\n${RED}✗ Resolve conflicts before committing.${NC}" >&2
    exit 1
fi

# Check if there are any files to commit
if [ ${#files[@]} -eq 0 ]; then
    echo -e "\n${DIM}No unstaged/untracked changes to select.${NC}"
    if [ ${#staged_files[@]} -gt 0 ]; then
        echo -e "${YELLOW}ℹ${NC} There are staged files - use ${CYAN}git commit${NC} directly if you want to commit them."
    fi
    exit 0
fi

echo
# Prompt for file selection
echo -e "${BOLD}Select files to stage and commit:${NC}"
echo -e "  ${DIM}(e.g., '1 3 4' for specific files, or 'A' for all)${NC}"
echo -ne "${CYAN}➜${NC} Enter your selection: "
read -r selection

selected_files=()
if [[ "$selection" == "A" || "$selection" == "a" ]]; then
    selected_files=("${files[@]}")
else
    # Split by whitespace safely (no globbing)
    read -ra nums <<< "$selection"
    for num in "${nums[@]}"; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#files[@]}" ]; then
            selected_files+=("${files[$((num-1))]}")
        else
            echo -e "${YELLOW}⚠ Invalid selection: $num. It will be ignored.${NC}" >&2
        fi
    done
fi

# Check if any files were actually selected
if [ ${#selected_files[@]} -eq 0 ]; then
    echo -e "\n${RED}✗ No files selected. Exiting.${NC}"
    exit 0
fi

# Confirm selection with the user
echo -e "\n${BOLD}Selected files to stage and commit:${NC}"
for file in "${selected_files[@]}"; do
    echo -e "  ${GREEN}•${NC} $file"
done
echo
echo -ne "${CYAN}➜${NC} Proceed? ${DIM}(Y/N)${NC}: "
read -r confirm
if [[ "$confirm" != "Y" && "$confirm" != "y" ]]; then
    echo -e "\n${YELLOW}Aborting.${NC}"
    exit 0
fi

# Stage the selected files
echo -e "\n${DIM}Staging selected files...${NC}"
if ! git add -- "${selected_files[@]}"; then
    echo -e "${RED}✗ Error: failed to stage selected files.${NC}" >&2
    exit 1
fi
echo -e "${GREEN}✓${NC} Selected files have been staged."

# COMMIT
echo
echo -ne "${CYAN}➜${NC} Enter commit message: "
read -r commit_message
if [ -z "${commit_message// }" ]; then
    echo -e "\n${RED}✗ Error: commit message cannot be empty.${NC}" >&2
    exit 1
fi

echo -e "\n${DIM}Committing...${NC}"
# Commit only the selected files (don't sweep already staged files)
if ! commit_output=$(git commit --only -m "$commit_message" -- "${selected_files[@]}" 2>&1); then
    echo -e "$commit_output"
    echo -e "\n${RED}✗ Error: commit failed.${NC}" >&2
    exit 1
fi
print_box "$commit_output" "$GREEN"

# PUSH
if [ "$NO_PUSH" -eq 1 ]; then
    echo -e "${YELLOW}ℹ${NC} Skipping push ${DIM}(--no-push)${NC}."
    echo -e "\n${GREEN}✓ Done!${NC}"
    exit 0
fi

echo -e "${DIM}Pushing to remote repository...${NC}"
if ! push_output=$(git push 2>&1); then
    echo -e "$push_output"
    echo -e "\n${RED}✗ Error: push failed.${NC}" >&2
    exit 1
fi
print_box "$push_output" "$BLUE"

echo -e "${GREEN}✓ Done!${NC}"
