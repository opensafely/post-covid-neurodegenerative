# Load packages ----------------------------------------------------------------
print('Load packages')

library(magrittr)

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  # name <- "all" # prepare datasets for all active analyses 
  name <- "cohort_prevax-main-addiction" # prepare datasets for all active analyses whose name contains X
  # name <- "vax-depression-main;vax-depression-sub_covid_hospitalised;vax-depression-sub_covid_nonhospitalised" # prepare datasets for specific active analyses
} else {
  name <- args[[1]]
}


# Load active analyses ---------------------------------------------------------
print('Load active analyses')

active_analyses <- readr::read_rds("lib/active_analyses.rds")

# Identify model inputs to be prepared -----------------------------------------
print('Identify model inputs to be prepared')

if (name=="all") {
  prepare <- active_analyses$name
} else if(grepl(";",name)) {
  prepare <- stringr::str_split(as.vector(name), ";")[[1]]
} else {
  prepare <- active_analyses[grepl(name,active_analyses$name),]$name
}

# Describe model outputs --------------------------------------------------------
print('Describe model outputs')

for (i in prepare) {
  
  ## Load model output
  
  tmp <- readr::read_rds(paste0("output/model_input-",i,".rds"))
  
  ## Describe file
  
  sink(paste0("output/describe-",i,".txt"))
  print(Hmisc::describe(tmp))
  sink()
  
}
