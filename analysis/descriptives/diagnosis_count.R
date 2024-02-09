# Load libraries ---------------------------------------------------------------
print('Load libraries')

#library(data.table)
library(readr)
library(dplyr)
library(stringr)
library(Hmisc)

# Specify redaction threshold --------------------------------------------------

threshold <- 6

# Source common functions ------------------------------------------------------
print('Source common functions')

source("analysis/utility.R")

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  cohort <- "prevax"
} else {
  cohort <- args[[1]]
}

# Read data ------- ------------------------------------------------------------
print('Load file')

df <- dplyr::as_tibble(readr::read_rds(paste0("output/input_", cohort, "_stage1.rds"))) 

# Filter columns of interest ---------------------------------------------------
df <- df %>%
  select_if(grepl("patient_id|alzheimer|other_dementias|any_dementia|unspecified_dementia|vascular_dementia", names(.))) %>%
  rename_at(vars(matches("out_date_")), ~ str_remove(., "out_date_")) %>%
  select(!patient_id) %>%
  mutate(diagnosis = rowSums(!is.na(.))) 

# Record cohort ----------------------------------------------------------------
print('Record cohort')

df$cohort <- cohort

# Save diagnosis date data -----------------------------------------------------
print('Save diagnosis date data')

readr::write_csv(df, paste0("output/not-for-review/dementia_diagnosis_dates_", cohort,".csv"))

# Group diagnosis counts -------------------------------------------------------
print('Group diagnosis counts')

df <- df %>%
  select(-cohort) %>% 
  group_by(diagnosis) %>% count() %>%
  rename_with(~ paste0(c("diagnosis_count_", "n_"), cohort), .cols = c(diagnosis, n))

# Save diagnosis count data ----------------------------------------------------
print('Save grouped diagnosis count data')

readr::write_csv(df, paste0("output/dementias_diagnosis_", cohort,".csv"))

# Perform redaction ------------------------------------------------------------
print('Perform redaction')

df[, setdiff(colnames(df), paste0(c("diagnosis_count_", "n_"), cohort))] <- lapply(df[,setdiff(colnames(df), paste0(c("diagnosis_count_", "n_"), cohort))],
                                                 FUN=function(y){roundmid_any(as.numeric(y), to = threshold)})

# Save rounded AER input -------------------------------------------------------
print('Save rounded AER input')

readr::write_csv(df, paste0("output/dementias_diagnosis_", cohort,"_rounded.csv"))
