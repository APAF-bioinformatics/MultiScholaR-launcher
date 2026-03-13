#!/bin/bash

# ========================================
# MultiScholaR Launcher for macOS/Linux
# ========================================

echo "========================================"
echo "MultiScholaR Launcher"
echo "========================================"
echo ""

# Get the directory where this script is located
LAUNCHER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for flags
LOCAL_FLAG=""
for arg in "$@"; do
    if [ "$arg" == "--local" ]; then
        LOCAL_FLAG="--local"
    fi
done

# ========================================
# Check Prerequisites
# ========================================
echo "Checking prerequisites..."
echo ""

# Check for git
if ! command -v git &> /dev/null; then
    echo "ERROR: git is not installed."
    echo ""
    echo "Please install git:"
    echo "  macOS: xcode-select --install"
    echo "  Linux: sudo apt install git (or equivalent)"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi
echo "[OK] git found"

# Check for pandoc (warning only)
if ! command -v pandoc &> /dev/null; then
    echo "[WARNING] pandoc not found - report generation will not work"
    echo "          Install from: https://pandoc.org/installing.html"
    echo "          Or: brew install pandoc (macOS)"
else
    echo "[OK] pandoc found"
fi

# ========================================
# Find R Installation
# ========================================
echo ""
echo "Detecting R installation..."

RSCRIPT_PATH=""

# Try to find Rscript in PATH
if command -v Rscript &> /dev/null; then
    RSCRIPT_PATH=$(command -v Rscript)
# Check common macOS locations
elif [ -f "/Library/Frameworks/R.framework/Resources/bin/Rscript" ]; then
    RSCRIPT_PATH="/Library/Frameworks/R.framework/Resources/bin/Rscript"
elif [ -f "/usr/local/bin/Rscript" ]; then
    RSCRIPT_PATH="/usr/local/bin/Rscript"
elif [ -f "/opt/homebrew/bin/Rscript" ]; then
    RSCRIPT_PATH="/opt/homebrew/bin/Rscript"
elif [ -f "/usr/bin/Rscript" ]; then
    RSCRIPT_PATH="/usr/bin/Rscript"
# Try R_HOME
elif [ -n "$R_HOME" ] && [ -f "$R_HOME/bin/Rscript" ]; then
    RSCRIPT_PATH="$R_HOME/bin/Rscript"
fi

if [ -z "$RSCRIPT_PATH" ]; then
    echo ""
    echo "ERROR: R is not installed or not found."
    echo ""
    echo "Please install R from: https://cran.r-project.org/"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

echo "[OK] R found: $RSCRIPT_PATH"
echo ""

