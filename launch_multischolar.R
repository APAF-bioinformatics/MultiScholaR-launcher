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

# Detect operating system
is_windows <- .Platform$OS.type == "windows"
os_name <- Sys.info()["sysname"]
cat("DEBUG: Operating system:", os_name, "\n")
cat("DEBUG: Is Windows:", is_windows, "\n")

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

# --- 6. Install dependencies needed to load package ---
cat("\n=== DEBUG: Installing Dependencies to Load Package ===\n")
if (requireNamespace("devtools", quietly = TRUE)) {
  tryCatch({
    # Install pacman (needed by loadDependencies function)
    if (!requireNamespace("pacman", quietly = TRUE)) {
      cat("DEBUG: Installing pacman...\n")
      install.packages("pacman", repos = "https://cran.rstudio.com/")
    }
    
    # Install BiocManager (needed for Bioconductor packages)
    if (!requireNamespace("BiocManager", quietly = TRUE)) {
      cat("DEBUG: Installing BiocManager...\n")
      install.packages("BiocManager", repos = "https://cran.rstudio.com/")
    }
    
    # Set up Bioconductor repositories
    if (requireNamespace("BiocManager", quietly = TRUE)) {
      bioc_repos <- BiocManager::repositories()
      options(repos = bioc_repos)
      cat("DEBUG: Bioconductor repositories configured\n")
    }
    
    # --- Pre-check: Try to load the package ---
    skip_dependency_install <- FALSE
    cat("DEBUG: Pre-checking if package loads successfully...\n")
    
    tryCatch({
      devtools::load_all(package_dir, quiet = FALSE)
      cat("DEBUG: ✓ Package loaded successfully. No dependency installation needed.\n")
      skip_dependency_install <- TRUE
    }, error = function(e) {
      cat("DEBUG: Package failed to load. Will install all dependencies from DESCRIPTION.\n")
      print(e)
    })
    
    # If package didn't load, install all dependencies from DESCRIPTION
    if (!skip_dependency_install) {
      cat("DEBUG: Installing all dependencies from DESCRIPTION file...\n")
      cat("DEBUG: First attempt: Using upgrade='never' to avoid updating existing packages\n")
      
      # First attempt: try without upgrades
      tryCatch({
        devtools::install_deps(package_dir, dependencies = c("Depends", "Imports"), upgrade = "never", quiet = FALSE)
        cat("DEBUG: ✓ Initial dependency installation completed\n")
      }, error = function(e) {
        cat("DEBUG: ✗ Initial installation attempt failed:", e$message, "\n")
      })
      
      # Try loading after initial installation to detect version conflicts
      cat("DEBUG: Testing package load after initial installation...\n")
      load_success <- FALSE
      version_conflict_detected <- FALSE
      missing_package_detected <- FALSE
      load_error_msg <- ""
      conflicting_packages <- character()
      
      tryCatch({
        devtools::load_all(package_dir, quiet = FALSE)
        cat("DEBUG: ✓ Package loaded successfully after initial installation\n")
        load_success <- TRUE
      }, error = function(e) {
        load_error_msg <- conditionMessage(e)
        cat("DEBUG: Package still failed to load. Error:", load_error_msg, "\n")
        
        # Enhanced error parsing to extract package information
        # Pattern 1: "namespace 'PackageName' X.Y.Z is already loaded, but >= A.B.C is required"
        if (grepl("namespace '[^']+' [^ ]+ is already loaded, but >= [^ ]+ is required", load_error_msg)) {
          version_conflict_detected <- TRUE
          
          # Extract package name and versions
          pkg_match <- regmatches(load_error_msg, regexpr("namespace '([^']+)' ([^ ]+) is already loaded, but >= ([^ ]+) is required", load_error_msg))
          if (length(pkg_match) > 0) {
            pkg_name <- sub("namespace '([^']+)' .*", "\\1", pkg_match[1])
            current_ver <- sub("namespace '[^']+' ([^ ]+) is already loaded.*", "\\1", pkg_match[1])
            required_ver <- sub(".*but >= ([^ ]+) is required", "\\1", pkg_match[1])
            conflicting_packages <- c(conflicting_packages, pkg_name)
            cat("DEBUG: ⚠ Version conflict detected!\n")
            cat("DEBUG:   Package:", pkg_name, "\n")
            cat("DEBUG:   Current version:", current_ver, "\n")
            cat("DEBUG:   Required version: >=", required_ver, "\n")
            cat("DEBUG:   Action: Will retry with package upgrades.\n")
          } else {
            # Fallback: just extract package name
            pkg_match <- regmatches(load_error_msg, regexpr("namespace '([^']+)'", load_error_msg))
            if (length(pkg_match) > 0) {
              pkg_name <- sub("namespace '([^']+)'.*", "\\1", pkg_match[1])
              conflicting_packages <- c(conflicting_packages, pkg_name)
              cat("DEBUG: ⚠ Version conflict detected for package:", pkg_name, "\n")
              cat("DEBUG:   Action: Will retry with package upgrades.\n")
            }
          }
        }
        # Pattern 2: "The package \"PackageName\" is required" (missing package)
        else if (grepl("The package [\"']([^\"']+)[\"'] is required", load_error_msg)) {
          missing_package_detected <- TRUE
          pkg_match <- regmatches(load_error_msg, regexpr("The package [\"']([^\"']+)[\"'] is required", load_error_msg))
          if (length(pkg_match) > 0) {
            pkg_name <- sub("The package [\"']([^\"']+)[\"'].*", "\\1", pkg_match[1])
            conflicting_packages <- c(conflicting_packages, pkg_name)
            cat("DEBUG: ⚠ Missing package detected:", pkg_name, "\n")
            cat("DEBUG:   Action: Will retry with package upgrades to force installation.\n")
            version_conflict_detected <- TRUE  # Treat missing packages as needing upgrade retry
          }
        }
        # Pattern 3: Generic version requirement error
        else if (grepl("is already loaded, but >= .* is required", load_error_msg)) {
          version_conflict_detected <- TRUE
          cat("DEBUG: ⚠ Version conflict detected (generic pattern)!\n")
          cat("DEBUG:   Action: Will retry with package upgrades.\n")
        }
      })
      
      # If version conflict detected, retry with upgrades
      if (!load_success && version_conflict_detected) {
        if (length(conflicting_packages) > 0) {
          cat("DEBUG: Retrying dependency installation with upgrade='always' to resolve conflicts...\n")
          cat("DEBUG: Affected packages:", paste(conflicting_packages, collapse = ", "), "\n")
        } else {
          cat("DEBUG: Retrying dependency installation with upgrade='always' to resolve version conflicts...\n")
        }
        cat("DEBUG: This will upgrade packages to meet version requirements.\n")
        
        tryCatch({
          devtools::install_deps(package_dir, dependencies = c("Depends", "Imports"), upgrade = "always", quiet = FALSE)
          cat("DEBUG: ✓ Dependency installation with upgrades completed\n")
          
          # Try loading again after upgrade
          cat("DEBUG: Testing package load after upgrade...\n")
          tryCatch({
            devtools::load_all(package_dir, quiet = FALSE)
            cat("DEBUG: ✓ Package loaded successfully after upgrade\n")
            load_success <- TRUE
            skip_dependency_install <- TRUE  # Mark as successful so step 7 doesn't retry
          }, error = function(e2) {
            error_msg2 <- conditionMessage(e2)
            cat("DEBUG: ✗ Package still failed to load after upgrade.\n")
            cat("DEBUG: Error:", error_msg2, "\n")
            cat("DEBUG: This may indicate a deeper dependency issue that requires manual resolution.\n")
          })
        }, error = function(e) {
          cat("DEBUG: ✗ Retry with upgrades failed during installation.\n")
          cat("DEBUG: Error:", e$message, "\n")
          cat("DEBUG: You may need to manually install or upgrade the conflicting packages.\n")
        })
      } else if (!load_success && !version_conflict_detected) {
        cat("DEBUG: ⚠ Package loading failed, but no version conflicts detected.\n")
        cat("DEBUG: Error type may be different. Will attempt again in verification step.\n")
      }
    }
  }, error = function(e) {
    cat("DEBUG: ✗ WARNING in dependency installation:", e$message, "\n")
    cat("DEBUG: Will attempt to continue anyway...\n")
  })
} else {
  cat("DEBUG: Cannot install dependencies - devtools not available\n")
}

