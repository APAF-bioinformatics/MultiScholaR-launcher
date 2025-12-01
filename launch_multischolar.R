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
DEFAULT_BRANCH <- "v0.35.1"

options(warn = 1)

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
message("Available options:")
message("  1. v0.35.1 (stable release) [DEFAULT]")
message("  2. main (latest development)")
message("  3. GUI (GUI development branch)")
message("  4. Enter custom branch/tag")
message("")

if (interactive()) {
  cat("Select option (1-4) or press Enter for default: ")
  choice <- readline()
  choice <- trimws(choice)
  
  if (choice == "" || choice == "1") {
    selected_branch <- "v0.35.1"
  } else if (choice == "2") {
    selected_branch <- "main"
  } else if (choice == "3") {
    selected_branch <- "GUI"
  } else if (choice == "4") {
    cat("Enter branch/tag name: ")
    selected_branch <- trimws(readline())
    if (selected_branch == "") selected_branch <- DEFAULT_BRANCH
  } else {
    selected_branch <- choice
  }
} else {
  args <- commandArgs(trailingOnly = TRUE)
  selected_branch <- if (length(args) >= 1 && args[1] != "") args[1] else DEFAULT_BRANCH
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
  
  for (pkg in heavy_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message("  Compiling ", pkg, " (this may take 5-10 minutes)...")
      tryCatch({
        install.packages(pkg, repos = "https://cloud.r-project.org/", 
                         quiet = FALSE, Ncpus = n_cores)
        message("  ", pkg, " installed successfully!")
      }, error = function(e) {
        message("  WARNING: ", pkg, " failed to install: ", conditionMessage(e))
        message("  Continuing anyway - ", pkg, " is optional.")
      })
    } else {
      message("  ", pkg, " already installed, skipping.")
    }
  }
  
  message("")
}

# ========================================
# Step 3: Install/update MultiScholaR
# ========================================
message("--- Step 3: Installing MultiScholaR ---")
message("Repository: ", MULTISCHOLAR_REF)
message("")

tryCatch({
  pak::pak(MULTISCHOLAR_REF, ask = FALSE, upgrade = TRUE)
  message("MultiScholaR installed.")
}, error = function(e) {
  message("ERROR: ", conditionMessage(e))
  message("")
  message("Troubleshooting:")
  message("  1. git installed and in PATH?")
  message("  2. Rtools installed? (Windows)")
  message("  3. Internet connection?")
  stop("Installation failed.")
})
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
  tryCatch({
    loadDependencies(verbose = TRUE)
    message("loadDependencies completed.")
  }, error = function(e) {
    message("WARNING: ", conditionMessage(e))
    message("Continuing anyway...")
  })
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
