# ============================================================================
# STANDARDIZED LOGGING AND ERROR HANDLING
# ============================================================================
# Purpose: Provide consistent logging and error handling across pipeline
# Usage: Source this file in scripts to use standardized logging
# ============================================================================

# ============================================================================
# CONFIGURATION
# ============================================================================

# Log levels
LOG_LEVELS <- list(
  DEBUG = 0,
  INFO = 1,
  WARNING = 2,
  ERROR = 3,
  FATAL = 4
)

# Current log level (can be set via environment variable)
CURRENT_LOG_LEVEL <- as.integer(Sys.getenv("PIPELINE_LOG_LEVEL", unset = "1"))

# Log file path (set by calling function)
GLOBAL_LOG_FILE <- NULL

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Get current timestamp
get_timestamp <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%S")
}

#' Format log message with context
format_log_message <- function(level, message, context = NULL) {
  timestamp <- get_timestamp()
  context_str <- if (!is.null(context)) paste0("[", context, "] ") else ""
  paste0(timestamp, " [", level, "] ", context_str, message)
}

#' Write to log file if available
write_to_log_file <- function(formatted_message) {
  if (!is.null(GLOBAL_LOG_FILE)) {
    tryCatch({
      dir.create(dirname(GLOBAL_LOG_FILE), recursive = TRUE, showWarnings = FALSE)
      cat(formatted_message, "\n", file = GLOBAL_LOG_FILE, append = TRUE)
    }, error = function(e) {
      # Silently fail if can't write to log file
    })
  }
}

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

#' Log an informational message
#' 
#' @param message Message to log
#' @param context Optional context (e.g., "Panel B", "Step 1")
#' @param verbose If TRUE, prints to console; if FALSE, only logs to file
log_info <- function(message, context = NULL, verbose = TRUE) {
  if (CURRENT_LOG_LEVEL <= LOG_LEVELS$INFO) {
    formatted <- format_log_message("INFO", message, context)
    
    if (verbose) {
      cat(formatted, "\n")
    }
    
    write_to_log_file(formatted)
  }
}

#' Log a warning message
#' 
#' @param message Warning message
#' @param context Optional context
#' @param verbose If TRUE, prints to console
log_warning <- function(message, context = NULL, verbose = TRUE) {
  if (CURRENT_LOG_LEVEL <= LOG_LEVELS$WARNING) {
    formatted <- format_log_message("WARNING", message, context)
    
    if (verbose) {
      cat("⚠️  ", formatted, "\n", sep = "")
    }
    
    write_to_log_file(formatted)
  }
}

#' Log an error message (non-fatal)
#' 
#' @param message Error message
#' @param context Optional context
#' @param verbose If TRUE, prints to console
log_error <- function(message, context = NULL, verbose = TRUE) {
  if (CURRENT_LOG_LEVEL <= LOG_LEVELS$ERROR) {
    formatted <- format_log_message("ERROR", message, context)
    
    if (verbose) {
      cat("❌ ", formatted, "\n", sep = "")
    }
    
    write_to_log_file(formatted)
  }
}

#' Log a debug message (only if log level is DEBUG)
#' 
#' @param message Debug message
#' @param context Optional context
log_debug <- function(message, context = NULL) {
  if (CURRENT_LOG_LEVEL <= LOG_LEVELS$DEBUG) {
    formatted <- format_log_message("DEBUG", message, context)
    cat("🔍 ", formatted, "\n", sep = "")
    write_to_log_file(formatted)
  }
}

