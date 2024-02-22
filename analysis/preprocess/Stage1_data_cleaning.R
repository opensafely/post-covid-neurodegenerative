# Load libraries ---------------------------------------------------------------
print('Load libraries')

library(dplyr)
library(tictoc)
library(readr)
library(tidyr)
library(stringr)
library(ggplot2)
library(jsonlite)
library(here)
library(arrow)

# Specify redaction threshold --------------------------------------------------
print('Specify redaction threshold')

threshold <- 6

# Source common functions ------------------------------------------------------
print('Source common functions')

source("analysis/utility.R")

# Specify command arguments ----------------------------------------------------
args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  # use for interactive testing
  cohort <- "prevax"
  
} else {
  cohort <- args[[1]]
}

# Load json file containing vax study dates ------------------------------------
print('Load json file containing vax study dates')

study_dates <- fromJSON("output/study_dates.json")

# Specify relevant dates -------------------------------------------------------
print('Specify relevant dates')

vax_start_date <- as.Date(study_dates$vax1_earliest, format="%Y-%m-%d")
mixed_vax_threshold <- as.Date("2021-05-07")
start_date_delta <- as.Date(study_dates$delta_date, format="%Y-%m-%d")
end_date_delta <- as.Date(study_dates$omicron_date, format="%Y-%m-%d") 

# Load cohort data -------------------------------------------------------------
print('Load cohort data')

input <- read_rds(file.path("output", paste0("input_",cohort,".rds")))
print(paste0(cohort,  " cohort: ", nrow(input), " rows in the input file"))

# Rename date variables --------------------------------------------------------
print('Rename date variables')

input <- dplyr::rename(input, "index_date" = "index_date_cohort")

# Handle missing values --------------------------------------------------------
print('Handle missing values')

input$cov_cat_smoking_status <- replace(input$cov_cat_smoking_status, 
                                        is.na(input$cov_cat_smoking_status),
                                        "M")

input <- input %>% 
  mutate(cov_cat_region = as.character(cov_cat_region)) %>%
  mutate(cov_cat_region = replace_na(cov_cat_region, "Missing")) %>%
  mutate(cov_cat_region = as.factor(cov_cat_region))

# Set reference levels for factors ---------------------------------------------
print('Set reference levels for factors')

cat_factors <- colnames(input)[grepl("_cat_",colnames(input))]
input[,cat_factors] <- lapply(input[,cat_factors], function(x) factor(x, ordered = FALSE))

# Set reference level for variable: sub_cat_covid19_hospital -------------------
print('Set reference level for variable: sub_cat_covid19_hospital')

input$sub_cat_covid19_hospital <- ordered(input$sub_cat_covid19_hospital, 
                                          levels = c("non_hospitalised",
                                                     "hospitalised",
                                                     "no_infection"))

# Set reference level for variable: cov_cat_ethnicity --------------------------
print('Set reference level for variable: cov_cat_ethnicity')

levels(input$cov_cat_ethnicity) <- list("Missing" = "0", "White" = "1", 
                                        "Mixed" = "2", "South Asian" = "3", 
                                        "Black" = "4", "Other" = "5")

input$cov_cat_ethnicity <- ordered(input$cov_cat_ethnicity, 
                                   levels = c("White","Mixed",
                                              "South Asian","Black",
                                              "Other","Missing"))

# Set reference level for variable: cov_cat_deprivation ------------------------
print('Set reference level for variable: cov_cat_deprivation')

levels(input$cov_cat_deprivation)[levels(input$cov_cat_deprivation)==1 | levels(input$cov_cat_deprivation)==2] <- "1-2 (most deprived)"
levels(input$cov_cat_deprivation)[levels(input$cov_cat_deprivation)==3 | levels(input$cov_cat_deprivation)==4] <- "3-4"
levels(input$cov_cat_deprivation)[levels(input$cov_cat_deprivation)==5 | levels(input$cov_cat_deprivation)==6] <- "5-6"
levels(input$cov_cat_deprivation)[levels(input$cov_cat_deprivation)==7 | levels(input$cov_cat_deprivation)==8] <- "7-8"
levels(input$cov_cat_deprivation)[levels(input$cov_cat_deprivation)==9 | levels(input$cov_cat_deprivation)==10] <- "9-10 (least deprived)"

input$cov_cat_deprivation <- ordered(input$cov_cat_deprivation, 
                                     levels = c("1-2 (most deprived)","3-4","5-6","7-8","9-10 (least deprived)"))

# Set reference level for variable: cov_cat_region -----------------------------
print('Set reference level for variable: cov_cat_region')

input$cov_cat_region <- relevel(input$cov_cat_region, ref = "East")

# Set reference level for variable: cov_cat_smoking_status ---------------------
print('Set reference level for variable: cov_cat_smoking_status')

