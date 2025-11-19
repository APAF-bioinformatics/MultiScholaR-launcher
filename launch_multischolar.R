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
    
    # --- Pre-check: Attempt to load the package ---
    skip_dependency_install <- FALSE
    cat("DEBUG: Pre-checking if package loads successfully...\n")
    
    tryCatch({
      devtools::load_all(package_dir, quiet = FALSE)
      cat("DEBUG: ✓ Package loaded successfully. No dependency installation needed.\n")
      skip_dependency_install <- TRUE
    }, error = function(e) {
      cat("DEBUG: Package did not load. Analyzing error...\n")
      print(e)
      error_msg <- conditionMessage(e)
      
      # Check if it's a missing package error
      # Devtools error: ! The package "pkgname" is required.
      # Base R error: there is no package called 'pkgname'
      is_devtools_missing_pkg <- grepl("package \".+\" is required", error_msg, ignore.case = TRUE)
      is_base_missing_pkg <- grepl("there is no package called", error_msg, ignore.case = TRUE)
      
      if (is_devtools_missing_pkg || is_base_missing_pkg) {
        # Extract the missing package name
        missing_pkg <- NULL
        if (is_base_missing_pkg) {
          pkg_match <- regmatches(error_msg, regexpr("'[^']+'", error_msg))
          if (length(pkg_match) > 0) missing_pkg <- gsub("'", "", pkg_match[1])
        } else {
          pkg_match <- regmatches(error_msg, regexpr('"([^"]+)"', error_msg))
          if (length(pkg_match) > 0) missing_pkg <- gsub('"', "", pkg_match[1])
        }
        
        if (!is.null(missing_pkg)) {
          cat("DEBUG: Missing package identified:", missing_pkg, "\n")
          cat("DEBUG: Installing ONLY this package (update=FALSE to avoid touching other packages)...\n")
          
          # Helper to clean lock files on Windows
          clean_lock_files <- function() {
            if (!is_windows) return()
            lib_path <- .libPaths()[1]
            lock_dirs <- list.files(lib_path, pattern = "^00LOCK", full.names = TRUE)
            if (length(lock_dirs) > 0) {
              cat("DEBUG: Cleaning", length(lock_dirs), "lock file(s)...\n")
              for (lock_dir in lock_dirs) {
                tryCatch(unlink(lock_dir, recursive = TRUE, force = TRUE), error = function(e) {})
              }
            }
          }
          
          # Clean lock files first
          clean_lock_files()
          
          install_success <- FALSE
          tryCatch({
            # CRITICAL: Use update=FALSE to prevent BiocManager from updating other packages
            # Try source first (BiocManager default)
            BiocManager::install(missing_pkg, ask = FALSE, update = FALSE, dependencies = TRUE)
            install_success <- TRUE
            cat("DEBUG: ✓ Installed", missing_pkg, "\n")
          }, error = function(e_install) {
            cat("DEBUG: ✗ Installation failed (likely source compilation issue):", e_install$message, "\n")
            
            # Fallback: Force binary installation on Windows
            if (is_windows) {
              cat("DEBUG: Attempting binary installation as fallback...\n")
              clean_lock_files()
              tryCatch({
                install.packages(missing_pkg, repos = bioc_repos, type = "binary", dependencies = TRUE)
                install_success <<- TRUE
                cat("DEBUG: ✓ Installed", missing_pkg, "from binary\n")
              }, error = function(e_binary) {
                cat("DEBUG: ✗ Binary installation also failed:", e_binary$message, "\n")
              })
            }
          })
          
          if (install_success) {
            cat("DEBUG: Retrying package load...\n")
            tryCatch({
              devtools::load_all(package_dir, quiet = FALSE)
              cat("DEBUG: ✓ Package loaded successfully after installing missing dependency.\n")
              skip_dependency_install <<- TRUE
            }, error = function(e2) {
              cat("DEBUG: ✗ Package still failed to load. Will use fallback installation.\n")
              print(e2)
            })
          } else {
            cat("DEBUG: Could not install", missing_pkg, ". Will use fallback installation.\n")
          }
        }
      } else {
        cat("DEBUG: Error is not a simple missing package. Will use fallback installation.\n")
      }
    })
    
    # Fallback: If package still didn't load, install dependencies from DESCRIPTION
    if (!skip_dependency_install) {
      cat("DEBUG: Using fallback: Installing dependencies from DESCRIPTION file...\n")
      devtools::install_deps(package_dir, dependencies = c("Depends", "Imports"), upgrade = "never", quiet = FALSE)
      cat("DEBUG: ✓ Fallback dependency installation completed\n")
    }
  }, error = function(e) {
    cat("DEBUG: ✗ WARNING in dependency installation:", e$message, "\n")
    cat("DEBUG: Will attempt to continue anyway...\n")
  })
} else {
  cat("DEBUG: Cannot install dependencies - devtools not available\n")
}

