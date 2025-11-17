# ========================================
# SUPER DEBUGGED MultiScholaR Launch Script
# ========================================

# Force immediate output
options(warn = 1)
options(error = function() {
  cat("ERROR OCCURRED:\n")
  print(sys.calls())
  traceback()
})

# Helper function to read config file
read_config <- function(config_path) {
  if (!file.exists(config_path)) {
    return(NULL)
  }
  
  lines <- readLines(config_path, warn = FALSE)
  config <- list()
  
  for (line in lines) {
    line <- trimws(line)
    if (line == "" || grepl("^#", line)) {
      next  # Skip empty lines and comments
    }
    
    if (grepl("=", line)) {
      parts <- strsplit(line, "=", fixed = TRUE)[[1]]
      if (length(parts) == 2) {
        key <- trimws(parts[1])
        value <- trimws(parts[2])
        config[[key]] <- value
      }
    }
  }
  
  return(config)
}

# Get launcher directory (where config.txt should be)
get_launcher_dir <- function() {
  # Try to get from command line args first
  args <- commandArgs(trailingOnly = FALSE)
  script_path <- grep("^--file=", args, value = TRUE)
  if (length(script_path) > 0) {
    launcher_dir <- dirname(sub("^--file=", "", script_path))
    return(normalizePath(launcher_dir))
  }
  # Fallback: assume config.txt is in current working directory
  return(getwd())
}

cat("=== DEBUG: R SCRIPT STARTED ===\n")
cat("DEBUG: R version:", R.version.string, "\n")
cat("DEBUG: Platform:", R.version$platform, "\n")
cat("DEBUG: Working directory:", getwd(), "\n")
cat("DEBUG: Command line args:", paste(commandArgs(), collapse = " "), "\n")

# --- 1. Test basic R functionality ---
cat("\n=== DEBUG: Testing Basic R Functionality ===\n")
tryCatch({
  cat("DEBUG: Testing basic math: 2+2 =", 2+2, "\n")
  cat("DEBUG: Testing basic function: length(1:5) =", length(1:5), "\n")
  cat("DEBUG: Basic R functionality works\n")
}, error = function(e) {
  cat("DEBUG: ERROR in basic R functionality:", e$message, "\n")
  stop("Basic R functionality failed")
})

# --- 2. Test package loading ---
cat("\n=== DEBUG: Testing Package Loading ===\n")
test_packages <- c("base", "utils", "stats")
for (pkg in test_packages) {
  tryCatch({
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat("DEBUG: ✓", pkg, "loaded successfully\n")
    } else {
      cat("DEBUG: ✗", pkg, "failed to load\n")
    }
  }, error = function(e) {
    cat("DEBUG: ✗", pkg, "ERROR:", e$message, "\n")
  })
}

# --- 3. Test file system access ---
cat("\n=== DEBUG: Testing File System Access ===\n")
current_dir <- getwd()
cat("DEBUG: Current directory:", current_dir, "\n")
cat("DEBUG: Directory exists:", dir.exists(current_dir), "\n")

if (dir.exists(current_dir)) {
  cat("DEBUG: Directory contents:\n")
  files <- list.files(current_dir, full.names = FALSE)
  for (i in seq_along(files)) {
    cat("DEBUG:   ", i, ":", files[i], "\n")
  }
} else {
  cat("DEBUG: ERROR - Current directory does not exist!\n")
}

# --- 4. Get package directory from command line argument or config ---
cat("\n=== DEBUG: Getting Package Directory ===\n")
args <- commandArgs(trailingOnly = TRUE)

if (length(args) > 0 && args[1] != "") {
  # Path provided as command-line argument
  package_dir <- args[1]
  cat("DEBUG: Package directory from command line:", package_dir, "\n")
} else {
  # Try to read from config file (for backward compatibility)
  cat("DEBUG: No command line argument, checking config file...\n")
  launcher_dir <- get_launcher_dir()
  config_path <- file.path(launcher_dir, "config.txt")
  cat("DEBUG: Launcher directory:", launcher_dir, "\n")
  cat("DEBUG: Config file path:", config_path, "\n")
  
  config <- read_config(config_path)
  if (is.null(config) || is.null(config$MULTISCHOLAR_PATH)) {
    stop("ERROR: Package directory not specified.\n",
         "Usage: Rscript launch_multischolar.R <path_to_MultiScholaR>\n",
         "Or create config.txt with MULTISCHOLAR_PATH=<path>")
  }
  package_dir <- config$MULTISCHOLAR_PATH
}

# Normalize path (R handles forward slashes on Windows too)
package_dir <- normalizePath(package_dir, mustWork = FALSE)

cat("DEBUG: Package directory:", package_dir, "\n")
cat("DEBUG: Package directory exists:", dir.exists(package_dir), "\n")