levels(input$cov_cat_smoking_status) <- list("Ever smoker" = "E", "Missing" = "M", "Never smoker" = "N", "Current smoker" = "S")
input$cov_cat_smoking_status <- ordered(input$cov_cat_smoking_status, levels = c("Never smoker","Ever smoker","Current smoker","Missing"))

# Set reference level for variable: cov_cat_sex --------------------------------
print('Set reference level for variable: cov_cat_sex')

levels(input$cov_cat_sex) <- list("Female" = "F", "Male" = "M")

input$cov_cat_sex <- relevel(input$cov_cat_sex, ref = "Female")

# Set reference level for variable: vax_cat_jcvi_group -------------------------
print('Set reference level for variable: vax_cat_jcvi_group')

input$vax_cat_jcvi_group <- ordered(input$vax_cat_jcvi_group, 
                                    levels = c("12","11","10",
                                               "09","08","07",
                                               "06","05","04",
                                               "03","02","01","99"))

# Set reference level for variable: vax_cat_product_*  -------------------------
print('Set reference level for variable: vax_cat_product_*')

vax_cat_product_factors <- colnames(input)[grepl("vax_cat_product_",colnames(input))]

input[,vax_cat_product_factors] <- lapply(input[,vax_cat_product_factors], 
                                          function(x) ordered(x, levels = c("Pfizer","AstraZeneca","Moderna")))

# Set reference level for binaries ---------------------------------------------
print('Set reference level for binaries')

bin_factors <- colnames(input)[grepl("cov_bin_",colnames(input))]

input[,bin_factors] <- lapply(input[,bin_factors], 
                              function(x) factor(x, levels = c("FALSE","TRUE")))

# Specify consort table --------------------------------------------------------
print('Specify consort table')

consort <- data.frame(Description = "Input",
                      N = nrow(input),
                      stringsAsFactors = FALSE)

# Quality assurance ------------------------------------------------------------

print('Quality assurance: Year of birth is after year of death or patient only has year of death')

input <- input[!((input$qa_num_birth_year > (format(input$death_date, format="%Y")) & 
                    is.na(input$qa_num_birth_year)== FALSE & is.na(input$death_date) == FALSE) | 
                   (is.na(input$qa_num_birth_year)== TRUE & is.na(input$death_date) == FALSE)),]

consort[nrow(consort)+1,] <- c("Quality assurance: Year of birth is after year of death or patient only has year of death",
                               nrow(input))

print('Quality assurance: Year of birth is before 1793 or year of birth exceeds current date')

input <- input[!((input$qa_num_birth_year < 1793 | 
                    (input$qa_num_birth_year >format(Sys.Date(),"%Y"))) & 
                   is.na(input$qa_num_birth_year) == FALSE),]

consort[nrow(consort)+1,] <- c("Quality assurance: Year of birth is before 1793 or year of birth exceeds current date",
                               nrow(input))

print('Quality assurance: Date of death is NULL or invalid (on or before 1/1/1900 or after current date)')

input <- input[!((input$death_date <= as.Date(study_dates$earliest_expec) | 
                    input$death_date > format(Sys.Date(),"%Y-%m-%d")) & is.na(input$death_date) == FALSE),]

consort[nrow(consort)+1,] <- c("Quality assurance: Date of death is NULL or invalid (on or before 1/1/1900 or after current date)",
                               nrow(input))

print('Quality assurance: Pregnancy/birth codes for men')

input <- input[!(input$qa_bin_pregnancy == TRUE & input$cov_cat_sex=="Male"),]

consort[nrow(consort)+1,] <- c("Quality assurance: Pregnancy/birth codes for men",
                               nrow(input))

print('Quality assurance: HRT or COCP meds for men')

#input <- input[!(input$cov_cat_sex=="Male" & input$qa_bin_hrtcocp==TRUE),]
# input <- input[!(input$cov_cat_sex == "Male" & (input$cov_bin_combined_oral_contraceptive_pill | input$cov_bin_hormone_replacement_therapy) == TRUE),]
input <- input[!(input$cov_cat_sex == "Male" & (as.logical(input$cov_bin_combined_oral_contraceptive_pill) | as.logical(input$cov_bin_hormone_replacement_therapy))), ]

consort[nrow(consort)+1,] <- c("Quality assurance: HRT or COCP meds for men",
                               nrow(input))

print('Quality assurance: Prostate cancer codes for women')

input <- input[!(input$qa_bin_prostate_cancer == TRUE & 
                   input$cov_cat_sex=="Female"),]

consort[nrow(consort)+1,] <- c("Quality assurance: Prostate cancer codes for women",
                               nrow(input))

# Inclusion criteria -----------------------------------------------------------

print('Inclusion criteria: Alive on the first day of follow up')

input <- input %>% filter(index_date < death_date | is.na(death_date))

