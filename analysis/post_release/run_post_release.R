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
output_folder <- "output/post_release"

# Make master plot file --------------------------------------------------------
print('Make master plot file')

source("analysis/post_release/make_plot_data.R")

# Run absolute excess risk -----------------------------------------------------
print('Run absolute excess risk')

source("analysis/post_release/fn-lifetable.R")
source("analysis/post_release/lifetables_compiled.R")

# Identify tables and figures to run -------------------------------------------
print('Identify tables and figures to run')

tables <- list.files(
  path = "analysis/post_release/",
  pattern = "manuscript_table"
)

figures <- list.files(
  path = "analysis/post_release/",
  pattern = "manuscript_figure"
)

# Run tables and figures -------------------------------------------------------
print('Run tables and figures')

for (i in c(tables, figures)) {
  message(paste0("Making: ", gsub(".R", "", i)))
  source(paste0("analysis/post_release/", i))
}
