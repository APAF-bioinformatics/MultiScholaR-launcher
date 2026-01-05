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

# ========================================
# 1. Check Prerequisites
# ========================================
echo "Checking prerequisites..."

# Check for R
if ! command -v Rscript &> /dev/null; then
    echo "[ERROR] R is not installed or not in PATH"
    echo "Please install R: sudo pacman -S r"
    read -p "Press Enter to exit..."
    exit 1
fi

# Check for git
if ! command -v git &> /dev/null; then
    echo "[ERROR] git is not installed"
    echo "Please install git: sudo pacman -S git"
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
echo "  L. ** LOCAL DEV ** ($LOCAL_PATH)"
echo "  --------------------------------------------------"

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
read -p "Select option (L, 1-$CUSTOM_OPT) [Default: 1]: " CHOICE

# Logic to handle selection
if [[ "$CHOICE" == "l" || "$CHOICE" == "L" ]]; then
    SELECTED_BRANCH="LOCAL"
elif [ -z "$CHOICE" ]; then
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

echo ""
echo "Selected target: $SELECTED_BRANCH"
echo ""

# ========================================
# 3. Launch Application
# ========================================

if [ "$SELECTED_BRANCH" == "LOCAL" ]; then
    # LOCAL MODE: Bypass pak/install and just load_all + run
    echo "Starting MultiScholaR from LOCAL source..."
    echo "Path: $LOCAL_PATH"
    
    if [ ! -d "$LOCAL_PATH" ]; then
        echo "[ERROR] Local path does not exist: $LOCAL_PATH"
        read -p "Press Enter to exit..."
        exit 1
    fi

    # NOTE: Adjust 'MultiScholaR::run_app()' below if your start function is named differently
    Rscript -e "options(browser = 'xdg-open', shiny.launch.browser = TRUE); devtools::load_all('$LOCAL_PATH'); MultiScholaR::run_app(launch.browser = TRUE)"

else
    # REMOTE MODE: Use the existing R launcher script
    echo "Starting MultiScholaR (Remote Install)..."
    Rscript launch_multischolar.R "$SELECTED_BRANCH"
fi

echo ""
echo "MultiScholaR session ended."
read -p "Press Enter to close..."