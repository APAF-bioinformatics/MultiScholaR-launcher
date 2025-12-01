# MultiScholaR Launcher

A simple, cross-platform launcher for the [MultiScholaR](https://github.com/APAF-bioinformatics/MultiScholaR) R package. **Double-click and go!**

## What This Does

This launcher provides a zero-configuration installation experience for MultiScholaR:

1. **Installs everything automatically** - No need to manually install R packages
2. **Handles updates** - Checks for and installs new versions on each launch
3. **Branch selection** - Choose between stable releases and development versions
4. **Cross-platform** - Works on Windows, macOS, and Linux

## Prerequisites

Install these **before** running the launcher:

| Software | Required | Download |
|----------|----------|----------|
| **R** (4.3+) | ✅ Yes | [Windows](https://cran.r-project.org/bin/windows/base/) / [macOS](https://cran.r-project.org/bin/macosx/) / [Linux](https://cran.r-project.org/) |
| **Rtools** | ✅ Windows only | [Download](https://cran.r-project.org/bin/windows/Rtools/) (match version to R) |
| **Git** | ✅ Yes | [Windows](https://git-scm.com/download/win) / macOS: `xcode-select --install` |
| **Pandoc** | 📄 For reports | [Download](https://pandoc.org/installing.html) |

> ⚠️ **Windows Users**: Rtools is **required** for compiling R packages. Match the version to your R (e.g., R 4.4.x → Rtools 4.4).

### Linux Additional Requirements

On Debian/Ubuntu, you may need system development libraries:

```bash
sudo apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev libglpk-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev
```

## Quick Start

### Windows

1. Download or clone this repository
2. **Double-click** `Launch_MultiScholaR.bat`
3. Select version when prompted (or press Enter for default)
4. Wait for installation (first run: 10-30 minutes)
5. App launches automatically! 🚀

### macOS

1. Download or clone this repository
2. Make executable (first time only):
   ```bash
   chmod +x Launch_MultiScholaR.command
   ```
3. **Double-click** `Launch_MultiScholaR.command` (or run from terminal)
4. Select version and wait for installation

### Linux

1. Download or clone this repository
2. Make executable (first time only):
   ```bash
   chmod +x Launch_MultiScholaR.sh
   ```
3. **Double-click** `Launch_MultiScholaR.sh` or run from terminal:
   ```bash
   ./Launch_MultiScholaR.sh
   ```
4. Select version and wait for installation

> **Note:** On Linux, first run may take 15-30 minutes due to package compilation. The launcher uses parallel compilation (`-j` flag) to speed this up.

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  1. Branch Selection                                        │
│     → Choose: stable (v0.35.1), main, GUI, or custom       │
├─────────────────────────────────────────────────────────────┤
│  2. Install pak (if needed)                                 │
│     → Modern R package manager, handles dependencies       │
├─────────────────────────────────────────────────────────────┤
│  3. pak installs MultiScholaR                               │
│     → Pulls from GitHub with all CRAN dependencies         │
│     → Compiles packages from source as needed              │
├─────────────────────────────────────────────────────────────┤
│  4. Load MultiScholaR                                       │
│     → Package is loaded into R session                     │
├─────────────────────────────────────────────────────────────┤
│  5. Run loadDependencies()                                  │
│     → Installs Bioconductor & optional packages            │
│     → limma, mixOmics, clusterProfiler, etc.              │
├─────────────────────────────────────────────────────────────┤
│  6. Launch MultiScholaRapp()                                │
│     → Opens the Shiny web interface                        │
└─────────────────────────────────────────────────────────────┘
```

### Branch Selection Menu

```
Available options:
  1. v0.35.1 (stable release) [DEFAULT]
  2. main (latest development)
  3. GUI (GUI development branch)
  4. Enter custom branch/tag

Select option (1-4) or press Enter for default:
```

- **Press Enter** or **1** → Stable release (recommended for most users)
- **Press 2** → Latest development (may have bugs)
- **Press 3** → GUI-specific development branch
- **Press 4** → Enter any branch, tag, or commit hash

### First Run vs Subsequent Runs

| | First Run | Subsequent Runs |
|---|-----------|-----------------|
| **pak** | Installs (~1 min) | Skipped |
| **MultiScholaR** | Full install (5-20 min) | Updates only if changed (~30 sec) |
| **Dependencies** | Full install via loadDependencies() | Installs missing only |
| **Total time** | 10-30 minutes | 1-2 minutes |

## Files in This Repository

| File | Purpose |
|------|---------|
| `Launch_MultiScholaR.bat` | Windows launcher (double-click) |
| `Launch_MultiScholaR.command` | macOS launcher (double-click) |
| `Launch_MultiScholaR.sh` | Linux launcher (double-click or `./Launch_MultiScholaR.sh`) |
| `launch_multischolar.R` | Core R script - handles installation & launch |
| `MultiScholaR.ico` | Icon for Windows shortcuts |
| `README.md` | This file |

## Troubleshooting

### "R is not installed"

Ensure R is in your PATH:
- **Windows**: Usually auto-configured by R installer
- **macOS/Linux**: Add to `~/.bashrc` or `~/.zshrc`:
  ```bash
  export PATH="/usr/local/bin/R:$PATH"
  ```

### "Rtools is not installed" (Windows)

1. Download [Rtools](https://cran.r-project.org/bin/windows/Rtools/) matching your R version
2. Run installer with default settings
3. Restart the launcher

### "git is not installed"

- **Windows**: Install from [git-scm.com](https://git-scm.com/download/win)
- **macOS**: Run `xcode-select --install`
- **Linux**: `sudo apt-get install git`

### Package Build Failures

If you see errors like `there is no package called 'X'` or compilation failures:

1. **Check for missing system libraries** (Linux):
   ```bash
   sudo apt-get install libcurl4-openssl-dev libssl-dev libxml2-dev
   ```

2. **Clear pak cache and retry**:
   ```r
   pak::cache_clean()
   pak::pak("APAF-bioinformatics/MultiScholaR@v0.35.1")
   ```

3. **BH package issues** (fgsea compilation):
   If fgsea fails with Boost errors, install BH 1.84.0:
   ```r
   install.packages("https://cran.r-project.org/src/contrib/Archive/BH/BH_1.84.0-0.tar.gz", repos=NULL, type="source")
   ```

### "Permission denied" (macOS/Linux)

```bash
chmod +x Launch_MultiScholaR.command
```

### loadDependencies() Takes Forever

This is normal on first run! It installs many Bioconductor packages:
- limma, mixOmics, clusterProfiler, fgsea, UniProt.ws, etc.
- Can take 10-20 minutes depending on internet speed and system

## Creating Desktop Shortcuts

### Windows

1. Right-click `Launch_MultiScholaR.bat` → **Send to** → **Desktop (create shortcut)**
2. Optional: Right-click shortcut → **Properties** → **Change Icon** → Browse to `MultiScholaR.ico`

### macOS

1. Right-click `Launch_MultiScholaR.command` → **Make Alias**
2. Drag alias to Desktop or Dock

## For Developers

### Testing Different Branches

```bash
# Pass branch as command-line argument
Rscript launch_multischolar.R my-feature-branch

# Or use non-interactive mode
R_LIBS_USER=~/R/library Rscript -e "source('launch_multischolar.R')" my-branch
```

### Changing Default Branch

Edit `launch_multischolar.R`:
```r
DEFAULT_BRANCH <- "v0.35.1"  # Change to your preferred default
```

### Manual Installation (without launcher)

```r
# Install pak if needed
install.packages("pak")

# Install MultiScholaR
pak::pak("APAF-bioinformatics/MultiScholaR@v0.35.1")

# Load and run
library(MultiScholaR)
loadDependencies()
MultiScholaRapp()
```

## Architecture Notes

The launcher uses a **two-phase dependency strategy**:

1. **Phase 1 (pak)**: Installs MultiScholaR + CRAN dependencies listed in `DESCRIPTION Imports:`
   - All standard CRAN packages
   - GitHub remotes (RUVIIIC, GlimmaV2)

2. **Phase 2 (loadDependencies)**: Installs optional Bioconductor packages
   - limma, mixOmics, clusterProfiler, fgsea, UniProt.ws, etc.
   - These are used via `::` notation and checked with `requireNamespace()`

This approach allows the package to build without Bioconductor pre-installed, while still providing full functionality after `loadDependencies()` runs.

## License

LGPL-3.0 (same as MultiScholaR)

## Support

- **Launcher issues**: [Open an issue](https://github.com/APAF-bioinformatics/MultiScholaR-launcher/issues)
- **MultiScholaR issues**: [Main repository](https://github.com/APAF-bioinformatics/MultiScholaR/issues)

---

Created for [MultiScholaR](https://github.com/APAF-bioinformatics/MultiScholaR) by APAF-bioinformatics.
