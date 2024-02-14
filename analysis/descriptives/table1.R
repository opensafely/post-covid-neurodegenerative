# Load libraries ---------------------------------------------------------------
print('Load libraries')

library(magrittr)
library(dplyr)

# Specify redaction threshold --------------------------------------------------
print('Specify redaction threshold')

threshold <- 6

# Source common functions ------------------------------------------------------
print('Source common functions')

source("analysis/utility.R")

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  cohort <- "vax"
} else {
  cohort <- args[[1]]
}


# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_rds(paste0("output/input_",cohort,"_stage1.rds"))

# Format columns ---------------------------------------------------------------
# dates, numerics, factors, logicals

df <- df %>%
  mutate(sub_bin_covid19_confirmed_history = as.factor(sub_bin_covid19_confirmed_history),
                sub_bin_high_vascular_risk = as.factor(sub_bin_high_vascular_risk))

# Create exposure indicator ----------------------------------------------------
print("Create exposure indicator")

df$exposed <- !is.na(df$exp_date_covid19_confirmed)

# Define age groups ------------------------------------------------------------
print("Define age groups")

df$cov_cat_age_group <- ""
df$cov_cat_age_group <- ifelse(df$cov_num_age>=18 & df$cov_num_age<=39, "18-39", df$cov_cat_age_group)
df$cov_cat_age_group <- ifelse(df$cov_num_age>=40 & df$cov_num_age<=64, "40-64", df$cov_cat_age_group)
df$cov_cat_age_group <- ifelse(df$cov_num_age>=65 & df$cov_num_age<=84, "65-84", df$cov_cat_age_group)
df$cov_cat_age_group <- ifelse(df$cov_num_age>=85, "85+", df$cov_cat_age_group)

# Define consultation rate groups ----------------------------------------------
print("Define consultation rate groups")

df$cov_cat_consulation_rate <- ""
df$cov_cat_consulation_rate <- ifelse(df$cov_num_consulation_rate==0, "0", df$cov_cat_consulation_rate)
df$cov_cat_consulation_rate <- ifelse(df$cov_num_consulation_rate>=1 & df$cov_num_consulation_rate<=5, "1-5", df$cov_cat_consulation_rate)
df$cov_cat_consulation_rate <- ifelse(df$cov_num_consulation_rate>=6, "6+", df$cov_cat_consulation_rate)

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[,c("patient_id",
            "exposed",
            "cov_cat_sex",
            "cov_cat_age_group",
            "cov_cat_ethnicity",
            "cov_cat_deprivation",
            "cov_cat_smoking_status",
            "cov_cat_region",
            "cov_bin_carehome_status",
            "cov_cat_consulation_rate",
            "cov_bin_healthcare_worker",
            "cov_bin_liver_disease",
            "cov_bin_ckd",
            "cov_bin_cancer",
            "cov_bin_hypertension",
            "cov_bin_diabetes",
            "cov_bin_obesity",
            "cov_bin_copd",
            "cov_bin_ami",
            "cov_bin_isch",
            "sub_bin_covid19_confirmed_history", 
            "sub_bin_high_vascular_risk", 
            "cov_bin_history_cog_imp_sympt",
            "cov_bin_history_mnd",
            "cov_bin_history_migraine",
            "cov_bin_history_any_dementia",
            "cov_bin_history_parkinson",
            "cov_bin_history_ms",
            "cov_bin_history_parkinson_risk")]

df$All <- "All"

# Aggregate data ---------------------------------------------------------------
print("Aggregate data")

df <- tidyr::pivot_longer(df,
                          cols = setdiff(colnames(df), c("patient_id","exposed")),
                          names_to = "characteristic",
                          values_to = "subcharacteristic")

df$total <- 1

df <- aggregate(cbind(total, exposed) ~ characteristic + subcharacteristic, 
                data = df,
                sum)

df$subcharacteristic <- ifelse(df$subcharacteristic == "", "Missing", df$subcharacteristic)

# Sort characteristics ---------------------------------------------------------
print("Sort characteristics")

df$characteristic <- factor(df$characteristic,
                            levels = c("All",
                                       "cov_cat_sex",
                                       "cov_cat_age_group",
                                       "cov_cat_ethnicity",
                                       "cov_cat_deprivation",
                                       "cov_cat_smoking_status",
                                       "cov_cat_region",
                                       "cov_bin_carehome_status",
                                       "cov_cat_consulation_rate",
                                       "cov_bin_healthcare_worker",
                                       "cov_bin_liver_disease",
                                       "cov_bin_ckd",
                                       "cov_bin_cancer",
                                       "cov_bin_hypertension",
                                       "cov_bin_diabetes",
                                       "cov_bin_obesity",
                                       "cov_bin_copd",
                                       "cov_bin_ami",
                                       "cov_bin_isch",
                                       "sub_bin_covid19_confirmed_history", 
                                       "sub_bin_high_vascular_risk", 
                                       "cov_bin_history_cog_imp_sympt",
                                       "cov_bin_history_mnd",
                                       "cov_bin_history_migraine",
                                       "cov_bin_history_any_dementia",
                                       "cov_bin_history_parkinson",
                                       "cov_bin_history_ms",
                                       "cov_bin_history_parkinson_risk"),
                            labels = c("All",
                                       "Sex",
                                       "Age, years",
                                       "Ethnicity",
                                       "Index of multiple deprivation quintile",
                                       "Smoking status",
                                       "Region",
                                       "Care home resident",
                                       "Consultation rate",
                                       "Health care worker",
                                       "Liver disease",
                                       "Chronic kidney disease",
                                       "Cancer",
                                       "Hypertension",
                                       "Diabetes",
                                       "Obesity",
                                       "Chronic obstructive pulmonary disease (COPD)",
                                       "Acute myocardial infarction",
                                       "Ischaemic stroke",
                                       "History of COVID-19",
                                       "History of High vascular risk",
                                       "History of cognitive impairment",
                                       "History of motor neurone disease",
                                       "History of migraine",
                                       "History of any dementia",
                                       "History of Parkinson's disease",
                                       "History of multiple sclerosis",
                                       "History of Parkinson's disease risk")) 