#' Log a success message
#' 
#' @param message Success message
#' @param context Optional context
log_success <- function(message, context = NULL) {
  formatted <- format_log_message("SUCCESS", message, context)
  cat("✅ ", formatted, "\n", sep = "")
  write_to_log_file(formatted)
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

#' Handle errors with standardized logging and cleanup
#' 
#' @param error Error object or error message
#' @param context Context where error occurred (e.g., "Panel B", "Step 1")
#' @param exit_code Exit code for fatal errors (NULL = don't exit)
#' @param log_file Optional log file path (auto-detected if NULL)
#' @param cleanup Function to run on cleanup (optional)
handle_error <- function(error, 
                        context = NULL, 
                        exit_code = 1,
                        log_file = NULL,
                        cleanup = NULL) {
  
  # Get error message
  error_message <- if (inherits(error, "condition")) {
    error$message
  } else {
    as.character(error)
  }
  
  # Format error details
  timestamp <- get_timestamp()
  context_str <- if (!is.null(context)) paste0("[", context, "] ") else ""
  
  # Log error
  formatted_error <- format_log_message("ERROR", error_message, context_str)
  
  # Print to console
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("❌ ERROR OCCURRED\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  cat("Context:", if (!is.null(context)) context else "Unknown", "\n")
  cat("Time:", timestamp, "\n")
  cat("Error:", error_message, "\n\n")
  
  # Try to get stack trace if available
  if (inherits(error, "condition")) {
    tryCatch({
      trace <- sys.calls()
      if (length(trace) > 1) {
        cat("Call stack:\n")
        for (i in min(3, length(trace)):length(trace)) {
          cat("  ", length(trace) - i + 1, ": ", deparse(trace[[i]]), "\n", sep = "")
        }
      }
    }, error = function(e) {
      # Ignore errors in traceback
    })
  }
  
  cat("\n")
  
  # Write to log file
  log_path <- if (!is.null(log_file)) log_file else GLOBAL_LOG_FILE
  if (!is.null(log_path)) {
    tryCatch({
      dir.create(dirname(log_path), recursive = TRUE, showWarnings = FALSE)
      
      # Write detailed error log
      error_log <- paste0(
        "═══════════════════════════════════════════════════════════════════\n",
        "ERROR LOG\n",
        "═══════════════════════════════════════════════════════════════════\n",
        "Timestamp: ", timestamp, "\n",
        "Context: ", if (!is.null(context)) context else "Unknown", "\n",
        "Error Message: ", error_message, "\n",
        "═══════════════════════════════════════════════════════════════════\n\n"
      )
      
      cat(error_log, file = log_path, append = TRUE)
      
      # Write stack trace if available
      if (inherits(error, "condition")) {
        tryCatch({
          trace <- sys.calls()
          if (length(trace) > 1) {
            cat("Call Stack:\n", file = log_path, append = TRUE)
            for (i in 1:min(10, length(trace))) {
              cat("  ", i, ": ", deparse(trace[[i]]), "\n", sep = "", file = log_path, append = TRUE)
            }
            cat("\n", file = log_path, append = TRUE)
          }
        }, error = function(e) {
          # Ignore
        })
      }
    }, error = function(e) {
      cat("⚠️  Warning: Could not write to error log file\n")
    })
  }
  
  # Run cleanup if provided
  if (!is.null(cleanup) && is.function(cleanup)) {
    tryCatch({
      cleanup()
      log_info("Cleanup completed", context = context, verbose = FALSE)
    }, error = function(e) {
      log_warning("Cleanup failed", context = context)
    })
  }
  
  # Exit if exit_code provided
  if (!is.null(exit_code)) {
    quit(status = exit_code)
  }
  
  # Return formatted error for further handling
  invisible(formatted_error)
}

# ============================================================================
# SNAKEMAKE INTEGRATION
# ============================================================================

#' Initialize logging for Snakemake job
#' 
#' @param log_file_path Path to log file (usually from snakemake@log)
#' @param context Context name (e.g., "Panel B", "Step 1")
initialize_logging <- function(log_file_path = NULL, context = NULL) {
  # Set global log file
  if (!is.null(log_file_path)) {
    GLOBAL_LOG_FILE <<- log_file_path
    
    # Create log directory if needed
    dir.create(dirname(log_file_path), recursive = TRUE, showWarnings = FALSE)
    
    # Write header
    header <- paste0(
      "═══════════════════════════════════════════════════════════════════\n",
      "PIPELINE EXECUTION LOG\n",
      if (!is.null(context)) paste0("Context: ", context, "\n") else "",
      "Started: ", get_timestamp(), "\n",
      "═══════════════════════════════════════════════════════════════════\n\n"
    )
    
    tryCatch({
      cat(header, file = log_file_path)
    }, error = function(e) {
      cat("⚠️  Warning: Could not write to log file:", log_file_path, "\n")
    })
  }
  
  log_info(paste("Logging initialized", if (!is.null(context)) paste("for", context) else ""), 
           context = context)
}

# ============================================================================
# SECTION SEPARATORS (for better readability)
# ============================================================================

#' Print a section separator for better log readability
log_section <- function(title, context = NULL) {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  if (!is.null(context)) {
    cat("  ", context, ": ", title, "\n", sep = "")
  } else {
    cat("  ", title, "\n", sep = "")
  }
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  if (!is.null(GLOBAL_LOG_FILE)) {
    formatted <- paste0("\n═══════════════════════════════════════════════════════════════════\n",
                       if (!is.null(context)) paste0(context, ": ", title) else title,
                       "\n═══════════════════════════════════════════════════════════════════\n\n")
    write_to_log_file(formatted)
  }
}

#' Print a subsection separator
log_subsection <- function(title, context = NULL) {
  cat("\n")
  cat("───────────────────────────────────────────────────────────────────\n")
  if (!is.null(context)) {
    cat("  ", context, ": ", title, "\n", sep = "")
  } else {
    cat("  ", title, "\n", sep = "")
  }
  cat("───────────────────────────────────────────────────────────────────\n\n")
  
  if (!is.null(GLOBAL_LOG_FILE)) {
    formatted <- paste0("\n───────────────────────────────────────────────────────────────────\n",
                       if (!is.null(context)) paste0(context, ": ", title) else title,
                       "\n───────────────────────────────────────────────────────────────────\n\n")
    write_to_log_file(formatted)
  }
}

# ============================================================================
# UTILITY: SAFE EXECUTION WRAPPER
# ============================================================================

#' Execute code with error handling
#' 
#' @param expr Expression to execute
#' @param context Context for error messages
#' @param on_error Function to call on error (optional)
#' @param finally Function to call in finally block (optional)
safe_execute <- function(expr, context = NULL, on_error = NULL, finally = NULL) {
  result <- NULL
  
  tryCatch({
    result <- expr
  }, error = function(e) {
    handle_error(e, context = context, exit_code = NULL)
    
    if (!is.null(on_error) && is.function(on_error)) {
      on_error(e)
    }
    
    result <<- NULL
  }, finally = {
    if (!is.null(finally) && is.function(finally)) {
      finally()
    }
  })
  
  return(result)
}


# ============================================================================
# Purpose: Provide consistent logging and error handling across pipeline
# Usage: Source this file in scripts to use standardized logging
# ============================================================================

# ============================================================================
# CONFIGURATION
# ============================================================================

# Log levels
LOG_LEVELS <- list(
  DEBUG = 0,
  INFO = 1,
  WARNING = 2,
  ERROR = 3,
  FATAL = 4
)

# Current log level (can be set via environment variable)
CURRENT_LOG_LEVEL <- as.integer(Sys.getenv("PIPELINE_LOG_LEVEL", unset = "1"))

# Log file path (set by calling function)
GLOBAL_LOG_FILE <- NULL

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Get current timestamp
get_timestamp <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%S")
}

#' Format log message with context
format_log_message <- function(level, message, context = NULL) {
  timestamp <- get_timestamp()
  context_str <- if (!is.null(context)) paste0("[", context, "] ") else ""
  paste0(timestamp, " [", level, "] ", context_str, message)
}

#' Write to log file if available
write_to_log_file <- function(formatted_message) {
  if (!is.null(GLOBAL_LOG_FILE)) {
    tryCatch({
      dir.create(dirname(GLOBAL_LOG_FILE), recursive = TRUE, showWarnings = FALSE)
      cat(formatted_message, "\n", file = GLOBAL_LOG_FILE, append = TRUE)
    }, error = function(e) {
      # Silently fail if can't write to log file
    })
  }
}

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

#' Log an informational message
#' 
#' @param message Message to log
#' @param context Optional context (e.g., "Panel B", "Step 1")
#' @param verbose If TRUE, prints to console; if FALSE, only logs to file
log_info <- function(message, context = NULL, verbose = TRUE) {
  if (CURRENT_LOG_LEVEL <= LOG_LEVELS$INFO) {
    formatted <- format_log_message("INFO", message, context)
    
    if (verbose) {
      cat(formatted, "\n")
    }
    
    write_to_log_file(formatted)
  }
}

#' Log a warning message
#' 
#' @param message Warning message
#' @param context Optional context
#' @param verbose If TRUE, prints to console
log_warning <- function(message, context = NULL, verbose = TRUE) {
  if (CURRENT_LOG_LEVEL <= LOG_LEVELS$WARNING) {
    formatted <- format_log_message("WARNING", message, context)
    
    if (verbose) {
      cat("⚠️  ", formatted, "\n", sep = "")
    }
    
    write_to_log_file(formatted)
  }
}

#' Log an error message (non-fatal)
#' 
#' @param message Error message
#' @param context Optional context
#' @param verbose If TRUE, prints to console
log_error <- function(message, context = NULL, verbose = TRUE) {
  if (CURRENT_LOG_LEVEL <= LOG_LEVELS$ERROR) {
    formatted <- format_log_message("ERROR", message, context)
    
    if (verbose) {
      cat("❌ ", formatted, "\n", sep = "")
    }
    
    write_to_log_file(formatted)
  }
}

#' Log a debug message (only if log level is DEBUG)
#' 
#' @param message Debug message
#' @param context Optional context
log_debug <- function(message, context = NULL) {
  if (CURRENT_LOG_LEVEL <= LOG_LEVELS$DEBUG) {
    formatted <- format_log_message("DEBUG", message, context)
    cat("🔍 ", formatted, "\n", sep = "")
    write_to_log_file(formatted)
  }
}

#' Log a success message
#' 
#' @param message Success message
#' @param context Optional context
log_success <- function(message, context = NULL) {
  formatted <- format_log_message("SUCCESS", message, context)
  cat("✅ ", formatted, "\n", sep = "")
  write_to_log_file(formatted)
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

#' Handle errors with standardized logging and cleanup
#' 
#' @param error Error object or error message
#' @param context Context where error occurred (e.g., "Panel B", "Step 1")
#' @param exit_code Exit code for fatal errors (NULL = don't exit)
#' @param log_file Optional log file path (auto-detected if NULL)
#' @param cleanup Function to run on cleanup (optional)
handle_error <- function(error, 
                        context = NULL, 
                        exit_code = 1,
                        log_file = NULL,
                        cleanup = NULL) {
  
  # Get error message
  error_message <- if (inherits(error, "condition")) {
    error$message
  } else {
    as.character(error)
  }
  
  # Format error details
  timestamp <- get_timestamp()
  context_str <- if (!is.null(context)) paste0("[", context, "] ") else ""
  
  # Log error
  formatted_error <- format_log_message("ERROR", error_message, context_str)
  
  # Print to console
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("❌ ERROR OCCURRED\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  cat("Context:", if (!is.null(context)) context else "Unknown", "\n")
  cat("Time:", timestamp, "\n")
  cat("Error:", error_message, "\n\n")
  
  # Try to get stack trace if available
  if (inherits(error, "condition")) {
    tryCatch({
      trace <- sys.calls()
      if (length(trace) > 1) {
        cat("Call stack:\n")
        for (i in min(3, length(trace)):length(trace)) {
          cat("  ", length(trace) - i + 1, ": ", deparse(trace[[i]]), "\n", sep = "")
        }
      }
    }, error = function(e) {
      # Ignore errors in traceback
    })
  }
  
  cat("\n")
  
  # Write to log file
  log_path <- if (!is.null(log_file)) log_file else GLOBAL_LOG_FILE
  if (!is.null(log_path)) {
    tryCatch({
      dir.create(dirname(log_path), recursive = TRUE, showWarnings = FALSE)
      
      # Write detailed error log
      error_log <- paste0(
        "═══════════════════════════════════════════════════════════════════\n",
        "ERROR LOG\n",
        "═══════════════════════════════════════════════════════════════════\n",
        "Timestamp: ", timestamp, "\n",
        "Context: ", if (!is.null(context)) context else "Unknown", "\n",
        "Error Message: ", error_message, "\n",
        "═══════════════════════════════════════════════════════════════════\n\n"
      )
      
      cat(error_log, file = log_path, append = TRUE)
      
      # Write stack trace if available
      if (inherits(error, "condition")) {
        tryCatch({
          trace <- sys.calls()
          if (length(trace) > 1) {
            cat("Call Stack:\n", file = log_path, append = TRUE)
            for (i in 1:min(10, length(trace))) {
              cat("  ", i, ": ", deparse(trace[[i]]), "\n", sep = "", file = log_path, append = TRUE)
            }
            cat("\n", file = log_path, append = TRUE)
          }
        }, error = function(e) {
          # Ignore
        })
      }
    }, error = function(e) {
      cat("⚠️  Warning: Could not write to error log file\n")
    })
  }
  
  # Run cleanup if provided
  if (!is.null(cleanup) && is.function(cleanup)) {
    tryCatch({
      cleanup()
      log_info("Cleanup completed", context = context, verbose = FALSE)
    }, error = function(e) {
      log_warning("Cleanup failed", context = context)
    })
  }
  
  # Exit if exit_code provided
  if (!is.null(exit_code)) {
    quit(status = exit_code)
  }
  
  # Return formatted error for further handling
  invisible(formatted_error)
}

# ============================================================================
# SNAKEMAKE INTEGRATION
# ============================================================================

#' Initialize logging for Snakemake job
#' 
#' @param log_file_path Path to log file (usually from snakemake@log)
#' @param context Context name (e.g., "Panel B", "Step 1")
initialize_logging <- function(log_file_path = NULL, context = NULL) {
  # Set global log file
  if (!is.null(log_file_path)) {
    GLOBAL_LOG_FILE <<- log_file_path
    
    # Create log directory if needed
    dir.create(dirname(log_file_path), recursive = TRUE, showWarnings = FALSE)
    
    # Write header
    header <- paste0(
      "═══════════════════════════════════════════════════════════════════\n",
      "PIPELINE EXECUTION LOG\n",
      if (!is.null(context)) paste0("Context: ", context, "\n") else "",
      "Started: ", get_timestamp(), "\n",
      "═══════════════════════════════════════════════════════════════════\n\n"
    )
    
    tryCatch({
      cat(header, file = log_file_path)
    }, error = function(e) {
      cat("⚠️  Warning: Could not write to log file:", log_file_path, "\n")
    })
  }
  
  log_info(paste("Logging initialized", if (!is.null(context)) paste("for", context) else ""), 
           context = context)
}

# ============================================================================
# SECTION SEPARATORS (for better readability)
# ============================================================================

#' Print a section separator for better log readability
log_section <- function(title, context = NULL) {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  if (!is.null(context)) {
    cat("  ", context, ": ", title, "\n", sep = "")
  } else {
    cat("  ", title, "\n", sep = "")
  }
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  if (!is.null(GLOBAL_LOG_FILE)) {
    formatted <- paste0("\n═══════════════════════════════════════════════════════════════════\n",
                       if (!is.null(context)) paste0(context, ": ", title) else title,
                       "\n═══════════════════════════════════════════════════════════════════\n\n")
    write_to_log_file(formatted)
  }
}

#' Print a subsection separator
log_subsection <- function(title, context = NULL) {
  cat("\n")
  cat("───────────────────────────────────────────────────────────────────\n")
  if (!is.null(context)) {
    cat("  ", context, ": ", title, "\n", sep = "")
  } else {
    cat("  ", title, "\n", sep = "")
  }
  cat("───────────────────────────────────────────────────────────────────\n\n")
  
  if (!is.null(GLOBAL_LOG_FILE)) {
    formatted <- paste0("\n───────────────────────────────────────────────────────────────────\n",
                       if (!is.null(context)) paste0(context, ": ", title) else title,
                       "\n───────────────────────────────────────────────────────────────────\n\n")
    write_to_log_file(formatted)
  }
}

# ============================================================================
# UTILITY: SAFE EXECUTION WRAPPER
# ============================================================================

#' Execute code with error handling
#' 
#' @param expr Expression to execute
#' @param context Context for error messages
#' @param on_error Function to call on error (optional)
#' @param finally Function to call in finally block (optional)
safe_execute <- function(expr, context = NULL, on_error = NULL, finally = NULL) {
  result <- NULL
  
  tryCatch({
    result <- expr
  }, error = function(e) {
    handle_error(e, context = context, exit_code = NULL)
    
    if (!is.null(on_error) && is.function(on_error)) {
      on_error(e)
    }
    
    result <<- NULL
  }, finally = {
    if (!is.null(finally) && is.function(finally)) {
      finally()
    }
  })
  
  return(result)
}


# ============================================================================
# Purpose: Provide consistent logging and error handling across pipeline
# Usage: Source this file in scripts to use standardized logging
# ============================================================================

# ============================================================================
# CONFIGURATION
# ============================================================================

# Log levels
LOG_LEVELS <- list(
  DEBUG = 0,
  INFO = 1,
  WARNING = 2,
  ERROR = 3,
  FATAL = 4
)

# Current log level (can be set via environment variable)
CURRENT_LOG_LEVEL <- as.integer(Sys.getenv("PIPELINE_LOG_LEVEL", unset = "1"))

# Log file path (set by calling function)
GLOBAL_LOG_FILE <- NULL

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Get current timestamp
get_timestamp <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%S")
}

#' Format log message with context
format_log_message <- function(level, message, context = NULL) {
  timestamp <- get_timestamp()
  context_str <- if (!is.null(context)) paste0("[", context, "] ") else ""
  paste0(timestamp, " [", level, "] ", context_str, message)
}

#' Write to log file if available
write_to_log_file <- function(formatted_message) {
  if (!is.null(GLOBAL_LOG_FILE)) {
    tryCatch({
      dir.create(dirname(GLOBAL_LOG_FILE), recursive = TRUE, showWarnings = FALSE)
      cat(formatted_message, "\n", file = GLOBAL_LOG_FILE, append = TRUE)
    }, error = function(e) {
      # Silently fail if can't write to log file
    })
  }
}

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

#' Log an informational message
#' 
#' @param message Message to log
#' @param context Optional context (e.g., "Panel B", "Step 1")
#' @param verbose If TRUE, prints to console; if FALSE, only logs to file
log_info <- function(message, context = NULL, verbose = TRUE) {
  if (CURRENT_LOG_LEVEL <= LOG_LEVELS$INFO) {
    formatted <- format_log_message("INFO", message, context)
    
    if (verbose) {
      cat(formatted, "\n")
    }
    
    write_to_log_file(formatted)
  }
}

#' Log a warning message
#' 
#' @param message Warning message
#' @param context Optional context
#' @param verbose If TRUE, prints to console
log_warning <- function(message, context = NULL, verbose = TRUE) {
  if (CURRENT_LOG_LEVEL <= LOG_LEVELS$WARNING) {
    formatted <- format_log_message("WARNING", message, context)
    
    if (verbose) {
      cat("⚠️  ", formatted, "\n", sep = "")
    }
    
    write_to_log_file(formatted)
  }
}

#' Log an error message (non-fatal)
#' 
#' @param message Error message
#' @param context Optional context
#' @param verbose If TRUE, prints to console
log_error <- function(message, context = NULL, verbose = TRUE) {
  if (CURRENT_LOG_LEVEL <= LOG_LEVELS$ERROR) {
    formatted <- format_log_message("ERROR", message, context)
    
    if (verbose) {
      cat("❌ ", formatted, "\n", sep = "")
    }
    
    write_to_log_file(formatted)
  }
}

#' Log a debug message (only if log level is DEBUG)
#' 
#' @param message Debug message
#' @param context Optional context
log_debug <- function(message, context = NULL) {
  if (CURRENT_LOG_LEVEL <= LOG_LEVELS$DEBUG) {
    formatted <- format_log_message("DEBUG", message, context)
    cat("🔍 ", formatted, "\n", sep = "")
    write_to_log_file(formatted)
  }
}

#' Log a success message
#' 
#' @param message Success message
#' @param context Optional context
log_success <- function(message, context = NULL) {
  formatted <- format_log_message("SUCCESS", message, context)
  cat("✅ ", formatted, "\n", sep = "")
  write_to_log_file(formatted)
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

#' Handle errors with standardized logging and cleanup
#' 
#' @param error Error object or error message
#' @param context Context where error occurred (e.g., "Panel B", "Step 1")
#' @param exit_code Exit code for fatal errors (NULL = don't exit)
#' @param log_file Optional log file path (auto-detected if NULL)
#' @param cleanup Function to run on cleanup (optional)
handle_error <- function(error, 
                        context = NULL, 
                        exit_code = 1,
                        log_file = NULL,
                        cleanup = NULL) {
  
  # Get error message
  error_message <- if (inherits(error, "condition")) {
    error$message
  } else {
    as.character(error)
  }
  
  # Format error details
  timestamp <- get_timestamp()
  context_str <- if (!is.null(context)) paste0("[", context, "] ") else ""
  
  # Log error
  formatted_error <- format_log_message("ERROR", error_message, context_str)
  
  # Print to console
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("❌ ERROR OCCURRED\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  cat("Context:", if (!is.null(context)) context else "Unknown", "\n")
  cat("Time:", timestamp, "\n")
  cat("Error:", error_message, "\n\n")
  
  # Try to get stack trace if available
  if (inherits(error, "condition")) {
    tryCatch({
      trace <- sys.calls()
      if (length(trace) > 1) {
        cat("Call stack:\n")
        for (i in min(3, length(trace)):length(trace)) {
          cat("  ", length(trace) - i + 1, ": ", deparse(trace[[i]]), "\n", sep = "")
        }
      }
    }, error = function(e) {
      # Ignore errors in traceback
    })
  }
  
  cat("\n")
  
  # Write to log file
  log_path <- if (!is.null(log_file)) log_file else GLOBAL_LOG_FILE
  if (!is.null(log_path)) {
    tryCatch({
      dir.create(dirname(log_path), recursive = TRUE, showWarnings = FALSE)
      
      # Write detailed error log
      error_log <- paste0(
        "═══════════════════════════════════════════════════════════════════\n",
        "ERROR LOG\n",
        "═══════════════════════════════════════════════════════════════════\n",
        "Timestamp: ", timestamp, "\n",
        "Context: ", if (!is.null(context)) context else "Unknown", "\n",
        "Error Message: ", error_message, "\n",
        "═══════════════════════════════════════════════════════════════════\n\n"
      )
      
      cat(error_log, file = log_path, append = TRUE)
      
      # Write stack trace if available
      if (inherits(error, "condition")) {
        tryCatch({
          trace <- sys.calls()
          if (length(trace) > 1) {
            cat("Call Stack:\n", file = log_path, append = TRUE)
            for (i in 1:min(10, length(trace))) {
              cat("  ", i, ": ", deparse(trace[[i]]), "\n", sep = "", file = log_path, append = TRUE)
            }
            cat("\n", file = log_path, append = TRUE)
          }
        }, error = function(e) {
          # Ignore
        })
      }
    }, error = function(e) {
      cat("⚠️  Warning: Could not write to error log file\n")
    })
  }
  
  # Run cleanup if provided
  if (!is.null(cleanup) && is.function(cleanup)) {
    tryCatch({
      cleanup()
      log_info("Cleanup completed", context = context, verbose = FALSE)
    }, error = function(e) {
      log_warning("Cleanup failed", context = context)
    })
  }
  
  # Exit if exit_code provided
  if (!is.null(exit_code)) {
    quit(status = exit_code)
  }
  
  # Return formatted error for further handling
  invisible(formatted_error)
}

# ============================================================================
# SNAKEMAKE INTEGRATION
# ============================================================================

#' Initialize logging for Snakemake job
#' 
#' @param log_file_path Path to log file (usually from snakemake@log)
#' @param context Context name (e.g., "Panel B", "Step 1")
initialize_logging <- function(log_file_path = NULL, context = NULL) {
  # Set global log file
  if (!is.null(log_file_path)) {
    GLOBAL_LOG_FILE <<- log_file_path
    
    # Create log directory if needed
    dir.create(dirname(log_file_path), recursive = TRUE, showWarnings = FALSE)
    
    # Write header
    header <- paste0(
      "═══════════════════════════════════════════════════════════════════\n",
      "PIPELINE EXECUTION LOG\n",
      if (!is.null(context)) paste0("Context: ", context, "\n") else "",
      "Started: ", get_timestamp(), "\n",
      "═══════════════════════════════════════════════════════════════════\n\n"
    )
    
    tryCatch({
      cat(header, file = log_file_path)
    }, error = function(e) {
      cat("⚠️  Warning: Could not write to log file:", log_file_path, "\n")
    })
  }
  
  log_info(paste("Logging initialized", if (!is.null(context)) paste("for", context) else ""), 
           context = context)
}

# ============================================================================
# SECTION SEPARATORS (for better readability)
# ============================================================================

#' Print a section separator for better log readability
log_section <- function(title, context = NULL) {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  if (!is.null(context)) {
    cat("  ", context, ": ", title, "\n", sep = "")
  } else {
    cat("  ", title, "\n", sep = "")
  }
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  if (!is.null(GLOBAL_LOG_FILE)) {
    formatted <- paste0("\n═══════════════════════════════════════════════════════════════════\n",
                       if (!is.null(context)) paste0(context, ": ", title) else title,
                       "\n═══════════════════════════════════════════════════════════════════\n\n")
    write_to_log_file(formatted)
  }
}

#' Print a subsection separator
log_subsection <- function(title, context = NULL) {
  cat("\n")
  cat("───────────────────────────────────────────────────────────────────\n")
  if (!is.null(context)) {
    cat("  ", context, ": ", title, "\n", sep = "")
  } else {
    cat("  ", title, "\n", sep = "")
  }
  cat("───────────────────────────────────────────────────────────────────\n\n")
  
  if (!is.null(GLOBAL_LOG_FILE)) {
    formatted <- paste0("\n───────────────────────────────────────────────────────────────────\n",
                       if (!is.null(context)) paste0(context, ": ", title) else title,
                       "\n───────────────────────────────────────────────────────────────────\n\n")
    write_to_log_file(formatted)
  }
}

# ============================================================================
# UTILITY: SAFE EXECUTION WRAPPER
# ============================================================================

#' Execute code with error handling
#' 
#' @param expr Expression to execute
#' @param context Context for error messages
#' @param on_error Function to call on error (optional)
#' @param finally Function to call in finally block (optional)
safe_execute <- function(expr, context = NULL, on_error = NULL, finally = NULL) {
  result <- NULL
  
  tryCatch({
    result <- expr
  }, error = function(e) {
    handle_error(e, context = context, exit_code = NULL)
    
    if (!is.null(on_error) && is.function(on_error)) {
      on_error(e)
    }
    
    result <<- NULL
  }, finally = {
    if (!is.null(finally) && is.function(finally)) {
      finally()
    }
  })
  
  return(result)
}

