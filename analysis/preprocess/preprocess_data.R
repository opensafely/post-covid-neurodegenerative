# Load libraries ---------------------------------------------------------------

library(magrittr)
library(dplyr)
library(tidyverse)
library(lubridate)
library(data.table)
library(readr)

# Specify command arguments ----------------------------------------------------

args <- commandArgs(trailingOnly=TRUE)
print(length(args))
if(length(args)==0){
  cohort_name <- "prevax"
} else {
  cohort_name <- args[[1]]
}

# Get column names -------------------------------------------------------------

all_cols <- fread(paste0("output/input_",cohort_name,".csv.gz"), 
                  header = TRUE, sep = ",", nrows = 0, 
                  stringsAsFactors = FALSE) %>%
  names()

message("Column names found")

print(all_cols)

# Identify column classes ------------------------------------------------------

cat_cols <- c("patient_id", grep("_cat", all_cols, value = TRUE))

bin_cols <- c(grep("_bin", all_cols, value = TRUE))

num_cols <- c(grep("_num", all_cols, value = TRUE),
              grep("vax_jcvi_age_", all_cols, value = TRUE))

date_cols <- grep("_date", all_cols, value = TRUE)

message("Column classes identified")

# Define column classes --------------------------------------------------------

col_classes <- setNames(
  c(rep("c", length(cat_cols)),
    rep("l", length(bin_cols)),
    rep("d", length(num_cols)),
    rep("D", length(date_cols))
  ), 
  all_cols[match(c(cat_cols, bin_cols, num_cols, date_cols), all_cols)]
)

message("Column classes defined")

# Read cohort dataset ---------------------------------------------------------- 

df <- read_csv(paste0("output/input_",cohort_name,".csv.gz"), 
               col_types = col_classes)

message(paste0("Dataset has been read successfully with N = ", nrow(df), " rows"))

# Format columns ---------------------------------------------------------------

df <- df %>%
  mutate(across(all_of(date_cols),
                ~ floor_date(as.Date(., format="%Y-%m-%d"), unit = "days")),
         across(contains('_birth_year'), 
                ~ format(as.Date(., origin = "1970-01-01"), "%Y")))

# Overwrite vaccination information for dummy data and vax cohort only ---------

if(Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations") &&
   cohort_name %in% c("vax")) {
  source("analysis/preprocess/modify_dummy_vax_data.R")
  message("Vaccine information overwritten successfully")
}

# Describe data ----------------------------------------------------------------

sink(paste0("output/describe_",cohort_name,".txt"))
print(Hmisc::describe(df))
sink()
message ("Cohort ",cohort_name, " description written successfully!")

# Remove records with missing patient id ---------------------------------------

df <- df[!is.na(df$patient_id),]

message("All records with valid patient IDs retained.")

# Restrict columns and save analysis dataset -----------------------------------

df1 <- df %>% 
  select(patient_id,
         starts_with("index_date"),
         starts_with("end_date_"),
         contains("sub_"), # Subgroups
         contains("exp_"), # Exposures
         contains("out_"), # Outcomes
         contains("cov_"), # Covariates
         contains("inex_"), # Inclusion/exclusion
         contains("cens_"), # Censor
         contains("qa_"), # Quality assurance
         contains("vax_date_eligible"), # Vaccination eligibility
         contains("vax_date_"), # Vaccination dates and vax type 
         contains("vax_cat_") # Vaccination products
  )

df1[,colnames(df)[grepl("tmp_",colnames(df))]] <- NULL

# Save input -------------------------------------------------------------------

saveRDS(df1, file = paste0("output/input_",cohort_name,".rds"), compress = TRUE)
message(paste0("Input data saved successfully with N = ", nrow(df1), " rows"))

# Describe data ----------------------------------------------------------------

sink(paste0("output/describe_input_",cohort_name,"_stage0.txt"))
print(Hmisc::describe(df1))
sink()

# Restrict columns and save Venn diagram input dataset -------------------------

df2 <- df %>% select(starts_with(c("patient_id","tmp_out_date","out_date")))

# Describe data ----------------------------------------------------------------

sink(paste0("output/describe_venn_",cohort_name,".txt"))
print(Hmisc::describe(df2))
sink()

saveRDS(df2, file = paste0("output/venn_",cohort_name,".rds"), compress = TRUE)

message("Venn diagram data saved successfully")