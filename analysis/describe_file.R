# Load packages ----------------------------------------------------------------
print('Load packages')

library(magrittr)

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  file <- "model_input-cohort_prevax-main-parkinson"
  extn <- "rds"
} else {
  file <- args[[1]]
  extn <- args[[2]]
}

# Load file
print('Load file')

if (extn=="rds") {
  df <- readr::read_rds(paste0("output/",file,".rds"))
}

if (extn=="csv") {
  df <- readr::read_csv(paste0("output/",file,".csv"))
}

# Describe file
print('Describe file')

sink(paste0("output/describe-",gsub("\\.*","",file),".txt"))
print(Hmisc::describe(df))
sink()