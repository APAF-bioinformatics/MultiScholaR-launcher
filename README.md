# MultiScholaR Launcher

A simple, cross-platform launcher for the MultiScholaR R package. Just double-click and go!

## Prerequisites

**⚠️ IMPORTANT: The following software must be installed before using the launcher:**

- **R** (version 4.4.3 or later recommended)
  - Download: [Windows](https://cran.r-project.org/bin/windows/base/) | [macOS](https://cran.r-project.org/bin/macosx/)
  
- **Git** (required for cloning/updating MultiScholaR)
  - Download: [Windows](https://git-scm.com/download/win) | [macOS](https://git-scm.com/download/mac)
  - macOS alternative: Install Xcode Command Line Tools via `xcode-select --install`
  
- **Pandoc** (required for report generation)
  - Download: [Windows/macOS/Linux](https://pandoc.org/installing.html)
  - macOS alternative: `brew install pandoc` (if using Homebrew)

## Features

- **Zero Configuration**: Automatically detects R installation and sets up MultiScholaR
- **Auto-Update**: Automatically pulls latest changes from the GUI branch on launch
- **Cross-Platform**: Works on Windows and macOS
- **Self-Contained**: No manual installation steps required

## Quick Start

### Windows

1. Download this repository (or clone it)
2. Double-click `Launch_MultiScholaR.bat`
3. On first run, it will:
   - Detect your R installation
   - Ask if you want to install MultiScholaR (clones to `Documents/MultiScholaR`)
   - Launch the application

### macOS

1. Download this repository (or clone it)
2. Make the launcher executable (first time only):
   ```bash
   chmod +x Launch_MultiScholaR.command
   ```
3. Double-click `Launch_MultiScholaR.command`
4. On first run, it will:
   - Detect your R installation
   - Ask if you want to install MultiScholaR (clones to `~/Documents/MultiScholaR`)
   - Launch the application

## Requirements

See [Prerequisites](#prerequisites) above for download links and installation instructions.

- **R** (version 4.4.3 or later recommended)
- **Git** (for cloning/updating MultiScholaR)
- **Internet connection** (for initial installation and updates)
- **Pandoc** (for report generation - required)

## How It Works

1. **First Launch**: 
   - Detects R installation automatically
   - Prompts to clone MultiScholaR from GitHub (GUI branch) to your Documents folder
   - Sets up everything automatically

2. **Subsequent Launches**:
   - Automatically pulls latest changes from the GUI branch
   - Launches MultiScholaR immediately

## Installation Location

MultiScholaR is installed to:
- **Windows**: `%USERPROFILE%\Documents\MultiScholaR`
- **macOS**: `~/Documents/MultiScholaR`

You can move this folder if needed, but you'll need to update the launcher or reinstall.

## Troubleshooting

### R Not Detected

If R is not automatically detected:
- Ensure R is installed and in your system PATH, OR
- Install R to a standard location:
  - Windows: `C:\Program Files\R\` or `%LOCALAPPDATA%\Programs\R\`
  - macOS: `/Library/Frameworks/R.framework/` or via Homebrew

### Git Not Found

- **Windows**: Download from [git-scm.com](https://git-scm.com/download/win)
- **macOS**: Install Xcode Command Line Tools: `xcode-select --install`

### Permission Denied (macOS)

If you get a permission error on macOS:
```bash
chmod +x Launch_MultiScholaR.command
```

Or right-click the file → Get Info → Check "Open with Terminal"

### Network Issues

If git pull fails (network issues, firewall, etc.):
- The launcher will show a warning but continue with your existing local version
- You can manually update by running `git pull origin GUI` in the MultiScholaR directory

## Files in This Repository

- `Launch_MultiScholaR.bat` - Windows launcher (double-click to run)
- `Launch_MultiScholaR.command` - macOS launcher (double-click to run)
- `launch_multischolar.R` - R script that loads and launches MultiScholaR
- `MultiScholaR.ico` - Icon file (optional, for shortcuts)
- `README.md` - This file

## Creating Desktop Shortcuts

### Windows

1. Right-click `Launch_MultiScholaR.bat`
2. Select "Create shortcut"
3. Move shortcut to Desktop
4. (Optional) Right-click shortcut → Properties → Change Icon → Browse to `MultiScholaR.ico`

### macOS

1. Right-click `Launch_MultiScholaR.command`
2. Select "Make Alias"
3. Drag alias to Desktop

## License

[Specify your license here - e.g., same as MultiScholaR (LGPL-3.0) or your preferred license]

## Contributing

[If you want to accept contributions, add guidelines here]

## Support

For issues with:
- **This launcher**: Open an issue in this repository
- **MultiScholaR package**: See the [main MultiScholaR repository](https://github.com/APAF-bioinformatics/MultiScholaR)

## Credits

Launcher created for the MultiScholaR package by APAF-bioinformatics.

