# ============================================================================
# STANDARDIZED ERROR HANDLING FUNCTIONS
# ============================================================================
# Consistent error handling across all pipeline scripts
#
# Usage:
#   source("scripts/utils/error_handling.R")
#   safe_execute({
#     # Your code here
#   })
# ============================================================================

# ============================================================================
# SAFE EXECUTION WRAPPER
# ============================================================================

#' Safely execute code with standardized error handling
#' 
#' @param expr Expression to execute
#' @param context Context description (e.g., "Loading data", "Generating figure")
#' @param on_error Function to call on error (default: logs and quits)
#' @return Result of expression execution, or NULL on error
safe_execute <- function(expr, context = "Pipeline step", on_error = NULL) {
  tryCatch({
    expr
  }, error = function(e) {
    error_msg <- paste0("❌ ERROR in ", context, ": ", e$message)
    
    # Log error
    if (exists("log_error")) {
      log_error(error_msg)
      log_error(paste("   Stack trace:", deparse(sys.calls())))
    } else {
      cat(error_msg, "\n", file = stderr())
    }
    
    # Call custom error handler if provided
    if (!is.null(on_error)) {
      on_error(e)
    } else {
      # Default: log and quit with error code
      quit(status = 1)
    }
    
    return(NULL)
  }, warning = function(w) {
    warning_msg <- paste0("⚠️  WARNING in ", context, ": ", w$message)
    
    # Log warning
    if (exists("log_warning")) {
      log_warning(warning_msg)
    } else {
      cat(warning_msg, "\n", file = stderr())
    }
    
    # Continue execution (warnings don't stop)
    invokeRestart("muffleWarning")
  })
}

# ============================================================================
# FILE OPERATIONS WITH ERROR HANDLING
# ============================================================================

#' Safely read a file with error handling
#' 
#' @param file_path Path to file
#' @param reader Function to read file (default: read_csv)
#' @param context Context for error messages
#' @return Data frame or NULL on error
safe_read_file <- function(file_path, reader = readr::read_csv, context = NULL) {
  if (is.null(context)) {
    context <- paste("Reading file:", basename(file_path))
  }
  
  safe_execute({
    if (!file.exists(file_path)) {
      stop(paste("File not found:", file_path))
    }
    
    data <- reader(file_path)
    
    if (exists("log_info")) {
      log_info(paste("✅ Successfully read:", basename(file_path)))
    }
    
    return(data)
  }, context = context)
}

#' Safely write a file with error handling
#' 
#' @param data Data to write
#' @param file_path Path to output file
#' @param writer Function to write file (default: write_csv)
#' @param context Context for error messages
#' @return TRUE on success, FALSE on error
safe_write_file <- function(data, file_path, writer = readr::write_csv, context = NULL) {
  if (is.null(context)) {
    context <- paste("Writing file:", basename(file_path))
  }
  
  result <- safe_execute({
    # Create directory if it doesn't exist
    output_dir <- dirname(file_path)
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    }
    
    writer(data, file_path)
    
    if (exists("log_info")) {
      log_info(paste("✅ Successfully wrote:", basename(file_path)))
    }
    
    return(TRUE)
  }, context = context)
  
  return(!is.null(result))
}

# ============================================================================
# VALIDATION WITH ERROR HANDLING
# ============================================================================

#' Validate condition and stop with clear error if false
#' 
#' @param condition Logical condition to check
#' @param error_msg Error message if condition is FALSE
#' @param context Context for error messages
validate_or_stop <- function(condition, error_msg, context = "Validation") {
  if (!condition) {
    full_error <- paste0("❌ ", context, ": ", error_msg)
    
    if (exists("log_error")) {
      log_error(full_error)
    } else {
      cat(full_error, "\n", file = stderr())
    }
    
    stop(full_error)
  }
}

#' Validate file exists and stop with clear error if not
#' 
#' @param file_path Path to file
#' @param context Context for error messages
validate_file_exists <- function(file_path, context = NULL) {
  if (is.null(context)) {
    context <- paste("File validation:", basename(file_path))
  }
  
  validate_or_stop(
    file.exists(file_path),
    paste("Required file not found:", file_path),
    context
  )
}

#' Validate directory exists and stop with clear error if not
#' 
#' @param dir_path Path to directory
#' @param context Context for error messages
validate_dir_exists <- function(dir_path, context = NULL) {
  if (is.null(context)) {
    context <- paste("Directory validation:", basename(dir_path))
  }
  
  validate_or_stop(
    dir.exists(dir_path),
    paste("Required directory not found:", dir_path),
    context
  )
}

# ============================================================================
# GRACEFUL DEGRADATION
# ============================================================================

#' Try to execute code with graceful degradation
#' 
#' If code fails, returns default value instead of stopping
#' 
#' @param expr Expression to execute
#' @param default Default value to return on error
#' @param context Context for warning messages
#' @return Result of expression or default value
try_with_default <- function(expr, default = NULL, context = NULL) {
  tryCatch({
    expr
  }, error = function(e) {
    if (!is.null(context)) {
      warning_msg <- paste0("⚠️  ", context, " failed, using default: ", e$message)
      
      if (exists("log_warning")) {
        log_warning(warning_msg)
      } else {
        cat(warning_msg, "\n", file = stderr())
      }
    }
    
    return(default)
  })
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

# Make functions available when sourced
if (!exists("pipeline_error_handling_loaded")) {
  pipeline_error_handling_loaded <- TRUE
  
  # Export to global environment
  assign("safe_execute", safe_execute, envir = .GlobalEnv)
  assign("safe_read_file", safe_read_file, envir = .GlobalEnv)
  assign("safe_write_file", safe_write_file, envir = .GlobalEnv)
  assign("validate_or_stop", validate_or_stop, envir = .GlobalEnv)
  assign("validate_file_exists", validate_file_exists, envir = .GlobalEnv)
  assign("validate_dir_exists", validate_dir_exists, envir = .GlobalEnv)
  assign("try_with_default", try_with_default, envir = .GlobalEnv)
}