# --- 7. Verify package loading ---
cat("\n=== DEBUG: Verifying Package Loading ===\n")
if (requireNamespace("devtools", quietly = TRUE)) {
  if (!skip_dependency_install) {
    # Step 6 didn't succeed, so we need to try loading after the fallback installation
    cat("DEBUG: Attempting to load package after dependency installation...\n")
    cat("DEBUG: Note: If this fails, the package may require manual dependency resolution\n")
    tryCatch({
      devtools::load_all(package_dir, quiet = FALSE)
      cat("DEBUG: ✓ Package loaded successfully after dependency installation\n")
      skip_dependency_install <- TRUE  # Mark as successful
    }, error = function(e) {
      error_msg <- conditionMessage(e)
      cat("DEBUG: ✗ ERROR: Package still failed to load after all installation attempts\n")
      cat("DEBUG: Error message:", error_msg, "\n")
      cat("DEBUG: \n")
      cat("DEBUG: Troubleshooting suggestions:\n")
      cat("DEBUG: 1. Check if all required packages are listed in DESCRIPTION file\n")
      cat("DEBUG: 2. Verify that Bioconductor packages are properly configured\n")
      cat("DEBUG: 3. Try manually installing missing packages:\n")
      
      # Try to extract package name from error for helpful suggestion
      if (grepl("The package [\"']([^\"']+)[\"'] is required", error_msg)) {
        pkg_match <- regmatches(error_msg, regexpr("The package [\"']([^\"']+)[\"'] is required", error_msg))
        if (length(pkg_match) > 0) {
          pkg_name <- sub("The package [\"']([^\"']+)[\"'].*", "\\1", pkg_match[1])
          cat("DEBUG:    install.packages(\"", pkg_name, "\")\n", sep = "")
        }
      } else if (grepl("namespace '[^']+'", error_msg)) {
        pkg_match <- regmatches(error_msg, regexpr("namespace '([^']+)'", error_msg))
        if (length(pkg_match) > 0) {
          pkg_name <- sub("namespace '([^']+)'.*", "\\1", pkg_match[1])
          cat("DEBUG:    Package '", pkg_name, "' may need to be upgraded\n", sep = "")
          cat("DEBUG:    Try: install.packages(\"", pkg_name, "\")\n", sep = "")
        }
      }
      
      cat("DEBUG: 4. The package may require manual dependency resolution\n")
    })
  } else {
    cat("DEBUG: ✓ Package already loaded successfully in Step 6\n")
  }
} else {
  cat("DEBUG: Cannot verify package loading - devtools not available\n")
}