if (dir.exists(package_dir)) {
  cat("DEBUG: Package directory contents:\n")
  pkg_files <- list.files(package_dir, full.names = FALSE)
  for (i in seq_along(pkg_files)) {
    cat("DEBUG:   ", i, ":", pkg_files[i], "\n")
  }
  
  # Check for key files
  key_files <- c("DESCRIPTION", "NAMESPACE", "R", "inst")
  for (file in key_files) {
    file_path <- file.path(package_dir, file)
    cat("DEBUG:   ", file, "exists:", file.exists(file_path), "\n")
  }
} else {
  cat("DEBUG: ERROR - Package directory does not exist!\n")
}

# --- 5. Test devtools availability ---
cat("\n=== DEBUG: Testing devtools Package ===\n")
tryCatch({
  if (requireNamespace("devtools", quietly = TRUE)) {
    cat("DEBUG: ✓ devtools is available\n")
    cat("DEBUG: devtools version:", as.character(utils::packageVersion("devtools")), "\n")
  } else {
    cat("DEBUG: ✗ devtools is NOT available\n")
    cat("DEBUG: Attempting to install devtools...\n")
    install.packages("devtools", repos = "https://cran.rstudio.com/")
    if (requireNamespace("devtools", quietly = TRUE)) {
      cat("DEBUG: ✓ devtools installed and loaded successfully\n")
    } else {
      cat("DEBUG: ✗ devtools installation failed\n")
    }
  }
}, error = function(e) {
  cat("DEBUG: ✗ ERROR with devtools:", e$message, "\n")
})

# --- 6. Test package loading with devtools ---
cat("\n=== DEBUG: Testing Package Loading with devtools ===\n")
if (requireNamespace("devtools", quietly = TRUE)) {
  tryCatch({
    cat("DEBUG: Attempting to load package from:", package_dir, "\n")
    devtools::load_all(package_dir, quiet = FALSE)
    cat("DEBUG: ✓ Package loaded successfully with devtools\n")
  }, error = function(e) {
    cat("DEBUG: ✗ ERROR loading package with devtools:", e$message, "\n")
    cat("DEBUG: Error details:\n")
    print(e)
  })
} else {
  cat("DEBUG: Cannot test package loading - devtools not available\n")
}

# --- 7. Test function availability ---
cat("\n=== DEBUG: Testing Function Availability ===\n")
functions_to_check <- c("loadDependencies", "setupDirectories", "RunApplet", "MultiScholaRapp")
for (func in functions_to_check) {
  exists_check <- exists(func, envir = .GlobalEnv)
  cat("DEBUG: Function", func, "exists:", exists_check, "\n")
  
  if (exists_check) {
    func_obj <- get(func, envir = .GlobalEnv)
    cat("DEBUG:   Type:", typeof(func_obj), "\n")
    cat("DEBUG:   Class:", paste(class(func_obj), collapse = ", "), "\n")
    cat("DEBUG:   Is function:", is.function(func_obj), "\n")
  }
}

# --- 8. Test dependency loading ---
cat("\n=== DEBUG: Testing Dependency Loading ===\n")
if (exists("loadDependencies", envir = .GlobalEnv)) {
  tryCatch({
    cat("DEBUG: Calling loadDependencies...\n")
    loadDependencies()
    cat("DEBUG: ✓ loadDependencies completed successfully\n")
  }, error = function(e) {
    cat("DEBUG: ✗ ERROR in loadDependencies:", e$message, "\n")
    print(e)
  })
} else {
  cat("DEBUG: loadDependencies function not available\n")
}

# --- 9. Test app launching ---
cat("\n=== DEBUG: Testing App Launch ===\n")
if (exists("MultiScholaRapp", envir = .GlobalEnv)) {
  tryCatch({
    cat("DEBUG: MultiScholaRapp function found\n")
    cat("DEBUG: About to call MultiScholaRapp()...\n")
    MultiScholaRapp()
    cat("DEBUG: ✓ MultiScholaRapp completed\n")
  }, error = function(e) {
    cat("DEBUG: ✗ ERROR in MultiScholaRapp:", e$message, "\n")
    print(e)
  })
} else {
  cat("DEBUG: ✗ MultiScholaRapp function not found\n")
  cat("DEBUG: Available functions in global environment:\n")
  all_funcs <- ls(envir = .GlobalEnv)
  for (i in seq_along(all_funcs)) {
    cat("DEBUG:   ", i, ":", all_funcs[i], "\n")
  }
}

# --- 10. Final status ---
cat("\n=== DEBUG: Final Status ===\n")
cat("DEBUG: Script completed without fatal errors\n")
cat("DEBUG: R session will now exit\n")

# Force output flush
flush.console()