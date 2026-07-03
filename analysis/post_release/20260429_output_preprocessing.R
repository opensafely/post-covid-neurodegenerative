# 20260429_output_processing.R
#
# Run this after downloading the files, in order to process the filenames and create a directory containing only the relevant files
# Specifically, this script removes the "_noday0" strings from filenames and internal variables to allow the data to be processed by the same post_release scripts as other outputs.

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

source("analysis/specify_paths.R") # includes path to release folder

original_dir <- paste0(
  release,
  "20260429/"
)

output_dir <- paste0(
  release,
  "20260429_noday0/"
)

files_to_exclude <- list.files(original_dir, pattern = ".*_collapsed-.*") #exclude old collapsed models
files_to_add <- c() #files from previous request

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
original_files <- c(original_files, files_to_add)

# Iterating through files ------------------------------------------------------

for (f in original_files) {
  # Full input paths
  input_path <- file.path(original_dir, f)

  # Remove `_noday0` from filename and create output
  new_name <- gsub("_noday0", "", f)
  new_name <- ifelse(
    f %in% files_to_add,
    sub("^[^/]+/[^/]+/", "", new_name),
    new_name
  ) # removing everything before the second slash, so it saves in the new structure

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
