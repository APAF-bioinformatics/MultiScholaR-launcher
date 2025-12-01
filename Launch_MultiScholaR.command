#!/bin/bash

# ========================================
# MultiScholaR Launcher for Mac/Linux
# ========================================

# Get the directory where this script is located
LAUNCHER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$LAUNCHER_DIR"

echo "========================================"
echo "MultiScholaR Launcher"
echo "========================================"
echo ""

# Default MultiScholaR installation path (Documents folder)
DOCUMENTS_DIR="$HOME/Documents"
MULTISCHOLAR_PATH="$DOCUMENTS_DIR/MultiScholaR"

# Branch to use
MULTISCHOLAR_BRANCH="v0.35.1"

# Detect R installation
echo "Detecting R installation..."
RSCRIPT_PATH=""

# First, try to find Rscript in PATH
if command -v Rscript &> /dev/null; then
    RSCRIPT_PATH=$(which Rscript)
    echo "Found Rscript in PATH: $RSCRIPT_PATH"
# Check common Mac R installation locations
elif [ -f "/Library/Frameworks/R.framework/Resources/bin/Rscript" ]; then
    RSCRIPT_PATH="/Library/Frameworks/R.framework/Resources/bin/Rscript"
    echo "Found Rscript: $RSCRIPT_PATH"
elif [ -f "/usr/local/bin/Rscript" ]; then
    RSCRIPT_PATH="/usr/local/bin/Rscript"
    echo "Found Rscript: $RSCRIPT_PATH"
elif [ -f "/opt/homebrew/bin/Rscript" ]; then
    RSCRIPT_PATH="/opt/homebrew/bin/Rscript"
    echo "Found Rscript: $RSCRIPT_PATH"
elif [ -f "/usr/bin/Rscript" ]; then
    RSCRIPT_PATH="/usr/bin/Rscript"
    echo "Found Rscript: $RSCRIPT_PATH"
else
    # Try to find via R_HOME
    if [ -n "$R_HOME" ] && [ -f "$R_HOME/bin/Rscript" ]; then
        RSCRIPT_PATH="$R_HOME/bin/Rscript"
        echo "Found Rscript via R_HOME: $RSCRIPT_PATH"
    else
        echo "ERROR: Could not detect R installation."
        echo "Please ensure R is installed."
        read -p "Press Enter to exit..."
        exit 1
    fi
fi

# Check for MultiScholaR installation
echo ""
echo "Checking for MultiScholaR installation..."

if [ -d "$MULTISCHOLAR_PATH" ]; then
    echo "MultiScholaR found at: $MULTISCHOLAR_PATH"
else
    # MultiScholaR not found - offer to install
    echo ""
    echo "MultiScholaR not found at: $MULTISCHOLAR_PATH"
    echo ""
    echo "Would you like to install MultiScholaR now?"
    echo "This will clone the repository from GitHub."
    echo ""
    read -p "Install MultiScholaR? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        read -p "Press Enter to exit..."
        exit 1
    fi
    
    # Check for git
    echo ""
    echo "Checking for git..."
    if ! command -v git &> /dev/null; then
        echo "ERROR: git is not available."
        echo "Please install git or Xcode Command Line Tools: xcode-select --install"
        read -p "Press Enter to exit..."
        exit 1
    fi
    
    # Clone the repository
    echo ""
    echo "Installing MultiScholaR..."
    echo "Cloning repository (branch: $MULTISCHOLAR_BRANCH) to: $MULTISCHOLAR_PATH"
    if ! git clone -b "$MULTISCHOLAR_BRANCH" https://github.com/APAF-bioinformatics/MultiScholaR.git "$MULTISCHOLAR_PATH"; then
        echo "ERROR: Failed to clone repository."
        echo "Please check your internet connection and try again."
        read -p "Press Enter to exit..."
        exit 1
    fi
    echo "MultiScholaR installed successfully!"
fi