consort[nrow(consort)+1,] <- c("Inclusion criteria: Alive on the first day of follow up",
                               nrow(input))

print('Inclusion criteria: Known age 18 or over on 01/06/2021')

input <- subset(input, input$cov_num_age >= 18) # Subset input if age between 18 and 110 on 01/06/2021.
consort[nrow(consort)+1,] <- c("Inclusion criteria: Known age 18 or over on 01/06/2021",
                               nrow(input))

print('Inclusion criteria: Known age 110 or under on 01/06/2021')

input <- subset(input, input$cov_num_age <= 110) # Subset input if age between 18 and 110 on 01/06/2021.
consort[nrow(consort)+1,] <- c("Inclusion criteria: Known age 110 or under on 01/06/2021",
                               nrow(input))

print('Inclusion criteria: Known sex')

input <- input[!is.na(input$cov_cat_sex),] # removes NAs, if any
consort[nrow(consort)+1,] <- c("Inclusion criteria: Known sex",
                               nrow(input))

print('Inclusion criteria: Known deprivation')

input <- input[!is.na(input$cov_cat_deprivation),] # removes NAs, if any
consort[nrow(consort)+1,] <- c("Inclusion criteria: Known deprivation",
                               nrow(input))

print('Inclusion criteria: Six months follow up prior to index')

input <- subset(input, input$has_follow_up_previous_6months == TRUE)
consort[nrow(consort)+1,] <- c("Inclusion criteria: Six months follow up prior to index",
                               nrow(input))

print('Inclusion criteria: Active registration') 
input <- input %>% 
  filter(is.na(deregistration_date) | (!is.na(deregistration_date) & deregistration_date>=index_date)) 
consort[nrow(consort)+1,] <- c("Inclusion criteria: Active registration", nrow(input)) 

print('Inclusion criteria: Known region')

input <- input %>% mutate(cov_cat_region = as.character(cov_cat_region)) %>%
  filter(cov_cat_region != "Missing")%>%
  mutate(cov_cat_region = as.factor(cov_cat_region))

input$cov_cat_region <- relevel(input$cov_cat_region, ref = "East")

consort[nrow(consort)+1,] <- c("Inclusion criteria: Known region",
                               nrow(input))

# Apply cohort specific inclusion criteria -------------------------------------
print('Apply cohort specific inclusion criteria')

