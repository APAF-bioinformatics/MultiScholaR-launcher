# ========================================
# MultiScholaR Launcher
# ========================================
# Prerequisites: R, Rtools (Windows), git, pandoc
#
# This script:
# 1. Prompts for branch/version selection
# 2. Installs pak (if needed)
# 3. On Linux: Pre-compiles heavy packages with parallel make
# 4. Installs/updates MultiScholaR from GitHub via pak
# 5. Loads the package
# 6. Runs loadDependencies() for Bioconductor/optional packages
# 7. Launches the Shiny app

# Configuration
MULTISCHOLAR_REPO <- "APAF-bioinformatics/MultiScholaR"

options(warn = 1)

# Set browser for Linux (xdg-open handles default browser)
if (.Platform$OS.type == "unix" && Sys.info()["sysname"] != "Darwin") {
  options(browser = "xdg-open")
}

message("========================================")
message("MultiScholaR Launcher")
message("========================================")
message("")
message("R version: ", R.version.string)
message("Platform:  ", R.version$platform)
message("")

# ========================================
# Step 1: Branch/Version Selection
# ========================================
message("--- Branch/Version Selection ---")
message("")

## Determine the branch to use
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  selected_branch <- args[1]
  message("Using branch from arguments: ", selected_branch)
} else {
  # This part should ideally not be reached if the shell scripts are working correctly
  # but we provide a default just in case
  selected_branch <- "main"
  message("No branch provided via arguments. Using default: ", selected_branch)
}

MULTISCHOLAR_REF <- paste0(MULTISCHOLAR_REPO, "@", selected_branch)
message("Selected: ", selected_branch)
message("")

# ========================================
# Step 2: Install pak if needed
# ========================================
message("--- Step 2: Checking pak ---")

if (!requireNamespace("pak", quietly = TRUE)) {
  message("Installing pak...")
  install.packages("pak", repos = "https://cran.rstudio.com/")
}
message("pak OK")
message("")

# ========================================
# Step 2b: Linux - Pre-compile heavy packages with parallel make
# ========================================
is_linux <- Sys.info()["sysname"] == "Linux"

if (is_linux) {
  message("--- Step 2b: Linux detected - Pre-compiling heavy packages ---")
  message("Using parallel compilation for faster builds...")
  message("")

  # Get number of cores (leave 2 free for system)
  n_cores <- max(1, parallel::detectCores() - 2)
  message("Using ", n_cores, " CPU cores for compilation")

  # Set parallel make flags
  Sys.setenv(MAKEFLAGS = paste0("-j", n_cores))

  # Heavy packages that take forever to compile on Linux
  heavy_packages <- c("duckdb", "arrow")

  lapply(heavy_packages, function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message("  Compiling ", pkg, " (this may take 5-10 minutes)...")
      tryCatch(
        {
          install.packages(pkg,
            repos = "https://cloud.r-project.org/",
            quiet = FALSE, Ncpus = n_cores
          )
          message("  ", pkg, " installed successfully!")
        },
        error = function(e) {
          message("  WARNING: ", pkg, " failed to install: ", conditionMessage(e))
          message("  Continuing anyway - ", pkg, " is optional.")
        }
      )
    } else {
      message("  ", pkg, " already installed, skipping.")
    }
  })

  message("")
}

# ========================================
# Step 3: Install/update MultiScholaR
# ========================================
message("--- Step 3: Installing MultiScholaR ---")
message("Repository: ", MULTISCHOLAR_REF)
message("")

tryCatch(
  {
    pak::pak(MULTISCHOLAR_REF, ask = FALSE, upgrade = TRUE)
    message("MultiScholaR installed.")
  },
  error = function(e) {
    message("ERROR: ", conditionMessage(e))
    message("")
    message("Troubleshooting:")
    message("  1. git installed and in PATH?")
    message("  2. Rtools installed? (Windows)")
    message("  3. Internet connection?")
    stop("Installation failed.")
  }
)
message("")

# ========================================
# Step 4: Load the package
# ========================================
message("--- Step 4: Loading MultiScholaR ---")

library(MultiScholaR)
message("Version: ", as.character(packageVersion("MultiScholaR")))
message("")

# ========================================
# Step 5: Run loadDependencies
# ========================================
message("--- Step 5: Running loadDependencies() ---")
message("Installing Bioconductor/optional packages...")
message("")

# Keep parallel make flags for Linux
if (is_linux) {
  n_cores <- max(1, parallel::detectCores() - 2)
  Sys.setenv(MAKEFLAGS = paste0("-j", n_cores))
  options(Ncpus = n_cores)
}

if (exists("loadDependencies")) {
  tryCatch(
    {
      loadDependencies(verbose = TRUE)
      message("loadDependencies completed.")
    },
    error = function(e) {
      message("WARNING: ", conditionMessage(e))
      message("Continuing anyway...")
    }
  )
}
message("")

# ========================================
# Step 6: Launch the app
# ========================================
message("========================================")
message("Launching MultiScholaR App...")
message("========================================")
message("")

MultiScholaRapp()
