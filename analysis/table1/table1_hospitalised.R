# Load libraries ---------------------------------------------------------------
print("Load libraries")

library(magrittr)
library(here)
library(dplyr)

# Define table1 output folder ---------------------------------------------------------
print("Creating output/table1 output folder")

table1_dir <- "output/table1/"
fs::dir_create(here::here(table1_dir))

# Source common functions ------------------------------------------------------
print("Source common functions")

source("analysis/utility.R")
source("analysis/table1/fn-hospitalised_counts.R")

# Specify arguments ------------------------------------------------------------
print("Specify arguments")

args <- commandArgs(trailingOnly = TRUE)

print(length(args))

if (length(args) == 0) {
  cohort <- "prevax"
  age_str <- "18;40;65;85;111"
  preex <- "All" # "All", TRUE, or FALSE
} else {
  cohort <- args[[1]]
  age_str <- args[[2]]
  if (length(args) < 3) {
    preex <- "All"
  } else {
    preex <- args[[3]]
  } # allow an empty input for the preex variable
}


age_bounds <- as.numeric(stringr::str_split(as.vector(age_str), ";")[[1]])

# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_rds(paste0(
  "output/dataset_clean/input_",
  cohort,
  "_clean.rds"
))

# Table 1 Processing Start -----------------------------------------------------
print("Table 1 processing")

# Remove people with history of COVID-19 ---------------------------------------
print("Remove people with history of COVID-19")

df <- df[df$sub_bin_covidhistory == FALSE, ]

# Select for pre-existing conditions -------------------------------------------
print("Select for pre-existing conditions")

preex_string <- ""
if (preex != "All") {
  df <- df[df$sup_bin_preex == preex, ]
  preex_string <- paste0("-preex_", preex)
}

# Define age groups ------------------------------------------------------------
print("Define age groups")

df$cov_cat_age_group <- numerical_to_categorical(df$cov_num_age, age_bounds) # See utility.R

df$cov_cat_consrate2019 <- numerical_to_categorical(
  df$cov_num_consrate2019,
  c(1, 6),
  zero_flag = TRUE
)

median_iqr_age <- create_median_iqr_string(df$cov_num_age) # See utility.R


# Exposure = hospitalisation -------------------------------------------

df$hospitalised = !is.na(df$exp_date_covid) &
  (df$sub_cat_covidhospital == "hospitalised")
df$nonhospitalised = !is.na(df$exp_date_covid) &
  !(df$sub_cat_covidhospital == "hospitalised")

median_iqr_age_hosp <- create_median_iqr_string(
  df[df$hospitalised, ]$cov_num_age
) # See utility.R
median_iqr_age_nonhosp <- create_median_iqr_string(
  df[df$nonhospitalised, ]$cov_num_age
) # See utility.R


# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[, c(
  "patient_id",
  "hospitalised",
  "nonhospitalised",
  colnames(df)[grepl("cov_cat_", colnames(df))],
  colnames(df)[grepl("strat_cat_", colnames(df))],
  colnames(df)[grepl("cov_bin_", colnames(df))]
)]

df$All <- "All"

# Aggregate data ---------------------------------------------------------------

print("Aggregate data")

df <- hospitalised_counts(df)


# Sort characteristics ---------------------------------------------------------
print("Sort characteristics")

df <- df[order(df$characteristic, df$subcharacteristic), ]

# Add in Median IQR ------------------------------------------------------------
print('Add median (IQR) age')

# Pastes: "Mean Age (LQ Age - UQ Age)" as a string for each cohort
df[nrow(df) + 1, ] <- c(
  "Age, years",
  "Median (IQR)",
  median_iqr_age,
  median_iqr_age_hosp,
  median_iqr_age_nonhosp
)


# Save Table 1 -----------------------------------------------------------------
print("Save Table 1")

write.csv(
  df,
  paste0(
    table1_dir,
    "table1_hospitalised-cohort_",
    cohort,
    preex_string,
    ".csv"
  ),
  row.names = FALSE
)

# Perform redaction ------------------------------------------------------------
print("Perform redaction")

df <- df[df$subcharacteristic != "Median (IQR)", ] # Remove Median IQR row
df <- df[df$subcharacteristic != FALSE, ] # Remove False binary data

df$total_midpoint6 <- roundmid_any(df$total)
df$hospitalised_midpoint6 <- roundmid_any(df$hospitalised)
df$nonhospitalised_midpoint6 <- roundmid_any(df$nonhospitalised)

# Calculate column percentages -------------------------------------------------

df$percent_hospitalised_midpoint6 <- round(
  df$hospitalised_midpoint6 /
    df$total_midpoint6 *
    100,
  1
)

df$percent_nonhospitalised_midpoint6 <- round(
  df$nonhospitalised_midpoint6 /
    df$total_midpoint6 *
    100,
  1
)

df <- df[, c(
  "characteristic",
  "subcharacteristic",
  "total_midpoint6",
  "hospitalised_midpoint6",
  "percent_hospitalised_midpoint6",
  "nonhospitalised_midpoint6",
  "percent_nonhospitalised_midpoint6"
)]

df[nrow(df) + 1, ] <- c(
  "Age, years",
  "Median (IQR)",
  median_iqr_age,
  median_iqr_age_hosp,
  "",
  median_iqr_age_nonhosp,
  ""
)

df <- dplyr::rename(
  df,
  "Characteristic" = "characteristic",
  "Subcharacteristic" = "subcharacteristic",
  "N [midpoint6]" = "total_midpoint6",
  "N (COVID-19 Hospitalised) [midpoint6]" = "hospitalised_midpoint6",
  "% (COVID-19 Hospitalised) [midpoint6_derived]" = "percent_hospitalised_midpoint6",
  "N (COVID-19 Non-hospitalised) [midpoint6]" = "nonhospitalised_midpoint6",
  "% (COVID-19 Non-hospitalised) [midpoint6_derived]" = "percent_nonhospitalised_midpoint6",
)

# Save Table 1 -----------------------------------------------------------------
print("Save rounded Table 1")

write.csv(
  df,
  paste0(
    table1_dir,
    "table1_hospitalised-cohort_",
    cohort,
    preex_string,
    "-midpoint6.csv"
  ),
  row.names = FALSE
)
