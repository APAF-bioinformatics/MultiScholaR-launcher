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
"$RSCRIPT_PATH" "$LAUNCHER_DIR/launch_multischolar.R"
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