# ========================================
# Branch Selection
# ========================================
if [ -z "$LOCAL_FLAG" ]; then
    echo "========================================"
    echo "Branch/Version Selection"
    echo "========================================"
    echo ""

    REPO_URL="https://github.com/APAF-bioinformatics/MultiScholaR.git"
    DEFAULT_BRANCH="main"
    PERSISTENCE_FILE="$LAUNCHER_DIR/.last_branch"

    # Try to detect remote default branch
    REMOTE_DEFAULT=$(git ls-remote --symref "$REPO_URL" HEAD 2>/dev/null | grep "^ref: refs/heads/" | sed 's|^ref: refs/heads/||;s|\s*HEAD$||')
    if [ -n "$REMOTE_DEFAULT" ]; then
        DEFAULT_BRANCH="$REMOTE_DEFAULT"
    fi

    # Load last selected branch
    LAST_SELECTED=""
    if [ -f "$PERSISTENCE_FILE" ]; then
        LAST_SELECTED=$(head -n 1 "$PERSISTENCE_FILE")
    fi

    # Fetch available branches
    echo "Fetching available branches from GitHub..."
    BRANCHES=($(git ls-remote --heads "$REPO_URL" 2>/dev/null | sed 's|.*refs/heads/||' | sort))

    SELECTED_BRANCH=""

    if [ ${#BRANCHES[@]} -gt 0 ]; then
        echo ""
        echo "Available branches:"
        echo ""
        
        # Determine the default menu index
        TARGET_DEFAULT="$DEFAULT_BRANCH"
        if [ -n "$LAST_SELECTED" ]; then
            TARGET_DEFAULT="$LAST_SELECTED"
        fi
        
        DEFAULT_IDX=1
        for i in "${!BRANCHES[@]}"; do
            IDX=$((i+1))
            BRANCH="${BRANCHES[$i]}"
            DISPLAY="$BRANCH"
            
            INDICATORS=()
            if [ "$BRANCH" == "$DEFAULT_BRANCH" ]; then INDICATORS+=("REMOTE DEFAULT"); fi
            if [ "$BRANCH" == "$LAST_SELECTED" ]; then INDICATORS+=("LAST USED"); fi
            
            if [ ${#INDICATORS[@]} -gt 0 ]; then
                DISPLAY="$DISPLAY [$(IFS=,; echo "${INDICATORS[*]}")]"
            fi
            
            if [ "$BRANCH" == "$TARGET_DEFAULT" ]; then
                DEFAULT_IDX=$IDX
            fi
            
            echo "  $IDX. $DISPLAY"
        done
        
        CUSTOM_IDX=$((${#BRANCHES[@]} + 1))
        echo "  $CUSTOM_IDX. Enter custom branch/tag"
        echo ""
        
        read -p "Select option (1-$CUSTOM_IDX) or press Enter for [$TARGET_DEFAULT]: " USER_CHOICE
        
        if [ -z "$USER_CHOICE" ]; then
            SELECTED_BRANCH="$TARGET_DEFAULT"
        elif [[ "$USER_CHOICE" =~ ^[0-9]+$ ]] && [ "$USER_CHOICE" -ge 1 ] && [ "$USER_CHOICE" -le "${#BRANCHES[@]}" ]; then
            SELECTED_BRANCH="${BRANCHES[$((USER_CHOICE-1))]}"
        elif [ "$USER_CHOICE" == "$CUSTOM_IDX" ]; then
            read -p "Enter branch/tag name: " SELECTED_BRANCH
            if [ -z "$SELECTED_BRANCH" ]; then SELECTED_BRANCH="$TARGET_DEFAULT"; fi
        else
            SELECTED_BRANCH="$USER_CHOICE"
        fi
    else
        # Fallback if git fails
        echo ""
        echo "Available options:"
        echo "  1. $DEFAULT_BRANCH [DEFAULT]"
        MAX=1
        if [ -n "$LAST_SELECTED" ] && [ "$LAST_SELECTED" != "$DEFAULT_BRANCH" ]; then
            echo "  2. $LAST_SELECTED [LAST USED]"
            echo "  3. Enter custom branch/tag"
            MAX=3
        else
            echo "  2. Enter custom branch/tag"
            MAX=2
        fi
        echo ""
        
        read -p "Select option (1-$MAX) or press Enter for default: " USER_CHOICE
        
        if [ -z "$USER_CHOICE" ] || [ "$USER_CHOICE" == "1" ]; then
            SELECTED_BRANCH="$DEFAULT_BRANCH"
        elif [ "$USER_CHOICE" == "2" ] && [ "$MAX" == "3" ]; then
            SELECTED_BRANCH="$LAST_SELECTED"
        elif { [ "$USER_CHOICE" == "3" ] && [ "$MAX" == "3" ]; } || { [ "$USER_CHOICE" == "2" ] && [ "$MAX" == "2" ]; }; then
            read -p "Enter branch/tag name: " SELECTED_BRANCH
            if [ -z "$SELECTED_BRANCH" ]; then SELECTED_BRANCH="$DEFAULT_BRANCH"; fi
        else
            SELECTED_BRANCH="$USER_CHOICE"
        fi
    fi

    # Save selection
    echo "$SELECTED_BRANCH" > "$PERSISTENCE_FILE"
else
    # Local mode - skip branch selection
    SELECTED_BRANCH="local_mode"
fi

echo ""
echo "Selected: $SELECTED_BRANCH"
echo ""

# ========================================
# Launch MultiScholaR
# ========================================
echo "========================================"
echo "Starting MultiScholaR..."
echo "========================================"
echo ""
echo "This may take several minutes on first run while"
echo "packages are downloaded and installed."
echo ""
echo "Do not close this window."
echo ""

# Run the R launch script
"$RSCRIPT_PATH" "$LAUNCHER_DIR/launch_multischolar.R" "$SELECTED_BRANCH" "$LOCAL_FLAG"
RSCRIPT_EXIT=$?

echo ""
echo "========================================"
if [ $RSCRIPT_EXIT -ne 0 ]; then
    echo "MultiScholaR exited with code: $RSCRIPT_EXIT"
    echo "There may have been an error. Check output above."
else
    echo "MultiScholaR session ended."
fi
echo "========================================"
echo ""
read -p "Press Enter to close..."