# Sort subcharacteristics ------------------------------------------------------
print("Sort subcharacteristics")

df$subcharacteristic <- factor(df$subcharacteristic, 
                               levels = c("All",
                                          "Female",
                                          "Male",
                                          "18-39",
                                          "40-64",
                                          "65-84",
                                          "85+",
                                          "White",
                                          "Mixed",
                                          "South Asian",
                                          "Black",
                                          "Other",
                                          "Missing",
                                          "1-2 (most deprived)",
                                          "3-4",
                                          "5-6",
                                          "7-8",
                                          "9-10 (least deprived)",
                                          "Never smoker",
                                          "Ever smoker",
                                          "Current smoker",
                                          "East",
                                          "East Midlands",
                                          "London",
                                          "North East",
                                          "North West",
                                          "South East",
                                          "South West",
                                          "West Midlands",
                                          "Yorkshire and The Humber",
                                          "Care home resident",
                                          "0",
                                          "1-5",
                                          "6+",
                                          "Healthcare worker",
                                          "TRUE", "FALSE", "TRUE", "FALSE",
                                          "TRUE", "FALSE", "TRUE", "FALSE", 
                                          "TRUE", "FALSE", "TRUE", "FALSE", 
                                          "TRUE", "FALSE", "TRUE", "FALSE", 
                                          "TRUE", "FALSE", "TRUE", "FALSE", 
                                          "TRUE", "FALSE", "TRUE", "FALSE",
                                          "TRUE", "FALSE", "TRUE", "FALSE",
                                          "TRUE", "FALSE", "TRUE", "FALSE",
                                          "TRUE", "FALSE", "TRUE", "FALSE",
                                          "Missing"),
                               labels = c("All",
                                          "Female",
                                          "Male",
                                          "18-39",
                                          "40-64",
                                          "65-84",
                                          "85+",
                                          "White",
                                          "Mixed",
                                          "South Asian",
                                          "Black",
                                          "Other",
                                          "Missing",
                                          "1: most deprived",
                                          "2",
                                          "3",
                                          "4",
                                          "5: least deprived",
                                          "Never smoker",
                                          "Former smoker",
                                          "Current smoker",
                                          "East",
                                          "East Midlands",
                                          "London",
                                          "North East",
                                          "North West",
                                          "South East",
                                          "South West",
                                          "West Midlands",
                                          "Yorkshire/Humber",
                                          "Care home resident",
                                          "0",
                                          "1-5",
                                          "6+",
                                          "Healthcare worker",
                                          "TRUE", "FALSE", "TRUE", "FALSE",
                                          "TRUE", "FALSE", "TRUE", "FALSE", 
                                          "TRUE", "FALSE", "TRUE", "FALSE", 
                                          "TRUE", "FALSE", "TRUE", "FALSE", 
                                          "TRUE", "FALSE", "TRUE", "FALSE", 
                                          "TRUE", "FALSE", "TRUE", "FALSE",
                                          "TRUE", "FALSE", "TRUE", "FALSE",
                                          "TRUE", "FALSE", "TRUE", "FALSE",
                                          "TRUE", "FALSE", "TRUE", "FALSE",
                                          "Missing")) 

# Sort data --------------------------------------------------------------------
print("Sort data")

df <- df[order(df$characteristic, df$subcharacteristic),]

# Save Table 1 -----------------------------------------------------------------
print('Save Table 1')

write.csv(df, paste0("output/table1_",cohort,".csv"), row.names = FALSE)

# Perform redaction ------------------------------------------------------------
print('Perform redaction')

df[,setdiff(colnames(df),c("characteristic","subcharacteristic"))] <- lapply(df[,setdiff(colnames(df),c("characteristic","subcharacteristic"))],
                                                                             FUN=function(y){roundmid_any(as.numeric(y), to=threshold)})

# Calculate column percentages -------------------------------------------------

df$Npercent <- paste0(df$total,ifelse(df$characteristic=="All","",
                                      paste0(" (",round(100*(df$total_midpoint6 / df[df$characteristic=="All","total"]),1),"%)")))

# Rename columns (output redaction) --------------------------------------------

df <- df[,c("characteristic","subcharacteristic","Npercent","exposed")]
colnames(df) <- c("Characteristic","Subcharacteristic","N (%) midpoint6 derived","COVID-19 diagnoses midpoint6")

# Save Table 1 -----------------------------------------------------------------
print('Save rounded Table 1')

write.csv(df, paste0("output/table1_",cohort,"_midpoint6.csv"), row.names = FALSE)