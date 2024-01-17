# Load libraries ---------------------------------------------------------------
tictoc::tic()
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
  # use for interactive testing
  cohort_name <- "prevax"
} else {
  cohort_name <- args[[1]]
}

fs::dir_create(here::here("output", "not-for-review"))

#data set

input_path <- paste0("output/input_",cohort_name,".csv.gz")

# Get column names -------------------------------------------------------------

all_cols <- fread(paste0("output/input_",cohort_name,".csv.gz"),
                  header = TRUE,
                  sep = ",",
                  nrows = 0,
                  stringsAsFactors = FALSE) %>%
  names()

#Get columns types based on their names

cat_cols <- c("patient_id", grep("_cat", all_cols, value = TRUE))
bin_cols <- c(grep("_bin", all_cols, value = TRUE),
              grep("prostate_cancer_", all_cols, value = TRUE),
              "has_follow_up_previous_6months", "has_died", "registered_at_start")
num_cols <- c(grep("_num", all_cols, value = TRUE),
              grep("vax_jcvi_age_", all_cols, value = TRUE))
date_cols <- grep("_date", all_cols, value = TRUE)

# Set the class of the columns with match to make sure the column match the type

col_classes <- setNames(
  c(rep("c", length(cat_cols)),
    rep("l", length(bin_cols)),
    rep("d", length(num_cols)),
    rep("D", length(date_cols))
  ),
  all_cols[match(c(cat_cols, bin_cols, num_cols, date_cols), all_cols)]
)

# read the input file and specify colClasses -----------------------------------

df <- read_csv(input_path, col_types = col_classes)

print(paste0("Dataset has been read successfully with N = ", nrow(df), " rows"))
print("type of columns:\n")

# Describe data ----------------------------------------------------------------

sink(paste0("output/not-for-review/describe_",cohort_name,".txt"))
print(Hmisc::describe(df))
print(str(df))
sink()

message ("Cohort ",cohort_name, " description written successfully!")

# Add death_date from prelim data ----------------------------------------------

prelim_data <- read_csv("output/index_dates.csv.gz",col_types=cols(patient_id = "c",death_date="D")) %>%
  select(patient_id,death_date)
df <- df %>% inner_join(prelim_data,by="patient_id")

message("Death date added!")
message(paste0("After adding death N = ", nrow(df), " rows"))

# Format columns ---------------------------------------------------------------
# dates, numerics, factors, logicals

df <- df %>%
  mutate( across(contains('_birth_year'),
                 ~ format(as.Date(.,origin='1970-01-01'), "%Y")),
          across(contains('_num') & !contains('date'), ~ as.numeric(.)),
          across(contains('_cat'), ~ as.factor(.)),
          across(contains('_bin'), ~ as.logical(.)))

# Overwrite vaccination information for dummy data and vax cohort only ---------

if(Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations") &&
   cohort_name %in% c("vax")) {
  source("analysis/preprocess/modify_dummy_vax_data.R")
  message("Vaccine information overwritten successfully")
}

#Combine BMI variables to create one history of obesity variable ---------------

df$cov_bin_obesity <- ifelse(df$cov_bin_obesity == TRUE | 
                               df$cov_cat_bmi_groups=="Obese",TRUE,FALSE)

# drop BMI variables 

df$cov_num_bmi_date_measured <- NULL
df$cov_num_bmi <- NULL
df$cov_cat_bmi_groups <- NULL

# QC for consultation variable--------------------------------------------------
#max to 365 (average of one per day)
df <- df %>%
  mutate(cov_num_consulation_rate = replace(cov_num_consulation_rate, 
                                            cov_num_consulation_rate > 365, 365))

# Define COVID-19 severity -----------------------------------------------------

df <- df %>%
  mutate(sub_cat_covid19_hospital = 
           ifelse(!is.na(exp_date_covid19_confirmed) &
                    !is.na(sub_date_covid19_hospital) &
                    sub_date_covid19_hospital - exp_date_covid19_confirmed >= 0 &
                    sub_date_covid19_hospital - exp_date_covid19_confirmed < 29, "hospitalised",
                  ifelse(!is.na(exp_date_covid19_confirmed), "non_hospitalised", 
                         ifelse(is.na(exp_date_covid19_confirmed), "no_infection", NA)))) %>%
  mutate(across(sub_cat_covid19_hospital, factor))

df <- df[!is.na(df$patient_id),]
df[,c("sub_date_covid19_hospital")] <- NULL

message("COVID19 severity determined successfully")

# Create vars for neurodegenerative outcomes - TBC -------------------------------------------------------------

# Rename cov_bin_chronic_obstructive_pulmonary_disease

df <- df %>%
  rename(cov_bin_copd = cov_bin_chronic_obstructive_pulmonary_disease,
         cov_bin_ckd = cov_bin_chronic_kidney_disease,
         cov_bin_history_cog_imp_sympt = cov_bin_history_cognitive_impairment_symptoms,
         cov_bin_history_mnd = cov_bin_history_motor_neurone_disease,
         cov_bin_history_parkinson = cov_bin_history_parkinson_disease,
         cov_bin_history_ms = cov_bin_history_multiple_sclerosis,
         cov_bin_history_parkinson_risk = cov_bin_history_parkison_risk_conditions)

# High vascular risk -----------------------------------------------------------

df <- df %>%
  mutate(sub_bin_high_vascular_risk = case_when(cov_bin_hypertension == FALSE & cov_bin_diabetes == FALSE ~ FALSE,
                                                cov_bin_hypertension == FALSE & cov_bin_diabetes == TRUE ~ TRUE,
                                                cov_bin_hypertension == TRUE & cov_bin_diabetes == FALSE ~ TRUE,
                                                cov_bin_hypertension == TRUE & cov_bin_diabetes == TRUE ~ TRUE))

# Restrict columns and save analysis dataset ---------------------------------

df1 <- df%>% select(patient_id,"death_date",starts_with("index_date_"),
                    has_follow_up_previous_6months,
                    dereg_date,
                    starts_with("end_date_"),
                    contains("sub_"), # Subgroups
                    contains("exp_"), # Exposures
                    contains("out_"), # Outcomes
                    contains("cov_"), # Covariates
                    contains("qa_"), # Quality assurance
                    contains("vax_date_eligible"), # Vaccination eligibility
                    contains("vax_date_"), # Vaccination dates and vax type 
                    contains("vax_cat_") # Vaccination products
) %>% 
  select(-matches("tmp_"))

# Repo specific preprocessing 

saveRDS(df1, file = paste0("output/input_",cohort_name,".rds"), compress = "gzip")

message(paste0("Input data saved successfully with N = ", nrow(df1), " rows"))

# Describe data --------------------------------------------------------------

sink(paste0("output/not-for-review/describe_input_",cohort_name,"_stage0.txt"))
print(Hmisc::describe(df1))
sink()
#rm(df1)
gc()

# Restrict columns and save Venn diagram input dataset -----------------------

df2 <- df %>% select(starts_with(c("patient_id","tmp_out_date","out_date")))
#rm(df)
gc()

message(paste0("Input data saved successfully with N = ", nrow(df1), " rows"))

# Describe venn ----------------------------------------------------------------

sink(paste0("output/not-for-review/describe_venn_",cohort_name,".txt"))
print(Hmisc::describe(df2))
sink()

# SAVE

saveRDS(df2, file = paste0("output/venn_",cohort_name,".rds"))

message("Venn diagram data saved successfully")
tictoc::toc() 