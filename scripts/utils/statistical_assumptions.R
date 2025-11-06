#!/usr/bin/env Rscript
# ============================================================================
# STATISTICAL ASSUMPTIONS VALIDATION
# ============================================================================
# Purpose: Validate statistical assumptions before performing parametric tests
# 
# Functions:
# - check_normality(): Test for normality (Shapiro-Wilk, KS test)
# - check_variance_homogeneity(): Test for equal variances (Levene's, Bartlett's)
# - diagnostic_plots(): Generate Q-Q plots and histograms
# - select_appropriate_test(): Automatically select parametric vs non-parametric
# 
# Usage: Source this file in analysis scripts or call functions directly
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
})

# ============================================================================
# CHECK NORMALITY
# ============================================================================

#' Check normality of data using multiple tests
#' 
#' @param data Vector of numeric values
#' @param group Optional grouping variable for comparison
#' @param alpha Significance threshold (default: 0.05)
#' @return List with test results and recommendations
check_normality <- function(data, group = NULL, alpha = 0.05) {
  
  # Remove NA values
  data <- data[!is.na(data)]
  
  if (length(data) < 3) {
    return(list(
      normal = FALSE,
      reason = "Insufficient data (n < 3)",
      shapiro_p = NA,
      ks_p = NA,
      recommendation = "non-parametric"
    ))
  }
  
  results <- list()
  
  # Shapiro-Wilk test (good for n < 50)
  if (length(data) >= 3 && length(data) <= 5000) {
    shapiro_test <- tryCatch({
      shapiro.test(data)
    }, error = function(e) NULL)
    
    if (!is.null(shapiro_test)) {
      results$shapiro_p <- shapiro_test$p.value
      results$shapiro_normal <- shapiro_test$p.value >= alpha
    } else {
      results$shapiro_p <- NA
      results$shapiro_normal <- NA
    }
  } else {
    results$shapiro_p <- NA
    results$shapiro_normal <- NA
    results$shapiro_reason <- "Sample size too large for Shapiro-Wilk (n > 5000)"
  }
  
  # Kolmogorov-Smirnov test (for larger samples)
  if (length(data) > 5000) {
    ks_test <- tryCatch({
      ks.test(data, "pnorm", mean(data, na.rm = TRUE), sd(data, na.rm = TRUE))
    }, error = function(e) NULL)
    
    if (!is.null(ks_test)) {
      results$ks_p <- ks_test$p.value
      results$ks_normal <- ks_test$p.value >= alpha
    } else {
      results$ks_p <- NA
      results$ks_normal <- NA
    }
  } else {
    results$ks_p <- NA
    results$ks_normal <- NA
  }
  
  # Visual inspection: skewness and kurtosis
  if (length(data) >= 3) {
    skewness <- mean((data - mean(data, na.rm = TRUE))^3) / (sd(data, na.rm = TRUE)^3)
    kurtosis <- mean((data - mean(data, na.rm = TRUE))^4) / (sd(data, na.rm = TRUE)^4) - 3
    
    # Normal distribution: skewness ≈ 0, kurtosis ≈ 0
    results$skewness <- skewness
    results$kurtosis <- kurtosis
    results$visual_normal <- abs(skewness) < 2 && abs(kurtosis) < 2
  } else {
    results$skewness <- NA
    results$kurtosis <- NA
    results$visual_normal <- NA
  }
  
  # Overall assessment
  if (!is.na(results$shapiro_normal)) {
    results$normal <- results$shapiro_normal && results$visual_normal
  } else if (!is.na(results$ks_normal)) {
    results$normal <- results$ks_normal && results$visual_normal
  } else {
    results$normal <- results$visual_normal
  }
  
  # Recommendation
  if (is.na(results$normal) || results$normal) {
    results$recommendation <- "parametric"
  } else {
    results$recommendation <- "non-parametric"
  }
  
  results$n <- length(data)
  results$alpha <- alpha
  
  return(results)
}

