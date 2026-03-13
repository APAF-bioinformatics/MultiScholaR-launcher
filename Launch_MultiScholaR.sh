#!/bin/bash
# ========================================
# MultiScholaR Launcher - Linux (Interactive)
# ========================================
# Run: ./Launch_MultiScholaR.sh

set -e

# Configuration
REPO_URL="https://github.com/APAF-bioinformatics/MultiScholaR.git"
DEFAULT_BRANCH="main"
# HARDCODED LOCAL PATH
LOCAL_PATH="$HOME/Documents/MultiScholaR"

echo "========================================"
echo "MultiScholaR Launcher"
echo "========================================"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check for flags
LOCAL_FLAG=""
for arg in "$@"; do
    if [ "$arg" == "--local" ]; then
        LOCAL_FLAG="--local"
    fi
done

# ========================================
# 1. Check Prerequisites
# ========================================
echo "Checking prerequisites..."

# Check for R
if ! command -v Rscript &> /dev/null; then
    echo "[ERROR] R is not installed or not in PATH"
    echo "Please install R: sudo pacman -S r (or equivalent)"
    read -p "Press Enter to exit..."
    exit 1
fi

# Check for git
if ! command -v git &> /dev/null; then
    echo "[ERROR] git is not installed"
    echo "Please install git: sudo pacman -S git (or equivalent)"
    read -p "Press Enter to exit..."
    exit 1
fi

# Set up R library path
export R_LIBS_USER="${HOME}/R/library"
mkdir -p "$R_LIBS_USER"
export R_BROWSER=xdg-open

# ========================================
# 2. Branch/Source Selection
# ========================================
if [ -z "$LOCAL_FLAG" ]; then
    echo "========================================"
    echo "Source Selection"
    echo "========================================"
    echo ""

    # Fetch branches cleanly into an array (ignoring errors if offline)
    RAW_BRANCHES=$(git ls-remote --heads "$REPO_URL" 2>/dev/null || true)

    BRANCHES=()
    if [ -n "$RAW_BRANCHES" ]; then
        mapfile -t BRANCHES < <(echo "$RAW_BRANCHES" | awk '{print $2}' | sed 's|refs/heads/||' | sort)
    fi

    SELECTED_BRANCH=""

    # Display Menu
    echo "Available sources:"
    echo ""
    
    if [ ${#BRANCHES[@]} -gt 0 ]; then
        i=0
        for branch in "${BRANCHES[@]}"; do
            i=$((i+1))
            if [ "$branch" == "$DEFAULT_BRANCH" ]; then
                echo "  $i. $branch [DEFAULT]"
            else
                echo "  $i. $branch"
            fi
        done
        CUSTOM_OPT=$((i+1))
        echo "  $CUSTOM_OPT. Enter custom branch/tag"
    else
        # Fallback if offline
        echo "  1. main [DEFAULT]"
        echo "  2. Enter custom branch"
        CUSTOM_OPT=2
    fi

    echo ""
    read -p "Select option (1-$CUSTOM_OPT) [Default: 1]: " CHOICE

    # Logic to handle selection
    if [ -z "$CHOICE" ]; then
        SELECTED_BRANCH="$DEFAULT_BRANCH"
    elif [ "$CHOICE" -eq "$CUSTOM_OPT" ] 2>/dev/null; then
        read -p "Enter branch/tag name: " USER_INPUT
        SELECTED_BRANCH="${USER_INPUT:-$DEFAULT_BRANCH}"
    elif [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#BRANCHES[@]}" ] 2>/dev/null; then
        IDX=$((CHOICE-1))
        SELECTED_BRANCH="${BRANCHES[$IDX]}"
    else
        # Fallback for manual entry or fallback menu
        if [ "${#BRANCHES[@]}" -eq 0 ] && [ "$CHOICE" == "1" ]; then
            SELECTED_BRANCH="main"
        else
            SELECTED_BRANCH="$CHOICE"
        fi
    fi
else
    # Local mode - skip branch selection
    SELECTED_BRANCH="local_mode"
fi

echo ""
echo "Selected target: $SELECTED_BRANCH"
echo ""

# ========================================
# 3. Launch Application
# ========================================

echo "Starting MultiScholaR..."
# Run the R launch script
Rscript launch_multischolar.R "$SELECTED_BRANCH" "$LOCAL_FLAG"

echo ""
echo "MultiScholaR session ended."
read -p "Press Enter to close..."