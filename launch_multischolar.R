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
is_local <- "--local" %in% args

# Filter out flags to find the branch
selected_branch <- args[!grepl("^-", args)][1]

if (is.null(selected_branch) || is.na(selected_branch)) {
  selected_branch <- "main"
}

# Helper to get the directory of the current script
get_script_dir <- function() {
  # Check if run via Rscript
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("--file=", "", file_arg))))
  }
  
  # Check if sourced
  if (!is.null(sys.frames()[[1]]$ofile)) {
    return(dirname(normalizePath(sys.frames()[[1]]$ofile)))
  }
  
  # Fallback to current directory
  return(getwd())
}

if (is_local) {
  message("Local installation mode enabled (--local)")
  config_file <- file.path(get_script_dir(), "launcher_config.json")
  
  if (file.exists(config_file)) {
    message("Reading config from: ", config_file)
    config_lines <- readLines(config_file, warn = FALSE)
    path_line <- grep("local_repo_path", config_lines, value = TRUE)
    local_path <- gsub('.*"local_repo_path"\\s*:\\s*"([^"]+)".*', "\\1", path_line)
    
    if (nchar(local_path) > 0 && dir.exists(local_path)) {
      MULTISCHOLAR_REF <- paste0("local::", local_path)
      message("Using local repository path: ", local_path)
    } else {
      message("WARNING: Local repository path not found or invalid. Falling back to remote.")
      MULTISCHOLAR_REF <- paste0(MULTISCHOLAR_REPO, "@", selected_branch)
    }
  } else {
    message("WARNING: launcher_config.json not found at ", config_file, ". Falling back to remote.")
    MULTISCHOLAR_REF <- paste0(MULTISCHOLAR_REPO, "@", selected_branch)
  }
} else {
  MULTISCHOLAR_REF <- paste0(MULTISCHOLAR_REPO, "@", selected_branch)
  message("Selected branch: ", selected_branch)
}
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