if (cohort == "vax") {
  
  print('Inclusion criteria: Record of two vaccination doses prior to the study end date')
  
  input$vax_gap <- input$vax_date_covid_2 - input$vax_date_covid_1 #Determine the vaccination gap in days : gap is NA if any vaccine date is missing
  input <- input[!is.na(input$vax_gap),] # Subset the fully vaccinated group
  consort[nrow(consort)+1,] <- c("Inclusion criteria: Record of two vaccination doses prior to the study end date",
                                 nrow(input))
  
  print('Inclusion criteria: Did not receive a vaccination prior to 08-12-2020 (i.e., the start of the vaccination program)')
  
  input <- subset(input, input$vax_date_covid_1 >= vax_start_date&input$vax_date_covid_2 >= vax_start_date)
  consort[nrow(consort)+1,] <- c("Inclusion criteria: Did not receive a vaccination prior to 08-12-2020 (i.e., the start of the vaccination program)",
                                 nrow(input))
  
  print('Inclusion criteria: Did not recieve a second dose vaccination before their first dose vaccination')
  
  input <- subset(input, input$vax_gap >= 0) # Keep those with positive vaccination gap
  consort[nrow(consort)+1,] <- c("Inclusion criteria: Did not recieve a second dose vaccination before their first dose vaccination",
                                 nrow(input))
  
  print('Inclusion criteria: Did not recieve a second dose vaccination less than three weeks after their first dose')
  
  input <- subset(input, input$vax_gap >= 21) # Keep those with at least 3 weeks vaccination gap
  consort[nrow(consort)+1,] <- c("Inclusion criteria: Did not recieve a second dose vaccination before their first dose vaccination",
                                 nrow(input))
  
  print('Inclusion criteria: Did not recieve a mixed vaccine products before 07-05-2021')
  
  # Trick to run the mixed vaccine code on dummy data with limited levels -> To ensure that the levels are the same in vax_cat_product variables
  
  input <- input %>%
    mutate(AZ_date = ifelse(vax_date_AstraZeneca_1 < mixed_vax_threshold, 1,
                            ifelse(vax_date_AstraZeneca_2 < mixed_vax_threshold, 1,
                                   ifelse(vax_date_AstraZeneca_3 < mixed_vax_threshold, 1, 0)))) %>%
    mutate(Moderna_date = ifelse(vax_date_Moderna_1 < mixed_vax_threshold, 1,
                                 ifelse(vax_date_Moderna_2 < mixed_vax_threshold, 1,
                                        ifelse(vax_date_Moderna_3 < mixed_vax_threshold, 1, 0)))) %>%
    mutate(Pfizer_date = ifelse(vax_date_Pfizer_1 < mixed_vax_threshold, 1,
                                ifelse(vax_date_Pfizer_2 < mixed_vax_threshold, 1,
                                       ifelse(vax_date_Pfizer_3 < mixed_vax_threshold, 1, 0)))) %>%
    rowwise() %>%
    mutate(vax_mixed = sum(across(c("AZ_date", "Moderna_date", "Pfizer_date")), na.rm = T)) %>%
    dplyr::filter(vax_mixed < 2)
  
  consort[nrow(consort)+1,] <- c("Inclusion criteria: Did not recieve a mixed vaccine products before 07-05-2021",
                                 nrow(input))
  
  print('Inclusion criteria: Index date is before cohort end date')
  
  # Will remove anyone who is not fully vaccinated by the cohort end date
  
  input <- input %>% filter (!is.na(index_date) & index_date <= end_date_exposure & index_date >= start_date_delta)
  consort[nrow(consort)+1,] <- c("Inclusion criteria: Index date is before cohort end date",
                                 nrow(input))
  
} else if (cohort %in% c("unvax")){
  
  print('Inclusion criteria: Does not have a record of one or more vaccination prior index date')
  
  # i.e. Have a record of a first vaccination prior to index date
  # (no more vax 2 and 3 variables available in this dataset)
  # a.Determine the vaccination status on index start date
  print(summary(input$cov_num_age))
  input$prior_vax1 <- ifelse(input$vax_date_covid_1 <= input$index_date, 1,0)
  input$prior_vax1[is.na(input$prior_vax1)] <- 0
  input <- subset(input, input$prior_vax1 == 0) # Exclude people with prior vaccination
  consort[nrow(consort)+1,] <- c("Inclusion criteria: Does not have a record of one or more vaccination prior index date",
                                 nrow(input))
  print("age check\n")                                
  print(summary(input$cov_num_age))
  print(sum(input$cov_num_age > 59))
  
  # print('Inclusion criteria: Not missing JCVI group')
  
  jcvi_cat <- c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12")
  
  input <- input %>%
    dplyr::filter(vax_cat_jcvi_group %in% jcvi_cat)
  consort[nrow(consort)+1,] <- c("Inclusion criteria: Not missing JCVI group",
                                 nrow(input))
  print(summary(input$cov_num_age))
  print(sum(input$cov_num_age > 59))
  print('Inclusion criteria: Index date is not before cohort end date - will remove anyone whose eligibility date + 84 days is after study end date (only those with unknown JCVI group)')
  
  input <- input %>% filter (!is.na(index_date) & index_date <= end_date_exposure & index_date >= start_date_delta)
  consort[nrow(consort)+1,] <- c("Inclusion criteria: Index date is not before cohort end date - will remove anyone whose eligibility date + 84 days is after study end date (only those with unknown JCVI group)",
                                 nrow(input))
  
}

#Apply outcome specific exclusions criteria
#-------------------------------------------------#

# Save consort data ------------------------------------------------------------
print('Save consort data')

consort$N <- as.numeric(consort$N)

consort$removed <- dplyr::lag(consort$N, default = dplyr::first(consort$N)) - consort$N

write.csv(consort, 
          file = paste0("output/consort_",cohort, ".csv"), 
          row.names=F)

# Perform redaction ------------------------------------------------------------
print('Perform redaction')

consort$removed <- NULL
consort$N <- roundmid_any(consort$N, to=threshold)
consort$removed <- dplyr::lag(consort$N, default = dplyr::first(consort$N)) - consort$N
names(consort)[names(consort) == "N"] <- "N_midpoint6"
names(consort)[names(consort) == "removed"] <- "removed_midpoint6_derived"

# Save rounded consort data ----------------------------------------------------
print('Save rounded consort data ')

write.csv(consort, 
          file = paste0("output/consort_",cohort, "_midpoint6.csv"), 
          row.names=F)

# Save stage 1 dataset ---------------------------------------------------------
print('Save stage 1 dataset')

input <- input[,c("patient_id","death_date","index_date",
                  colnames(input)[grepl("end_date_",colnames(input))],
                  colnames(input)[grepl("sub_",colnames(input))],
                  colnames(input)[grepl("exp_",colnames(input))],
                  colnames(input)[grepl("out_",colnames(input))],
                  colnames(input)[grepl("cov_",colnames(input))],
                  colnames(input)[grepl("vax_date_",colnames(input))],
                  colnames(input)[grepl("vax_cat_",colnames(input))])]

saveRDS(input, 
        file = paste0("output/input_",cohort,"_stage1.rds"), 
        compress = TRUE)
