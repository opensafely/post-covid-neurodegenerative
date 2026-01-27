# Load packages ----------------------------------------------------------------
print('Load packages')

library(magrittr)
library(dplyr)

# Source common functions ------------------------------------------------------
print('Source common functions')

source("analysis/utility.R")

# Specify arguments ------------------------------------------------------------
print("Specify arguments")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  subgroup <- "main"
} else {
  subgroup <- args[[1]]
}

# Noday0 processing ------------------------------------------------------------
if (grepl("_noday0", subgroup)) {
  noday0_str <- "_noday0"
  subgroup <- gsub("_noday0", "", subgroup)
  noday0_flag <- TRUE
} else {
  noday0_str <- ""
  noday0_flag <- FALSE
}

# Define model output folder ---------------------------------------------------
print("Creating output/model output folder")

# setting up the sub directory
makeout_dir <- "output/make_output/"
model_dir <- "output/model/"

# check if sub directory exists, create if not
fs::dir_create(here::here(makeout_dir))

# Load active analyses ---------------------------------------------------------
print('Load active analyses')

active_analyses <- readr::read_rds("lib/active_analyses.rds")

# List available model outputs -----------------------------------------------
print('List available model outputs')

files <- list.files(
  model_dir,
  pattern = paste0("model_output-.*", subgroup, ".*")
) # subgroup filtering
files <- intersect(
  files,
  paste0(
    c("model_output-", "stata_model_output-"),
    rep(active_analyses$name, each = 2),
    ".csv"
  )
) # only include models currently in active_analyses
files <- files[grepl("_noday0", files) == noday0_flag] # noday0 processing

# Combine model output (R, and Stata if available) -----------------------------
print('Combine model output')

df <- NULL

for (i in files) {
  ## Load model output
  print('Load model output')

  tmp <- readr::read_csv(paste0(model_dir, i))

  ## Handle errors
  if (colnames(tmp)[1] == "error") {
    dummy <- data.frame(
      model = "",
      exposure = "",
      outcome = gsub(".*-", "", gsub(".csv", "", i)),
      term = "",
      lnhr = NA,
      se_lnhr = NA,
      hr = NA,
      conf_low = NA,
      conf_high = NA,
      N_total = NA,
      N_exposed = NA,
      N_events = NA,
      person_time_total = NA,
      outcome_time_median = NA,
      strata_warning = "",
      surv_formula = "",
      input = "",
      error = tmp$error
    )
    tmp <- dummy
  } else {
    tmp$error <- ""
  }

  ## Add source file name
  tmp$name <- gsub("^(stata_)?model_output-", "", gsub("\\.csv", "", i))

  ## Add source column (R vs Stata)
  tmp$source <- ifelse(grepl("^stata_model_output", i), "Stata", "R")

  ## Append to master dataframe
  df <- plyr::rbind.fill(df, tmp)
}

# Add details from active analyses ---------------------------------------------
print('Add details from active analyses')

if (any(names(df) %in% c("exposure", "outcome"))) {
  df <- df[, !(names(df) %in% c("exposure", "outcome"))]
}

df <- merge(
  df,
  active_analyses[, c("name", "cohort", "outcome", "analysis")],
  by = "name",
  all.x = TRUE
)

df$outcome <- gsub("out_date_", "", df$outcome)

# Save model output ------------------------------------------------------------
print('Save model output')

df <- df[, c(
  "name",
  "cohort",
  "outcome",
  "analysis",
  "error",
  "model",
  "term",
  "lnhr",
  "se_lnhr",
  "hr",
  "conf_low",
  "conf_high",
  "N_total",
  "N_exposed",
  "N_events",
  "person_time_total",
  "outcome_time_median",
  "strata_warning",
  "surv_formula",
  "source"
)]

readr::write_csv(
  df,
  paste0(makeout_dir, "model_output-", subgroup, noday0_str, ".csv")
)

# Perform redaction ------------------------------------------------------------
print('Perform redaction')

df$N_total_midpoint6 <- roundmid_any(df$N_total)
df$N_exposed_midpoint6 <- roundmid_any(df$N_exposed)
df$N_events_midpoint6 <- roundmid_any(df$N_events)
df$person_time_total_midpoint6 <- roundmid_any(df$person_time_total)
df[, c("N_total", "N_exposed", "N_events", "person_time_total")] <- NULL

# Save model output ------------------------------------------------------------
print('Save model output')

readr::write_csv(
  df,
  paste0(makeout_dir, "model_output-", subgroup, noday0_str, "-midpoint6.csv")
)