# ============================================================================
# CHECK VARIANCE HOMOGENEITY
# ============================================================================

#' Check for equal variances between groups
#' 
#' @param data Vector of numeric values
#' @param group Vector of group labels (must be same length as data)
#' @param alpha Significance threshold (default: 0.05)
#' @return List with test results
check_variance_homogeneity <- function(data, group, alpha = 0.05) {
  
  # Remove NA values
  valid_idx <- !is.na(data) & !is.na(group)
  data <- data[valid_idx]
  group <- group[valid_idx]
  
  if (length(unique(group)) < 2) {
    return(list(
      equal_variances = NA,
      reason = "Less than 2 groups",
      levene_p = NA,
      bartlett_p = NA,
      recommendation = "parametric"
    ))
  }
  
  results <- list()
  
  # Levene's test (robust to non-normality)
  tryCatch({
    # Create data frame for leveneTest
    df <- data.frame(value = data, group = as.factor(group))
    
    # Simple Levene's test (mean-based)
    group_means <- tapply(df$value, df$group, mean, na.rm = TRUE)
    df$centered <- abs(df$value - group_means[df$group])
    
    levene_test <- aov(centered ~ group, data = df)
    levene_summary <- summary(levene_test)
    
    if (length(levene_summary[[1]]) > 0) {
      results$levene_p <- levene_summary[[1]][["Pr(>F)"]][1]
      results$levene_equal <- results$levene_p >= alpha
    } else {
      results$levene_p <- NA
      results$levene_equal <- NA
    }
  }, error = function(e) {
    results$levene_p <- NA
    results$levene_equal <- NA
  })
  
  # Bartlett's test (sensitive to non-normality, but more powerful if normal)
  tryCatch({
    bartlett_test <- bartlett.test(data ~ group)
    results$bartlett_p <- bartlett_test$p.value
    results$bartlett_equal <- results$bartlett_p >= alpha
  }, error = function(e) {
    results$bartlett_p <- NA
    results$bartlett_equal <- NA
  })
  
  # Overall assessment (prefer Levene's as it's more robust)
  if (!is.na(results$levene_equal)) {
    results$equal_variances <- results$levene_equal
  } else if (!is.na(results$bartlett_equal)) {
    results$equal_variances <- results$bartlett_equal
  } else {
    results$equal_variances <- NA
  }
  
  # Recommendation
  if (is.na(results$equal_variances) || results$equal_variances) {
    results$recommendation <- "t-test (equal variances)"
  } else {
    results$recommendation <- "t-test (Welch's, unequal variances)"
  }
  
  results$alpha <- alpha
  results$n_groups <- length(unique(group))
  
  return(results)
}

# ============================================================================
# DIAGNOSTIC PLOTS
# ============================================================================

