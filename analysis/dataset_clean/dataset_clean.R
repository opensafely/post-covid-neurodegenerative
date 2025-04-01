# Load libraries --------------------------------------------------------------
print('Load libraries')

library(dplyr)
library(tidyverse)
library(lubridate)
library(data.table)
library(readr)
library(jsonlite)
library(here)
library(fs)
library(base)
library(stats)

# Define clean dataset output folder -------------------------------------------
print("Creating output/dataset_clean output folder")

dataclean_dir <- "output/dataset_clean/"
dir_create(here::here(dataclean_dir))

# Specify redaction threshold --------------------------------------------------
print('Specify redaction threshold')

threshold <- 6

# Load json file containing vax study dates ------------------------------------
print('Load json file containing vax study dates')

study_dates <- fromJSON("output/study_dates.json")

# Specify relevant dates -------------------------------------------------------
print('Specify relevant dates')

vax1_earliest <- as.Date(study_dates$vax1_earliest, format = "%Y-%m-%d")
mixed_vax_threshold <- as.Date(
  study_dates$mixed_vax_threshold,
  format = "%Y-%m-%d"
)
delta_date <- as.Date(study_dates$delta_date, format = "%Y-%m-%d")
lcd_date <- as.Date(study_dates$lcd_date, format = "%Y-%m-%d")

# Source common functions ------------------------------------------------------
print('Source common functions')

source("analysis/utility.R")
lapply(
  list.files("analysis/dataset_clean", full.names = TRUE, pattern = "fn-"),
  source
)

# Specify command arguments ----------------------------------------------------
print('Specify command arguments')

args <- commandArgs(trailingOnly = TRUE)
print(length(args))
if (length(args) == 0) {
  cohort <- "vax"
  describe <- TRUE
} else {
  cohort <- args[[1]]
  describe <- args[[2]]
}

describe <- as.logical(describe)

# Preprocess data --------------------------------------------------------------

input_preprocess <- preprocess(cohort, describe)

saveRDS(
  input_preprocess$venn,
  file = paste0(dataclean_dir, "venn_", cohort, ".rds"),
  compress = TRUE
)
message("Venn diagram data saved successfully")

message(paste0(
  "Preprocess dataset has N = ",
  nrow(input_preprocess$input),
  " rows"
))

# Specify flow table ----------------------------------------------------------
print('Specify flow table')

flow <- data.frame(
  Description = "Input",
  N = nrow(input_preprocess$input),
  stringsAsFactors = FALSE
)

# Inclusion criteria -----------------------------------------------------------
print('Call inclusion criteria function')

inex_results <- inex(
  input_preprocess$input,
  flow,
  cohort,
  vax1_earliest,
  mixed_vax_threshold,
  delta_date,
  lcd_date
)

# Quality assurance ------------------------------------------------------------
print('Call quality assurance function')

qa_results <- qa(inex_results$input, inex_results$flow, lcd_date)

# Set reference levels for factors----------------------------------------------
print('Call reference function')

input <- ref(qa_results$input)

# Save flow data after Inclusion criteria---------------------------------------
print('Saving flow data after Inclusion criteria')

flow <- qa_results$flow
flow$N <- as.numeric(flow$N)
flow$removed <- dplyr::lag(flow$N, default = dplyr::first(flow$N)) - flow$N

write.csv(
  flow,
  file = paste0(dataclean_dir, "flow_", cohort, ".csv"),
  row.names = FALSE
)

# Perform redaction-------------------------------------------------------------
print('Performing redaction')

flow$removed <- NULL
flow$N_midpoint6 <- roundmid_any(flow$N, to = threshold)
flow$removed_derived <- dplyr::lag(
  flow$N_midpoint6,
  default = dplyr::first(flow$N_midpoint6)
) -
  flow$N_midpoint6
flow$N <- NULL

# Save rounded flow data--------------------------------------------------------
print('Saving rounded flow data after Inclusion criteria')

write.csv(
  flow,
  file = paste0(dataclean_dir, "flow_", cohort, "_midpoint6.csv"),
  row.names = FALSE
)

# Save the dataset--------------------------------------------------------------
print(
  'Saving dataset after preprocessing, applying inclusion criteria, quality assurance checks, and setting reference levels'
)

input <- input %>%
  select(
    patient_id,
    index_date,
    starts_with("end_date_"),
    starts_with("sub_"), # Subgroups
    starts_with("exp_"), # Exposures
    starts_with("out_"), # Outcomes
    starts_with("cov_"), # Covariates
    starts_with("cens_"), # Censor
    starts_with("strat_"), # Strata
    starts_with("vax_date_"), # Vaccination dates
    starts_with("vax_cat_") # Vaccination products
  )

saveRDS(
  input,
  file = paste0(dataclean_dir, "input_", cohort, "_clean.rds"),
  compress = TRUE
)
