# ========================================
# MultiScholaR Launch Script
# ========================================
# This script loads and launches MultiScholaR.
# Dependencies should already be installed by bootstrap_dependencies.R
#
# Exit codes:
#   0 - Success (app ran and exited normally)
#   1 - Error (package failed to load or app crashed)

# Force immediate output
options(warn = 1)
options(error = function() {
  cat("ERROR OCCURRED:\n")
  traceback()
})

cat("========================================\n")
cat("MultiScholaR Launcher\n")
cat("========================================\n\n")

# --- Helper function to read config file ---
read_config <- function(config_path) {
  if (!file.exists(config_path)) {
    return(NULL)
  }
  
  lines <- readLines(config_path, warn = FALSE)
  config <- list()
  
  for (line in lines) {
    line <- trimws(line)
    if (line == "" || grepl("^#", line)) next
    
    if (grepl("=", line)) {
      parts <- strsplit(line, "=", fixed = TRUE)[[1]]
      if (length(parts) == 2) {
        config[[trimws(parts[1])]] <- trimws(parts[2])
      }
    }
  }
  
  return(config)
}

# --- Get launcher directory ---
get_launcher_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  script_path <- grep("^--file=", args, value = TRUE)
  if (length(script_path) > 0) {
    return(normalizePath(dirname(sub("^--file=", "", script_path))))
  }
  return(getwd())
}

# --- Main Launch Logic ---
main <- function() {
  cat("R version:", R.version.string, "\n")
  cat("Platform:", R.version$platform, "\n\n")
  
  # Get package directory from command line argument or config
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) > 0 && args[1] != "") {
    package_dir <- args[1]
    cat("Package directory (from args):", package_dir, "\n")
  } else {
    # Try config file fallback
    launcher_dir <- get_launcher_dir()
    config_path <- file.path(launcher_dir, "config.txt")
    config <- read_config(config_path)
    
    if (is.null(config) || is.null(config$MULTISCHOLAR_PATH)) {
      stop("ERROR: Package directory not specified.\n",
           "Usage: Rscript launch_multischolar.R <path_to_MultiScholaR>")
    }
    package_dir <- config$MULTISCHOLAR_PATH
    cat("Package directory (from config):", package_dir, "\n")
  }
  
  # Normalize and validate path
  package_dir <- normalizePath(package_dir, mustWork = FALSE)
  
  if (!dir.exists(package_dir)) {
    stop("ERROR: Package directory does not exist: ", package_dir)
  }
  
  # Check for key files
  desc_path <- file.path(package_dir, "DESCRIPTION")
  if (!file.exists(desc_path)) {
    stop("ERROR: DESCRIPTION file not found. Is this a valid R package?")
  }
  
  cat("Package directory validated.\n\n")
  
  # --- Ensure devtools is available ---
  if (!requireNamespace("devtools", quietly = TRUE)) {
    cat("Installing devtools...\n")
    utils::install.packages("devtools", repos = "https://cran.rstudio.com/")
  }
  
  if (!requireNamespace("devtools", quietly = TRUE)) {
    stop("ERROR: devtools is required but could not be installed.")
  }
  
  # --- Load the package ---
  cat("--- Loading MultiScholaR ---\n")
  
  tryCatch({
    devtools::load_all(package_dir, quiet = FALSE)
    cat("\nPackage loaded successfully!\n\n")
  }, error = function(e) {
    cat("\nERROR: Failed to load package.\n")
    cat("Error message:", conditionMessage(e), "\n\n")
    
    # Check for common issues
    error_msg <- conditionMessage(e)
    
    if (grepl("namespace .* is already loaded", error_msg)) {
      cat("This appears to be a namespace/version conflict.\n")
      cat("Try running the bootstrap script again or restart R.\n")
    } else if (grepl("there is no package called", error_msg)) {
      cat("A required package is missing.\n")
      cat("Try running the bootstrap script to install dependencies.\n")
    }
    
    stop("Package loading failed. See error above.")
  })
  
  # --- Run loadDependencies if available ---
  if (exists("loadDependencies", envir = .GlobalEnv)) {
    cat("--- Running loadDependencies ---\n")
    cat("This ensures all runtime dependencies are loaded...\n\n")
    
    tryCatch({
      loadDependencies(verbose = TRUE)
      cat("\nloadDependencies completed.\n\n")
    }, error = function(e) {
      cat("WARNING: loadDependencies encountered an error:", conditionMessage(e), "\n")
      cat("Continuing anyway - app may still work.\n\n")
    })
  }
  
  # --- Launch the app ---
  cat("--- Launching MultiScholaR App ---\n\n")
  
  if (!exists("MultiScholaRapp", envir = .GlobalEnv)) {
    stop("ERROR: MultiScholaRapp function not found. Package may not have loaded correctly.")
  }
  
  cat("Starting MultiScholaRapp()...\n\n")
  MultiScholaRapp()
  
  cat("\n========================================\n")
  cat("MultiScholaR session ended.\n")
  cat("========================================\n")
}

# Run with error handling
tryCatch({
  main()
}, error = function(e) {
  cat("\n========================================\n")
  cat("LAUNCH FAILED\n")
  cat("========================================\n")
  cat("Error:", conditionMessage(e), "\n")
  quit(status = 1, save = "no")
})