# --- 8. Test function availability ---
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

# --- 9. Install all dependencies via loadDependencies() ---
cat("\n=== DEBUG: Installing All Dependencies via loadDependencies() ===\n")
cat("DEBUG: This will install all CRAN, Bioconductor, and GitHub packages required by MultiScholaR\n")
cat("DEBUG: This may take several minutes on first run...\n")
cat("DEBUG: Note: Base Bioconductor packages were already updated in step 6\n")

if (exists("loadDependencies", envir = .GlobalEnv)) {
  tryCatch({
    cat("DEBUG: Calling loadDependencies(verbose = TRUE)...\n")
    cat("DEBUG: Note: loadDependencies() uses update=FALSE, so base packages should already be updated\n")
    loadDependencies(verbose = TRUE)
    cat("DEBUG: ✓ loadDependencies completed successfully\n")
    cat("DEBUG: All dependencies should now be installed and loaded\n")
    
    # Ensure MultiScholaR package is still loaded after dependency installation
    if (requireNamespace("devtools", quietly = TRUE)) {
      cat("DEBUG: Reloading MultiScholaR package to ensure all dependencies are available...\n")
      tryCatch({
        devtools::load_all(package_dir, quiet = FALSE)
        cat("DEBUG: ✓ Package reloaded successfully\n")
      }, error = function(e2) {
        cat("DEBUG: WARNING: Package reload failed:", e2$message, "\n")
        cat("DEBUG: Continuing anyway - dependencies should be available\n")
      })
    }
  }, error = function(e) {
    cat("DEBUG: ✗ ERROR in loadDependencies:", e$message, "\n")
    cat("DEBUG: Error details:\n")
    print(e)
    cat("DEBUG: WARNING: Some dependencies may not be installed. The app may not work correctly.\n")
  })
} else {
  cat("DEBUG: ✗ loadDependencies function not available\n")
  cat("DEBUG: Package may not have loaded successfully. Check errors above.\n")
}

# --- 10. Test app launching ---
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

# --- 11. Final status ---
cat("\n=== DEBUG: Final Status ===\n")
cat("DEBUG: Script completed without fatal errors\n")
cat("DEBUG: R session will now exit\n")

# Force output flush
flush.console()