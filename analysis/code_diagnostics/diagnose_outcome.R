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

# Process input arguments ----------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
print(length(args))
if (length(args) == 0) {
  outcome <- "rsd"
} else {
  outcome <- args[[1]]
}

# Cohorts to check
cohorts <- c("prevax", "unvax", "vax")

# Define clean dataset output folder -------------------------------------------
print("Creating output/code_diagnostics output folder")

codediag_dir <- "output/code_diagnostics/"
dir_create(here::here(codediag_dir))

# Define output text file ------------------------------------------------------
print("creating output text file")

out_file <- paste0(codediag_dir, outcome, ".txt")

# Start txt file ---------------------------------------------------------------
sink(out_file)

# Load cohort dataset from dataset_definition using dataset_clean code ---------

for (cohort in cohorts) {
  # Get column names ----
  print('Get column names')

  file_path <- paste0("output/dataset_definition/input_", cohort, ".csv.gz")
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

  input <- read_csv(
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
  cat("\n")
  print(skim(input))
  cat("\n\n")
}
sink()
