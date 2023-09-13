# Load packages ----------------------------------------------------------------
print('Load packages')

library(magrittr)
library(data.table)
library(dplyr)
library(readr)

# Source functions -------------------------------------------------------------
print('Source functions')

source("analysis/model/fn-check_vitals.R")

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  output <- "dementias_diagnosis"
  cohorts <- "prevax;vax;unvax"
} else {
  output <- args[[1]]
  cohorts <- args[[2]]
}

# Separate cohorts -------------------------------------------------------------
print('Separate cohorts')

cohorts <- stringr::str_split(as.vector(cohorts), ";")[[1]]

# Create blank table -----------------------------------------------------------
print('Create blank table')

df <- NULL

# Add output from each cohort --------------------------------------------------
print('Add output from each cohort')

for (i in cohorts) {
  
  tmp <- readr::read_csv(paste0("output/",output,"_",i,"_rounded.csv"))
  df <- dplyr::bind_cols(df, tmp)
  
}

# Save output ------------------------------------------------------------------
print('Save output')

readr::write_csv(df, paste0("output/",output,"_output_rounded.csv"))
