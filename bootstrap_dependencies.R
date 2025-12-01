# ========================================
# MultiScholaR Dependency Bootstrap Script
# ========================================
# This script installs/upgrades dependencies WITHOUT loading MultiScholaR
# to avoid namespace conflicts. It parses DESCRIPTION directly.
#
# Exit codes:
#   0  - All dependencies satisfied, ready to launch
#   42 - Packages were upgraded, R session restart required
#   1  - Error occurred

# Force immediate output
options(warn = 1)

cat("========================================\n")
cat("MultiScholaR Dependency Bootstrap\n")
cat("========================================\n\n")

# --- Helper: Parse dependency string from DESCRIPTION ---
# Handles formats like: "pkg1, pkg2 (>= 1.0.0), pkg3"
parse_dependencies <- function(dep_string) {
  if (is.na(dep_string) || dep_string == "") {
    return(data.frame(package = character(), version = character(), stringsAsFactors = FALSE))
  }
  
  # Split by comma
  deps <- strsplit(dep_string, ",")[[1]]
  deps <- trimws(deps)
  deps <- deps[deps != ""]
  
  result <- data.frame(package = character(), version = character(), stringsAsFactors = FALSE)
  
  for (dep in deps) {
    # Extract package name and version requirement
    # Pattern: "package (>= 1.0.0)" or just "package"
    if (grepl("\\(", dep)) {
      pkg_name <- trimws(sub("\\s*\\(.*", "", dep))
      version_match <- regmatches(dep, regexpr("\\([^)]+\\)", dep))
      if (length(version_match) > 0) {
        # Extract version number, handling ">= X.Y.Z" format
        version_req <- gsub("[()>=<\\s]", "", version_match)
      } else {
        version_req <- ""
      }
    } else {
      pkg_name <- trimws(dep)
      version_req <- ""
    }
    
    # Skip R itself and empty names
    if (pkg_name != "" && pkg_name != "R") {
      result <- rbind(result, data.frame(package = pkg_name, version = version_req, stringsAsFactors = FALSE))
    }
  }
  
  return(result)
}

# --- Helper: Compare versions ---
version_satisfied <- function(installed_ver, required_ver) {
  if (is.null(required_ver) || required_ver == "" || is.na(required_ver)) {
    return(TRUE)
  }
  tryCatch({
    return(package_version(installed_ver) >= package_version(required_ver))
  }, error = function(e) {
    return(TRUE)  # If we can't parse, assume OK
  })
}

# --- Helper: Check if package needs install/upgrade ---
needs_install <- function(pkg_name, required_version = "") {
  if (!requireNamespace(pkg_name, quietly = TRUE)) {
    return(list(needed = TRUE, reason = "not_installed"))
  }
  
  if (required_version != "") {
    installed_ver <- tryCatch(
      as.character(utils::packageVersion(pkg_name)),
      error = function(e) "0.0.0"
    )
    if (!version_satisfied(installed_ver, required_version)) {
      return(list(needed = TRUE, reason = "version_too_old", 
                  installed = installed_ver, required = required_version))
    }
  }
  
  return(list(needed = FALSE))
}

