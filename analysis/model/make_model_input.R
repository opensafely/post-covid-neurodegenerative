# Load packages ----------------------------------------------------------------
print("Load packages")

library(magrittr)
library(data.table)
library(stringr)
library(lubridate)

# Source functions -------------------------------------------------------------
print("Source functions")

lapply(
  list.files("analysis/model", full.names = TRUE, pattern = "fn-"),
  source
)

# Specify arguments ------------------------------------------------------------
print("Specify arguments")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  name <- "cohort_prevax-sub_covidhospital_FALSE_preex_FALSE-asthma"
} else {
  name <- args[[1]]
}

analysis <- gsub(
  "cohort_.*vax-",
  "",
  name
)

# Define model output folder ---------------------------------------
print("Creating output/model output folder")

# setting up the sub directory
model_dir <- "output/model/"

# check if sub directory exists, create if not
fs::dir_create(here::here(model_dir))

# Load and prepare data by selecting project-required columns
print("Load and prepare data for analysis")

pmi <- prepare_model_input(name)

# Restrict to required population -------------------------------------------
print('Restrict to required population')

# Creating a pre-existing condition variable where appropriate
if (grepl("preex", name)) {
  # True false indicator of preex
  preex <- as.logical(
    gsub(
      ".*preex_([^\\-]+)-.*",
      "\\1",
      name
    )
  )

  # Remove preex string from analysis string
  analysis <- gsub(
    "_preex_.*",
    "",
    analysis
  )
  df <- pmi$input[pmi$input$sup_bin_preex == preex, ]
} else {
  df <- pmi$input
}

## Perform subgroup-specific manipulation
print("Perform subgroup-specific manipulation")

print(paste0("Make model input: ", analysis))

check_for_subgroup <- (grepl("main", analysis)) # TRUE if subgroup is main, FALSE otherwise

# Make model input: main/sub_covidhistory ------------------------------------
if (grepl("sub_covidhistory", analysis)) {
  check_for_subgroup <- TRUE
  df <- df[df$sub_bin_covidhistory == TRUE, ] # Only selecting for this subgroup
} else {
  df <- df[df$sub_bin_covidhistory == FALSE, ] # all other subgroups (inc. Main)
}

# Make model input: sub_covidhospital ----------------------------------------
if (grepl("sub_covidhospital", analysis)) {
  check_for_subgroup <- TRUE
  covidhosp <- as.logical(gsub(
    ".*sub_covidhospital_",
    "",
    analysis
  ))
  str_covidhosp_cens <- ifelse(covidhosp, "non_hospitalised", "hospitalised")
  df <- df %>%
    dplyr::mutate(
      end_date_outcome = as.Date(
        ifelse(
          sub_cat_covidhospital == str_covidhosp_cens,
          exp_date - 1,
          end_date_outcome
        ),
        origin = .Date(0)
      ),
      exp_date = as.Date(
        ifelse(
          sub_cat_covidhospital == str_covidhosp_cens,
          NA_Date_,
          exp_date
        ),
        origin = .Date(0)
      ),
      out_date = as.Date(
        ifelse(
          out_date > end_date_outcome,
          NA_Date_,
          out_date
        ),
        origin = .Date(0)
      )
    ) %>%
    dplyr::filter(end_date_outcome >= index_date)
}

# Make model input: sub_sex_* ------------------------------------------------
if (grepl("sub_sex_", analysis)) {
  check_for_subgroup <- TRUE
  sex <- str_to_title(gsub(
    ".*sub_sex_",
    "",
    analysis
  ))
  df <- df[df$cov_cat_sex == sex, ]
}

# Make model input: sub_age_* ------------------------------------------------
if (grepl("sub_age_", analysis) == TRUE) {
  check_for_subgroup <- TRUE
  min_age <- as.numeric(strsplit(
    gsub(".*sub_age_", "", analysis),
    split = "_"
  )[[1]][1])
  max_age <- as.numeric(strsplit(
    gsub(".*sub_age_", "", analysis),
    split = "_"
  )[[1]][2])
  df <- df[
    df$cov_num_age >= min_age &
      df$cov_num_age < (max_age + 1),
  ]
}

# Make model input: sub_ethnicity_* ------------------------------------------
if (grepl("sub_ethnicity_", analysis) == TRUE) {
  check_for_subgroup <- TRUE
  ethnicity <- str_to_title(gsub(
    "_",
    " ",
    gsub(
      ".*sub_ethnicity_",
      "",
      analysis
    )
  ))
  df <- df[df$cov_cat_ethnicity == ethnicity, ]
}

# Make model input: sub_smoking_* ------------------------------------------
if (grepl("sub_smoking_", analysis)) {
  check_for_subgroup <- TRUE
  smoking <- paste(
    str_to_title(gsub(
      ".*sub_smoking_",
      "",
      analysis
    )),
    "smoker"
  )
  df <- df[df$cov_cat_smoking == smoking, ]
}

# Stop code if no subgroup/main analysis was correctly selected
if (isFALSE(check_for_subgroup)) {
  stop(paste0("Input: ", name, " did not undergo any subgroup filtering!"))
}

# Save model output
df <- df %>%
  dplyr::select(tidyselect::all_of(pmi$keep))

check_vitals(df)
readr::write_rds(
  df,
  file.path(
    model_dir,
    paste0("model_input-", name, ".rds")
  ),
  compress = "gz"
)
print(paste0(
  "Saved: ",
  model_dir,
  "model_input-",
  name,
  ".rds"
))
