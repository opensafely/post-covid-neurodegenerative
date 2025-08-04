# Load libraries --------------------------------------------------------------
print('Load libraries')

library(dplyr)
library(tidyverse)
library(lubridate)
library(data.table)
library(readr)
library(here)
library(skimr)
library(fs)
library(base)
library(stats)
library(vroom)

# Process input arguments ----------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

# Arguements checked
# 1. Outcome of interest (string, eg. "rsd")
# 2. Cohorts (string, e.g. "vax" or "prevax;vax;unvax")
# 3. Dataset Definition group dd_group (string, e.g. "" for core definition, "rsd" for rsd study group)

print(length(args))
if (length(args) == 0) {
  outcome <- "rsd" # outcome of interest (matches any columns containing this string)
  cohorts <- c("prevax", "unvax", "vax") # cohorts to examine (can use "vax" or "prevax;vax;unvax" to specify single or multiple cohorts)
  dd_group <- ""
} else {
  outcome <- args[[1]]
  if (length(args) >= 2) {
    cohorts <- stringr::str_split(as.character(args[[2]]), ";")[[1]]
  } else {
    cohorts <- c("prevax", "unvax", "vax")
  }
  if (length(args) >= 3) {
    dd_group <- args[[3]]
  } else {
    dd_group <- ""
  }
}

if (dd_group != "") {
  dd_group <- paste0("_", dd_group)
}

cohort_str <- paste0("-", paste0(cohorts, collapse = "_"))

print(paste0(
  "Inputs are: ",
  outcome,
  ", ",
  cohort_str,
  ", ",
  dd_group,
  ". (Last input may be blank)."
))

# Define clean dataset output folder -------------------------------------------
print("Creating output/code_diagnostics output folder")

codediag_dir <- "output/code_diagnostics/"
dir_create(here::here(codediag_dir))

# Define output text file ------------------------------------------------------
print("creating output text file")

out_file <- paste0(codediag_dir, outcome, dd_group, cohort_str, ".txt")

# Start txt file ---------------------------------------------------------------
sink(out_file)

# Load cohort dataset from dataset_definition using dataset_clean code ---------

for (cohort in cohorts) {
  # Get column names ----
  print('Get column names')

  file_path <- paste0(
    "output/dataset_definition",
    dd_group,
    "/input",
    dd_group,
    "_",
    cohort,
    ".csv.gz"
  )
  all_cols <- fread(
    file_path,
    header = TRUE,
    sep = ",",
    nrows = 0,
    stringsAsFactors = FALSE
  ) %>%
    names()

  # Define column classes ----
  print('Define column classes')

  id_cols <- c("patient_id")
  out_cols <- c(grep(outcome, all_cols, value = TRUE))

  message("Column names Selected")
  print(c(id_cols, out_cols))

  message("Column classes identified")

  col_classes <- setNames(
    c(
      rep("c", length(id_cols)),
      rep("D", length(out_cols))
    ),
    all_cols[match(
      c(id_cols, out_cols),
      all_cols
    )]
  )
  message("Column classes defined")

  print('Load cohort dataset')

  input <- vroom(
    file_path,
    col_select = c(id_cols, out_cols),
    col_types = col_classes
  )

  message(paste0(
    "Dataset has been read successfully with N = ",
    nrow(input),
    " rows"
  ))

  # Save dataset characteristics
  cat("\n\n")
  print(paste0("***Summary of ", cohort, " cohort***"))
  print(paste0("***Generated from: ", file_path, " ***"))
  cat("\n")
  print(skim(input))
  cat("\n\n")
}
sink()

message(paste0(
  "File closed"
))
