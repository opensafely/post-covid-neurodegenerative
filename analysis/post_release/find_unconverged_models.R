# Load libraries ---------------------------------------------------------------
print('Load libraries')

library(magrittr)
library(tidyverse)
library(purrr)
library(data.table)
library(tidyverse)
library(svglite)
library(VennDiagram)
library(grid)
library(gridExtra)

# Specify paths ----------------------------------------------------------------
print('Specify paths')

# NOTE:
# This file is used to specify paths and is in the .gitignore to keep your information secret.
# A file called specify_paths_example.R is provided for you to fill in.
# Please remove "_example" from the file name and add your specific file paths before running this script.

source("analysis/specify_paths.R")

# Source functions -------------------------------------------------------------
print('Source functions')

source("analysis/utility.R")

# Make post-release directory --------------------------------------------------
print('Make post-release directory')

dir.create("output/post_release/", recursive = TRUE, showWarnings = FALSE)
output_folder <- "output/post_release/"

# Find all model files ---------------------------------------------------------
print('Collecting list of models')
file_list <- list.files(
  path = paste0(release, "20250804\\"),
  pattern = "^model_output-.*-midpoint6\\.csv$",
  full.names = TRUE
)

# Read and combine all CSV files into one data frame---------------------------
print('Loading and combining models')
df <- file_list %>%
  lapply(read_csv, show_col_types = FALSE) %>%
  bind_rows()

# Define bounds for checking --------------------------------------------------
lb <- 0.25
ub <- 32

# Find relevant rows ----------------------------------------------------------
print('Filtering dataframe')
df <- df[df$hr < lb | df$hr > ub | df$conf_low < lb | df$conf_high > ub, ] # HR range restriction
df <- df[!(df$term %in% c("days_pre", "days0_1")), ] # Term restriction
df <- df[!is.na(df$name), ] #NA filtering

unconverged_list <- sprintf('"%s"', unique(df$name))

# Save list of models ---------------------------------------------------------
print("Saving .txt list of models")
writeLines(
  paste(unconverged_list, collapse = ",\n"),
  "output/post_release/unconverged_models.txt"
)

# Save related dataframe -------------------------------------------------------
print("Save dataframe of unconverged models")

readr::write_csv(
  df,
  paste0(output_folder, "/unconverged_models.csv"),
  na = "-"
)