# --- Main Bootstrap Logic ---
main <- function() {
  # Get package directory from command line argument
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) < 1 || args[1] == "") {
    stop("Usage: Rscript bootstrap_dependencies.R <path_to_MultiScholaR>")
  }
  
  package_dir <- normalizePath(args[1], mustWork = FALSE)
  cat("Package directory:", package_dir, "\n")
  
  if (!dir.exists(package_dir)) {
    stop("ERROR: Package directory does not exist: ", package_dir)
  }
  
  # Check for DESCRIPTION file
  desc_path <- file.path(package_dir, "DESCRIPTION")
  if (!file.exists(desc_path)) {
    stop("ERROR: DESCRIPTION file not found at: ", desc_path)
  }
  
  cat("Reading DESCRIPTION file...\n")
  
  # Parse DESCRIPTION using read.dcf (base R, no package loading)
  desc <- read.dcf(desc_path)
  
  # Extract dependency fields
  imports_str <- if ("Imports" %in% colnames(desc)) desc[1, "Imports"] else ""
  depends_str <- if ("Depends" %in% colnames(desc)) desc[1, "Depends"] else ""
  suggests_str <- if ("Suggests" %in% colnames(desc)) desc[1, "Suggests"] else ""
  remotes_str <- if ("Remotes" %in% colnames(desc)) desc[1, "Remotes"] else ""
  
  # Parse all dependencies
  imports <- parse_dependencies(imports_str)
  depends <- parse_dependencies(depends_str)
  suggests <- parse_dependencies(suggests_str)
  
  cat("\nFound dependencies:\n")
  cat("  Imports:", nrow(imports), "packages\n")
  cat("  Depends:", nrow(depends), "packages\n")
  cat("  Suggests:", nrow(suggests), "packages\n")
  
  # Combine Imports and Depends (required)
  required_deps <- rbind(imports, depends)
  
  # --- Step 1: Ensure core package managers are installed ---
  cat("\n--- Installing Core Package Managers ---\n")
  
  core_packages <- c("devtools", "BiocManager", "remotes")
  for (pkg in core_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      cat("Installing", pkg, "...\n")
      utils::install.packages(pkg, repos = "https://cran.rstudio.com/", quiet = TRUE)
    }
  }
  
  # Set up Bioconductor repositories
  if (requireNamespace("BiocManager", quietly = TRUE)) {
    bioc_repos <- BiocManager::repositories()
    options(repos = bioc_repos)
    cat("Bioconductor repositories configured.\n")
  }
  
  # --- Step 2: Identify Bioconductor packages ---
  # Known Bioconductor packages from typical omics workflows
  bioc_packages <- c(
    "UniProt.ws", "mixOmics", "limma", "qvalue", "clusterProfiler", 
    "GO.db", "EDASeq", "RUVSeq", "basilisk", "Biobase", "BiocGenerics",
    "S4Vectors", "IRanges", "GenomicRanges", "SummarizedExperiment",
    "AnnotationDbi", "org.Hs.eg.db", "DOSE", "enrichplot", "pathview"
  )
  
  # --- Step 3: Check and install required dependencies ---
  cat("\n--- Checking Required Dependencies ---\n")
  
  packages_upgraded <- FALSE
  packages_installed <- c()
  packages_failed <- c()
  
  for (i in seq_len(nrow(required_deps))) {
    pkg_name <- required_deps$package[i]
    pkg_version <- required_deps$version[i]
    
    check <- needs_install(pkg_name, pkg_version)
    
    if (check$needed) {
      if (check$reason == "not_installed") {
        cat("  [MISSING]", pkg_name, "\n")
      } else {
        cat("  [UPGRADE]", pkg_name, "- have", check$installed, "need >=", check$required, "\n")
      }
      
      # Determine source and install
      tryCatch({
        if (pkg_name %in% bioc_packages) {
          cat("    -> Installing from Bioconductor...\n")
          BiocManager::install(pkg_name, update = FALSE, ask = FALSE, quiet = TRUE)
        } else {
          cat("    -> Installing from CRAN...\n")
          utils::install.packages(pkg_name, quiet = TRUE)
        }
        
        # Verify installation
        if (requireNamespace(pkg_name, quietly = TRUE)) {
          packages_installed <- c(packages_installed, pkg_name)
          packages_upgraded <- TRUE
          cat("    -> SUCCESS\n")
        } else {
          packages_failed <- c(packages_failed, pkg_name)
          cat("    -> FAILED (package not loadable)\n")
        }
      }, error = function(e) {
        packages_failed <<- c(packages_failed, pkg_name)
        cat("    -> FAILED:", e$message, "\n")
      })
    }
  }
  
  # --- Step 4: Handle Remotes (GitHub packages) ---
  if (!is.na(remotes_str) && remotes_str != "") {
    cat("\n--- Installing GitHub Packages (Remotes) ---\n")
    
    # Parse remotes: format is "user/repo" or "cran/package"
    remotes <- strsplit(remotes_str, ",")[[1]]
    remotes <- trimws(remotes)
    remotes <- remotes[remotes != ""]
    
    for (remote in remotes) {
      # Extract package name from repo path
      pkg_name <- basename(remote)
      
      cat("  Checking", pkg_name, "(", remote, ")...\n")
      
      if (!requireNamespace(pkg_name, quietly = TRUE)) {
        cat("    -> Installing from GitHub...\n")
        tryCatch({
          remotes::install_github(remote, quiet = TRUE, upgrade = "never")
          if (requireNamespace(pkg_name, quietly = TRUE)) {
            packages_installed <- c(packages_installed, pkg_name)
            packages_upgraded <- TRUE
            cat("    -> SUCCESS\n")
          } else {
            packages_failed <- c(packages_failed, pkg_name)
            cat("    -> FAILED (package not loadable)\n")
          }
        }, error = function(e) {
          packages_failed <<- c(packages_failed, pkg_name)
          cat("    -> FAILED:", e$message, "\n")
        })
      } else {
        cat("    -> Already installed\n")
      }
    }
  }
  
  # --- Step 5: Install key Suggests (optional but helpful) ---
  cat("\n--- Checking Suggested Packages ---\n")
  
  # Only install Suggests that are commonly needed
  key_suggests <- c("shiny", "ggplot2", "plotly", "testthat")
  
  for (i in seq_len(nrow(suggests))) {
    pkg_name <- suggests$package[i]
    
    # Only install key suggests
    if (!(pkg_name %in% key_suggests)) next
    
    if (!requireNamespace(pkg_name, quietly = TRUE)) {
      cat("  [MISSING]", pkg_name, "(suggested)\n")
      tryCatch({
        if (pkg_name %in% bioc_packages) {
          BiocManager::install(pkg_name, update = FALSE, ask = FALSE, quiet = TRUE)
        } else {
          utils::install.packages(pkg_name, quiet = TRUE)
        }
        if (requireNamespace(pkg_name, quietly = TRUE)) {
          packages_installed <- c(packages_installed, pkg_name)
          packages_upgraded <- TRUE
          cat("    -> SUCCESS\n")
        }
      }, error = function(e) {
        cat("    -> FAILED (optional):", e$message, "\n")
      })
    }
  }
  
  # --- Summary ---
  cat("\n========================================\n")
  cat("Bootstrap Summary\n")
  cat("========================================\n")
  
  if (length(packages_installed) > 0) {
    cat("Packages installed/upgraded:", length(packages_installed), "\n")
    for (pkg in packages_installed) {
      cat("  -", pkg, "\n")
    }
  }
  
  if (length(packages_failed) > 0) {
    cat("\nPackages that failed to install:", length(packages_failed), "\n")
    for (pkg in packages_failed) {
      cat("  -", pkg, "\n")
    }
    cat("\nWARNING: Some packages failed. The app may not work correctly.\n")
  }
  
  # --- Determine exit code ---
  if (packages_upgraded) {
    cat("\n*** Packages were installed/upgraded. R session restart recommended. ***\n")
    cat("Exit code: 42 (restart needed)\n")
    quit(status = 42, save = "no")
  } else {
    cat("\nAll dependencies are satisfied.\n")
    cat("Exit code: 0 (ready to launch)\n")
    quit(status = 0, save = "no")
  }
}

# Run with error handling
tryCatch({
  main()
}, error = function(e) {
  cat("\n========================================\n")
  cat("BOOTSTRAP FAILED\n")
  cat("========================================\n")
  cat("Error:", e$message, "\n")
  quit(status = 1, save = "no")
})

