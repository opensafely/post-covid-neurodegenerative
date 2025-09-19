# Load libraries ---------------------------------------------------------------
print("Load libraries")

library(magrittr)
library(here)
library(dplyr)
library(jsonlite)
library(skimr)

# Define table_age output folder ---------------------------------------------------------
print("Creating output/table_age output folder")

table_age_dir <- "output/table_age/"
fs::dir_create(here::here(table_age_dir))

# Source common functions ------------------------------------------------------
print("Source common functions")

source("analysis/utility.R")

# Load json file containing vax study dates ------------------------------------
print('Load json file containing vax study dates')

study_dates <- fromJSON("output/study_dates.json")

# Specify arguments ------------------------------------------------------------
print("Specify arguments")

args <- commandArgs(trailingOnly = TRUE)

print(length(args))

if (length(args) == 0) {
  cohort <- "unvax"
  age_str <- "40;45;55;60;65"
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

# Create exposure indicator ----------------------------------------------------
print("Create exposure indicator")

df$exposed <- !is.na(df$exp_date_covid)

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

# Outcome Processing ----------------------------------------------------------
print("Outcome Processing")

df <- df %>%

  mutate(across(
    matches("out_date*"),
    ~ if_else(
      !is.na(.x) & .x >= index_date & .x <= study_dates$lcd_date,
      TRUE,
      FALSE
    )
  ))

for (colname in colnames(df)[grepl("out_date", colnames(df))]) {
  df[[colname]] <- sapply(df[[colname]], as.character)
}


# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[, c(
  "patient_id",
  "exposed",
  "cov_cat_age_group",
  colnames(df)[grepl("out_date", colnames(df))]
)]

df$All <- "All"

# Convert to characteristics and subcharacteristics ----------------------------
print("Convert to characteristics and subcharacteristics")

df <- tidyr::pivot_longer(
  df,
  cols = setdiff(colnames(df), c("patient_id", "exposed", "cov_cat_age_group")),
  names_to = "characteristic",
  values_to = "subcharacteristic"
)

df$total <- 1

# Tidy missing data labels -----------------------------------------------------
print("Tidy missing data labels")

df$subcharacteristic <- ifelse(
  df$subcharacteristic == "" |
    df$subcharacteristic == "unknown" |
    is.na(df$subcharacteristic),
  "Missing",
  df$subcharacteristic
)

# Aggregate data ---------------------------------------------------------------

print("Aggregate data")

df <- df %>%
  group_by(cov_cat_age_group, characteristic) %>%
  summarise(
    exposed = sum(exposed, na.rm = TRUE),
    total = sum(total, na.rm = TRUE),
    .groups = "drop"
  )


# Sort characteristics ---------------------------------------------------------
print("Sort characteristics")

df <- df[order(df$characteristic, df$cov_cat_age_group), ]

# Save Table Age -----------------------------------------------------------------
print("Save Table Age")

write.csv(
  df,
  paste0(table_age_dir, "table_age-cohort_", cohort, preex_string, ".csv"),
  row.names = FALSE
)

# Perform redaction ------------------------------------------------------------
print("Perform redaction")

df <- df[df$characteristic != FALSE, ] # Remove False binary data
df$total_midpoint6 <- roundmid_any(df$total)
df$exposed_midpoint6 <- roundmid_any(df$exposed)

# Calculate column percentages -------------------------------------------------

df <- df[, c(
  "characteristic",
  "cov_cat_age_group",
  "total_midpoint6",
  "exposed_midpoint6"
)]

df <- dplyr::rename(
  df,
  "Characteristic" = "characteristic",
  "Age Group" = "cov_cat_age_group",
  "Total outcome count [midpoint6_derived]" = "total_midpoint6",
  "COVID-19 diagnoses [midpoint6_derived]" = "exposed_midpoint6"
)

# Save Table Age -----------------------------------------------------------------
print("Save rounded Table Age")

write.csv(
  df,
  paste0(
    table_age_dir,
    "table_age-cohort_",
    cohort,
    preex_string,
    "-midpoint6.csv"
  ),
  row.names = FALSE
)