# Update repository
echo ""
echo "========================================"
echo "Updating MultiScholaR repository..."
echo "========================================"
cd "$MULTISCHOLAR_PATH"

# Fetch and checkout the correct branch
git fetch origin "$MULTISCHOLAR_BRANCH" 2>/dev/null
git checkout "$MULTISCHOLAR_BRANCH" 2>/dev/null
if git pull origin "$MULTISCHOLAR_BRANCH" 2>/dev/null; then
    echo "Repository updated successfully (branch: $MULTISCHOLAR_BRANCH)."
else
    echo ""
    echo "WARNING: Failed to update repository via git pull."
    echo "This may be due to network issues or local changes."
    echo "MultiScholaR will continue with the existing local version."
fi
echo ""

# Return to launcher directory
cd "$LAUNCHER_DIR"

# Check for Pandoc
echo "========================================"
echo "Checking for Pandoc..."
echo "========================================"
if command -v pandoc &> /dev/null; then
    PANDOC_VERSION=$(pandoc --version | head -n 1)
    echo "Pandoc found - $PANDOC_VERSION"
else
    echo "WARNING: Pandoc NOT found in PATH"
    echo ""
    echo "Pandoc is required for generating reports in MultiScholaR."
    echo "Without Pandoc, you can still use MultiScholaR for all analysis"
    echo "steps, but report generation will fail."
    echo ""
    echo "Install via Homebrew: brew install pandoc"
    echo "Or download from: https://pandoc.org/installing.html"
    echo ""
    echo "MultiScholaR will continue to launch..."
fi
echo ""

# ========================================
# Bootstrap Dependencies with Restart Loop
# ========================================
echo "========================================"
echo "Bootstrapping Dependencies..."
echo "========================================"
echo ""

MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if [ -f "$LAUNCHER_DIR/bootstrap_dependencies.R" ]; then
        echo "Running dependency bootstrap (attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES)..."
        "$RSCRIPT_PATH" "$LAUNCHER_DIR/bootstrap_dependencies.R" "$MULTISCHOLAR_PATH"
        BOOTSTRAP_EXIT=$?
        
        if [ $BOOTSTRAP_EXIT -eq 0 ]; then
            echo ""
            echo "Dependencies satisfied!"
            echo ""
            break
        elif [ $BOOTSTRAP_EXIT -eq 42 ]; then
            echo ""
            echo "Packages were installed/upgraded. Restarting R session..."
            echo ""
            RETRY_COUNT=$((RETRY_COUNT + 1))
        else
            echo ""
            echo "WARNING: Bootstrap script encountered an error (exit code: $BOOTSTRAP_EXIT)."
            echo "Will attempt to launch anyway..."
            echo ""
            break
        fi
    else
        echo "WARNING: bootstrap_dependencies.R not found."
        echo "Skipping dependency bootstrap..."
        echo ""
        break
    fi
done

if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "WARNING: Maximum bootstrap retries reached."
    echo "Some dependencies may not be installed correctly."
    echo ""
fi

# Launch R script
echo "========================================"
echo "Launching MultiScholaR..."
echo "========================================"
echo ""

if [ -f "$LAUNCHER_DIR/launch_multischolar.R" ]; then
    "$RSCRIPT_PATH" "$LAUNCHER_DIR/launch_multischolar.R" "$MULTISCHOLAR_PATH"
    RSCRIPT_EXIT_CODE=$?
else
    echo "ERROR: launch_multischolar.R not found in launcher directory"
    echo "Expected at: $LAUNCHER_DIR/launch_multischolar.R"
    RSCRIPT_EXIT_CODE=1
fi

echo ""
echo "========================================"
if [ $RSCRIPT_EXIT_CODE -ne 0 ]; then
    echo "MultiScholaR finished with exit code: $RSCRIPT_EXIT_CODE"
    echo "There may have been an error. Check the output above."
else
    echo "MultiScholaR completed successfully"
fi
echo "========================================"

echo ""
read -p "Press Enter to exit..."