# --- 7. Test package loading with devtools ---
cat("\n=== DEBUG: Testing Package Loading with devtools ===\n")
if (requireNamespace("devtools", quietly = TRUE)) {
  # Helper function to clean lock files (Windows-only issue)
  clean_lock_files <- function() {
    if (!is_windows) {
      return()  # Skip on macOS - lock files are a Windows issue
    }
    lib_path <- .libPaths()[1]
    lock_dirs <- list.files(lib_path, pattern = "^00LOCK", full.names = TRUE)
    if (length(lock_dirs) > 0) {
      cat("DEBUG: Found", length(lock_dirs), "lock file(s), attempting to remove...\n")
      for (lock_dir in lock_dirs) {
        tryCatch({
          unlink(lock_dir, recursive = TRUE, force = TRUE)
          cat("DEBUG: Removed lock:", basename(lock_dir), "\n")
        }, error = function(e) {
          cat("DEBUG: Could not remove lock:", basename(lock_dir), "-", e$message, "\n")
        })
      }
    }
  }
  
  package_loaded <- FALSE
  max_retries <- 2
  retry_count <- 0
  
  while (!package_loaded && retry_count < max_retries) {
    # Clean lock files before each retry (Windows only)
    clean_lock_files()
    tryCatch({
      cat("DEBUG: Attempting to load package from:", package_dir, "\n")
      devtools::load_all(package_dir, quiet = FALSE)
      cat("DEBUG: ✓ Package loaded successfully with devtools\n")
      package_loaded <- TRUE
    }, error = function(e) {
      error_msg <- as.character(e$message)
      cat("DEBUG: ✗ ERROR loading package with devtools:", error_msg, "\n")
      
      # Check for version conflict errors
      if (grepl("is being loaded, but.*is required", error_msg, ignore.case = TRUE) ||
          grepl("version.*is required", error_msg, ignore.case = TRUE)) {
        cat("DEBUG: ⚠ VERSION CONFLICT detected - existing package version is too old\n")
        cat("DEBUG: This requires updating existing packages (will be handled by BiocManager with update=TRUE)\n")
        
        # Extract package names from version conflict message
        # Pattern: "namespace 'PackageName' X.Y.Z is being loaded, but >= A.B.C is required"
        pkg_version_match <- regmatches(error_msg, regexpr("'[^']+'", error_msg))
        if (length(pkg_version_match) > 0) {
          conflict_pkg <- gsub("'", "", pkg_version_match[1])
          cat("DEBUG: Package with version conflict:", conflict_pkg, "\n")
          cat("DEBUG: Attempting to update", conflict_pkg, "and dependencies...\n")
          
          if (requireNamespace("BiocManager", quietly = TRUE)) {
            tryCatch({
              clean_lock_files()  # Clean before install
              BiocManager::install(conflict_pkg, ask = FALSE, update = TRUE, dependencies = TRUE)
              cat("DEBUG: ✓ Updated", conflict_pkg, "and dependencies\n")
            }, error = function(e2) {
              cat("DEBUG: ✗ Failed to update", conflict_pkg, ":", e2$message, "\n")
            })
          }
        }
      }
      # Check if error is about a missing package
      else if (grepl("there is no package called", error_msg, ignore.case = TRUE)) {
        # Extract package name from error message
        pkg_match <- regmatches(error_msg, regexpr("'[^']+'", error_msg))
        if (length(pkg_match) > 0) {
          missing_pkg <- gsub("'", "", pkg_match[1])
          cat("DEBUG: Detected MISSING package:", missing_pkg, "\n")
          cat("DEBUG: Attempting to install missing package...\n")
          
          # Try to install from Bioconductor first (many annotation packages are there)
          if (requireNamespace("BiocManager", quietly = TRUE)) {
            tryCatch({
              cat("DEBUG: Installing", missing_pkg, "with dependencies and allowing updates...\n")
              clean_lock_files()  # Clean before install
              BiocManager::install(missing_pkg, ask = FALSE, update = TRUE, dependencies = TRUE)
              cat("DEBUG: ✓ Installed", missing_pkg, "from Bioconductor\n")
            }, error = function(e2) {
              # If Bioconductor fails, try CRAN
              cat("DEBUG: Bioconductor install failed:", e2$message, "\n")
              cat("DEBUG: Trying CRAN...\n")
              tryCatch({
                clean_lock_files()  # Clean before install
                install.packages(missing_pkg, repos = "https://cran.rstudio.com/", dependencies = TRUE)
                cat("DEBUG: ✓ Installed", missing_pkg, "from CRAN\n")
              }, error = function(e3) {
                cat("DEBUG: ✗ Failed to install", missing_pkg, "from both sources\n")
                cat("DEBUG: CRAN error:", e3$message, "\n")
              })
            })
          } else {
            # No BiocManager, just try CRAN
            tryCatch({
              clean_lock_files()  # Clean before install
              install.packages(missing_pkg, repos = "https://cran.rstudio.com/", dependencies = TRUE)
              cat("DEBUG: ✓ Installed", missing_pkg, "from CRAN\n")
            }, error = function(e3) {
              cat("DEBUG: ✗ Failed to install", missing_pkg, "\n")
              cat("DEBUG: Error:", e3$message, "\n")
            })
          }
        }
      } else {
        cat("DEBUG: Other error type detected\n")
        cat("DEBUG: Error details:\n")
        print(e)
      }
    })
    retry_count <- retry_count + 1
  }
  
  if (!package_loaded) {
    cat("DEBUG: WARNING: Package failed to load after", max_retries, "attempts\n")
    cat("DEBUG: Attempting fallback: installing critical Bioconductor dependencies...\n")
    
    # Fallback: Install critical Bioconductor packages that are commonly needed
    if (requireNamespace("BiocManager", quietly = TRUE)) {
      tryCatch({
        cat("DEBUG: Installing critical Bioconductor packages (GO.db, AnnotationDbi) with updates...\n")
        cat("DEBUG: This will update existing packages if needed (e.g., S4Vectors)\n")
        
        # Install GO.db and AnnotationDbi with all dependencies and updates
        critical_packages <- c("GO.db", "AnnotationDbi")
        BiocManager::install(critical_packages, ask = FALSE, update = TRUE, dependencies = TRUE)
        
        cat("DEBUG: ✓ Critical Bioconductor packages installed/updated\n")
        cat("DEBUG: Retrying package load...\n")
        
        # Try loading one more time
        tryCatch({
          devtools::load_all(package_dir, quiet = FALSE)
          cat("DEBUG: ✓ Package loaded successfully after fallback installation\n")
          package_loaded <- TRUE
        }, error = function(e3) {
          cat("DEBUG: ✗ Package still failed to load after fallback:", e3$message, "\n")
        })
      }, error = function(e2) {
        cat("DEBUG: ✗ Fallback installation failed:", e2$message, "\n")
        cat("DEBUG: Package may require manual dependency resolution\n")
      })
    } else {
      cat("DEBUG: Cannot perform fallback - BiocManager not available\n")
    }
  }
} else {
  cat("DEBUG: Cannot test package loading - devtools not available\n")
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