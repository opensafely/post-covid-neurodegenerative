# Load libraries ---------------------------------------------------------------
tictoc::tic()
library(magrittr)
library(dplyr)
library(tidyverse)
library(lubridate)

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
fs::dir_create(here::here("output", "review"))

# Read cohort dataset ---------------------------------------------------------- 

df <- readr::read_csv(file = paste0("output/input_",cohort_name,".csv.gz"))

message(paste0("Dataset has been read successfully with N = ", nrow(df), " rows"))

#Add death_date from prelim data
prelim_data <- read_csv("output/index_dates.csv.gz") %>%
  select(c(patient_id,death_date))
df <- df %>% inner_join(prelim_data,by="patient_id")

message("Death date added!")

# Format columns ---------------------------------------------------------------
# dates, numerics, factors, logicals

df <- df %>%
  mutate(across(c(contains("_date")),
                ~ floor_date(as.Date(., format="%Y-%m-%d", origin = "1970-01-01"), unit = "days")),
         across(contains('_birth_year'),
                ~ format(as.Date(., origin = "1970-01-01"), "%Y")),
         across(contains('_num') & !contains('date'), ~ as.numeric(.)),
         across(contains('_cat'), ~ as.factor(.)),
         across(contains('_bin'), ~ as.logical(.)))

# Overwrite vaccination information for dummy data and vax cohort only --

if(Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations") &&
   cohort_name %in% c("vax")) {
  source("analysis/preprocess/modify_dummy_vax_data.R")
  message("Vaccine information overwritten successfully")
}

# Describe data ----------------------------------------------------------------

sink(paste0("output/not-for-review/describe_",cohort_name,".txt"))
print(Hmisc::describe(df))
sink()

message ("Cohort ",cohort_name, " description written successfully!")

#Combine BMI variables to create one history of obesity variable ---------------

df$cov_bin_obesity <- ifelse(df$cov_bin_obesity == TRUE | 
                               df$cov_cat_bmi_groups=="Obese",TRUE,FALSE)

# QC for consultation variable--------------------------------------------------
#max to 365 (average of one per day)
df <- df %>%
  mutate(cov_num_consulation_rate = replace(cov_num_consulation_rate, 
                                            cov_num_consulation_rate > 365, 365))

# Define COVID-19 severity --------------------------------------------------------------

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
                    contains("step"), # diabetes steps
                    contains("vax_date_eligible"), # Vaccination eligibility
                    contains("vax_date_"), # Vaccination dates and vax type 
                    contains("vax_cat_")# Vaccination products
)

df1[,colnames(df)[grepl("tmp_",colnames(df))]] <- NULL

# Repo specific preprocessing 

saveRDS(df1, file = paste0("output/input_",cohort_name,".rds"), compress = "gzip")

message(paste0("Input data saved successfully with N = ", nrow(df1), " rows"))

# SAVE

saveRDS(df1, file = paste0("output/input_",cohort_name,".rds"))

print(paste0(cohort_name," ","Dataset saved successfully"))

# Describe data --------------------------------------------------------------

sink(paste0("output/not-for-review/describe_input_",cohort_name,"_stage0.txt"))
print(Hmisc::describe(df1))
sink()

# Restrict columns and save Venn diagram input dataset -----------------------

df2 <- df %>% select(starts_with(c("patient_id","tmp_out_date","out_date")))

# Describe data --------------------------------------------------------------

sink(paste0("output/not-for-review/describe_venn_",cohort_name,".txt"))
print(Hmisc::describe(df2))
sink()

saveRDS(df2, file = paste0("output/venn_",cohort_name,".rds"))

message("Venn diagram data saved successfully")
tictoc::toc() 