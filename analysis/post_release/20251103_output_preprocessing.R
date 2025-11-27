# a script for removing the "_noday0" strings from filenames and internal variables to allow the data to be processed by the same post_release scripts as other outputs.

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

# Specify paths for processing -------------------------------------------------
print('Specify paths')

release <- "C:\\Users\\pp24053\\OneDrive - University of Bristol\\Documents - grp-EHR\\Projects\\post-covid-events\\post-covid-neurodegenerative\\release\\" # Specify path to release directory

original_dir <- paste0(
  release,
  "20251103/"
)

output_dir <- paste0(
  release,
  "20251103_noday0_test/"
)

files_to_exclude <- c("model_output-main-midpoint6.csv")

#Create Folder -----------------------------------------------------------------
print("Create folder")
print('Make output directory')
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)


# Source functions -------------------------------------------------------------
print('Source functions')

source("analysis/utility.R")


# Generate list of files in folder ---------------------------------------------
print("Generating file list")
original_files <- setdiff(list.files(original_dir), files_to_exclude)

# Iterating through files ------------------------------------------------------

for (f in original_files) {
  # Remove `_noday0` from filename
  new_name <- gsub("_noday0", "", f)

  # Full input/output paths
  input_path <- file.path(original_dir, f)
  output_path <- file.path(output_dir, new_name)

  if (grepl("table1", f)) {
    file.copy(input_path, output_path, overwrite = TRUE)
  } else {
    # Read CSV
    df <- read.csv(input_path, stringsAsFactors = FALSE)

    # Remove `_noday0` inside data (applies to all character fields)
    df[] <- lapply(df, function(x) {
      if (is.character(x)) gsub("_noday0", "", x) else x
    })

    # Write modified CSV to target
    write.csv(df, output_path, row.names = FALSE)
  }
}

# move files over (non model)
# move model files over
# open each file and edit
