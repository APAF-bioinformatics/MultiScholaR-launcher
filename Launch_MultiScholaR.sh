#!/bin/bash
# ========================================
# MultiScholaR Launcher - Linux
# ========================================
# Double-click or run: ./Launch_MultiScholaR.sh

set -e

echo "========================================"
echo "MultiScholaR Launcher"
echo "========================================"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check for R
if ! command -v Rscript &> /dev/null; then
    echo "[ERROR] R is not installed or not in PATH"
    echo ""
    echo "Please install R:"
    echo "  Ubuntu/Debian: sudo apt-get install r-base r-base-dev"
    echo "  Fedora: sudo dnf install R"
    echo "  Or download from: https://cran.r-project.org/"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi
echo "[OK] R found: $(Rscript --version 2>&1 | head -1)"

# Check for git
if ! command -v git &> /dev/null; then
    echo "[ERROR] git is not installed"
    echo ""
    echo "Please install git:"
    echo "  Ubuntu/Debian: sudo apt-get install git"
    echo "  Fedora: sudo dnf install git"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi
echo "[OK] git found: $(git --version)"

# Check for pandoc (optional but recommended)
if command -v pandoc &> /dev/null; then
    echo "[OK] pandoc found: $(pandoc --version | head -1)"
else
    echo "[WARN] pandoc not found (optional - needed for reports)"
    echo "       Install with: sudo apt-get install pandoc"
fi

echo ""

# Set up R library path
export R_LIBS_USER="${HOME}/R/library"
mkdir -p "$R_LIBS_USER"

# Run the R launcher script
echo "Starting MultiScholaR..."
echo ""

Rscript -e "source('launch_multischolar.R')" "$@"

echo ""
echo "MultiScholaR session ended."
read -p "Press Enter to close..."