#' Generate diagnostic plots for assumption checking
#' 
#' @param data Vector of numeric values
#' @param group Optional grouping variable
#' @param output_dir Directory to save plots
#' @param prefix Filename prefix for saved plots
#' @return List of ggplot objects
diagnostic_plots <- function(data, group = NULL, output_dir = NULL, prefix = "diagnostic") {
  
  plots <- list()
  
  # Remove NA values
  valid_idx <- !is.na(data)
  data_clean <- data[valid_idx]
  
  if (is.null(group)) {
    group_clean <- NULL
  } else {
    group_clean <- group[valid_idx]
  }
  
  # 1. Histogram with normal curve overlay
  df_hist <- data.frame(value = data_clean)
  if (!is.null(group_clean)) {
    df_hist$group <- group_clean
  }
  
  p_hist <- ggplot(df_hist, aes(x = value)) +
    geom_histogram(aes(y = ..density..), bins = 30, fill = "steelblue", alpha = 0.7, color = "white") +
    stat_function(fun = dnorm, 
                  args = list(mean = mean(data_clean), sd = sd(data_clean)),
                  color = "red", linewidth = 1.2) +
    labs(title = "Distribution Histogram",
         subtitle = "Red line shows expected normal distribution",
         x = "Value", y = "Density") +
    theme_minimal()
  
  if (!is.null(group_clean)) {
    p_hist <- p_hist + facet_wrap(~ group, scales = "free")
  }
  
  plots$histogram <- p_hist
  
  # 2. Q-Q plot
  df_qq <- data.frame(value = data_clean)
  if (!is.null(group_clean)) {
    df_qq$group <- group_clean
    p_qq <- ggplot(df_qq, aes(sample = value)) +
      stat_qq() +
      stat_qq_line(color = "red", linewidth = 1.2) +
      facet_wrap(~ group, scales = "free") +
      labs(title = "Q-Q Plot (Normality Check)",
           subtitle = "Points should follow red line if normally distributed",
           x = "Theoretical Quantiles", y = "Sample Quantiles") +
      theme_minimal()
  } else {
    p_qq <- ggplot(df_qq, aes(sample = value)) +
      stat_qq() +
      stat_qq_line(color = "red", linewidth = 1.2) +
      labs(title = "Q-Q Plot (Normality Check)",
           subtitle = "Points should follow red line if normally distributed",
           x = "Theoretical Quantiles", y = "Sample Quantiles") +
      theme_minimal()
  }
  
  plots$qq_plot <- p_qq
  
  # 3. Box plot (if groups are provided)
  if (!is.null(group_clean)) {
    df_box <- data.frame(value = data_clean, group = group_clean)
    p_box <- ggplot(df_box, aes(x = group, y = value, fill = group)) +
      geom_boxplot(alpha = 0.7) +
      geom_jitter(width = 0.2, alpha = 0.3) +
      labs(title = "Box Plot by Group",
           subtitle = "Visual check for variance homogeneity and outliers",
           x = "Group", y = "Value") +
      theme_minimal() +
      theme(legend.position = "none")
    
    plots$boxplot <- p_box
  }
  
  # Save plots if output directory is provided
  if (!is.null(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    
    ggsave(file.path(output_dir, paste0(prefix, "_histogram.png")), 
           p_hist, width = 10, height = 6, dpi = 300)
    ggsave(file.path(output_dir, paste0(prefix, "_qqplot.png")), 
           p_qq, width = 10, height = 6, dpi = 300)
    
    if (!is.null(group_clean) && "boxplot" %in% names(plots)) {
      ggsave(file.path(output_dir, paste0(prefix, "_boxplot.png")), 
             plots$boxplot, width = 8, height = 6, dpi = 300)
    }
  }
  
  return(plots)
}

# ============================================================================
# AUTOMATIC TEST SELECTION
# ============================================================================

#' Automatically select appropriate statistical test based on assumptions
#' 
#' @param data Vector of numeric values
#' @param group Vector of group labels
#' @param alpha Significance threshold (default: 0.05)
#' @param output_dir Optional directory for diagnostic plots
#' @param prefix Optional prefix for diagnostic plots
#' @return List with test selection and assumption checks
select_appropriate_test <- function(data, group, alpha = 0.05, 
                                    output_dir = NULL, prefix = "assumptions") {
  
  results <- list()
  
  # Check normality
  normality_results <- list()
  for (g in unique(group)) {
    group_data <- data[group == g & !is.na(data) & !is.na(group)]
    if (length(group_data) >= 3) {
      normality_results[[as.character(g)]] <- check_normality(group_data, alpha = alpha)
    }
  }
  
  results$normality <- normality_results
  
  # Check variance homogeneity
  variance_results <- check_variance_homogeneity(data, group, alpha = alpha)
  results$variance <- variance_results
  
  # Generate diagnostic plots
  if (!is.null(output_dir)) {
    plots <- diagnostic_plots(data, group, output_dir, prefix)
    results$plots <- plots
  }
  
  # Decision tree for test selection
  all_normal <- all(sapply(normality_results, function(x) {
    if (is.null(x) || is.na(x$normal)) return(FALSE)
    return(x$normal)
  }))
  
  equal_var <- if (is.na(variance_results$equal_variances)) {
    TRUE  # Assume equal if we can't test
  } else {
    variance_results$equal_variances
  }
  
  # Test recommendation
  if (all_normal && equal_var) {
    results$recommended_test <- "t-test (two-sample, equal variances)"
    results$test_function <- "t.test"
    results$parametric <- TRUE
  } else if (all_normal && !equal_var) {
    results$recommended_test <- "t-test (Welch's, unequal variances)"
    results$test_function <- "t.test"  # R's t.test uses Welch by default
    results$parametric <- TRUE
  } else {
    results$recommended_test <- "Wilcoxon rank-sum test (non-parametric)"
    results$test_function <- "wilcox.test"
    results$parametric <- FALSE
  }
  
  # Summary
  results$summary <- list(
    normality_passed = all_normal,
    variance_homogeneity_passed = equal_var,
    recommended_test = results$recommended_test,
    parametric = results$parametric
  )
  
  return(results)
}

# ============================================================================
# HELPER: Print assumption check results
# ============================================================================

#' Print assumption check results in a readable format
#' 
#' @param assumption_results Output from select_appropriate_test()
print_assumption_results <- function(assumption_results) {
  
  cat("\n")
  cat(paste(rep("=", 70), collapse = ""), "\n")
  cat("STATISTICAL ASSUMPTIONS CHECK\n")
  cat(paste(rep("=", 70), collapse = ""), "\n\n")
  
  # Normality
  cat("NORMALITY CHECK:\n")
  cat(paste(rep("-", 70), collapse = ""), "\n")
  for (group_name in names(assumption_results$normality)) {
    norm <- assumption_results$normality[[group_name]]
    cat(sprintf("  Group: %s (n = %d)\n", group_name, norm$n))
    
    if (!is.na(norm$shapiro_p)) {
      cat(sprintf("    Shapiro-Wilk test: p = %.4f", norm$shapiro_p))
      if (norm$shapiro_normal) {
        cat(" ✓ Normal\n")
      } else {
        cat(" ✗ Not normal\n")
      }
    }
    
    if (!is.na(norm$skewness)) {
      cat(sprintf("    Skewness: %.3f", norm$skewness))
      if (abs(norm$skewness) < 2) {
        cat(" ✓ Acceptable\n")
      } else {
        cat(" ✗ Too skewed\n")
      }
    }
    
    if (!is.na(norm$kurtosis)) {
      cat(sprintf("    Kurtosis: %.3f", norm$kurtosis))
      if (abs(norm$kurtosis) < 2) {
        cat(" ✓ Acceptable\n")
      } else {
        cat(" ✗ Too kurtotic\n")
      }
    }
    
    cat("\n")
  }
  
  # Variance homogeneity
  cat("VARIANCE HOMOGENEITY CHECK:\n")
  cat(paste(rep("-", 70), collapse = ""), "\n")
  var_res <- assumption_results$variance
  
  if (!is.na(var_res$levene_p)) {
    cat(sprintf("  Levene's test: p = %.4f", var_res$levene_p))
    if (var_res$levene_equal) {
      cat(" ✓ Equal variances\n")
    } else {
      cat(" ✗ Unequal variances\n")
    }
  }
  
  if (!is.na(var_res$bartlett_p)) {
    cat(sprintf("  Bartlett's test: p = %.4f", var_res$bartlett_p))
    if (var_res$bartlett_equal) {
      cat(" ✓ Equal variances\n")
    } else {
      cat(" ✗ Unequal variances\n")
    }
  }
  
  cat("\n")
  
  # Recommendation
  cat("RECOMMENDATION:\n")
  cat(paste(rep("-", 70), collapse = ""), "\n")
  cat(sprintf("  Recommended test: %s\n", assumption_results$recommended_test))
  cat(sprintf("  Parametric: %s\n", if (assumption_results$parametric) "Yes" else "No"))
  cat("\n")
  cat(paste(rep("=", 70), collapse = ""), "\n\n")
}

