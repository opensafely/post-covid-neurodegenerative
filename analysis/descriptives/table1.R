# Load libraries ---------------------------------------------------------------
print('Load libraries')

library(magrittr)

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

# Remove people with history of COVID-19 ---------------------------------------
print("Remove people with history of COVID-19")

df <- df[df$sub_bin_covid19_confirmed_history==FALSE,]

# Create exposure indicator ----------------------------------------------------
print("Create exposure indicator")

df$exposed_midpoint6 <- !is.na(df$exp_date_covid19_confirmed)

# Define age groups ------------------------------------------------------------
print("Define age groups")

df$cov_cat_age_group <- ""
df$cov_cat_age_group <- ifelse(df$cov_num_age>=18 & df$cov_num_age<=29, "18-29", df$cov_cat_age_group)
df$cov_cat_age_group <- ifelse(df$cov_num_age>=30 & df$cov_num_age<=39, "30-39", df$cov_cat_age_group)
df$cov_cat_age_group <- ifelse(df$cov_num_age>=40 & df$cov_num_age<=49, "40-49", df$cov_cat_age_group)
df$cov_cat_age_group <- ifelse(df$cov_num_age>=50 & df$cov_num_age<=59, "50-59", df$cov_cat_age_group)
df$cov_cat_age_group <- ifelse(df$cov_num_age>=60 & df$cov_num_age<=69, "60-69", df$cov_cat_age_group)
df$cov_cat_age_group <- ifelse(df$cov_num_age>=70 & df$cov_num_age<=79, "70-79", df$cov_cat_age_group)
df$cov_cat_age_group <- ifelse(df$cov_num_age>=80 & df$cov_num_age<=89, "80-89", df$cov_cat_age_group)
df$cov_cat_age_group <- ifelse(df$cov_num_age>=90, "90+", df$cov_cat_age_group)

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[,c("patient_id",
            "exposed_midpoint6",
            "cov_cat_sex",
            "cov_cat_age_group",
            "cov_cat_ethnicity",
            "cov_cat_deprivation",
            "cov_cat_smoking_status",
            "cov_cat_region",
            "cov_bin_carehome_status")]

df$All <- "All"

# Aggregate data ---------------------------------------------------------------
print("Aggregate data")

df <- tidyr::pivot_longer(df,
                          cols = setdiff(colnames(df),c("patient_id","exposed_midpoint6")),
                          names_to = "characteristic",
                          values_to = "subcharacteristic")

df$total_midpoint6 <- 1

df <- aggregate(cbind(total_midpoint6, exposed_midpoint6) ~ characteristic + subcharacteristic, 
                data = df,
                sum)

# Tidy care home characteristic ------------------------------------------------
print("Remove extraneous information")

df <- df[!(df$characteristic=="cov_bin_carehome_status" & 
             df$subcharacteristic=="FALSE"),]

df$subcharacteristic <- ifelse(df$characteristic=="cov_bin_carehome_status",
                               "Care home resident",
                               df$subcharacteristic)

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
                                       "cov_bin_carehome_status"),
                            labels = c("All",
                                       "Sex",
                                       "Age, years",
                                       "Ethnicity",
                                       "Index of multiple deprivation quintile",
                                       "Smoking status",
                                       "Region",
                                       "Care home resident"))

# Sort subcharacteristics ------------------------------------------------------
print("Sort subcharacteristics")

df$subcharacteristic <- factor(df$subcharacteristic,
                               levels = c("All",
                                          "Female",
                                          "Male",
                                          "18-29",
                                          "30-39",
                                          "40-49",
                                          "50-59",
                                          "60-69",
                                          "70-79",
                                          "80-89",
                                          "90+",
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
                                          "Missing"),
                               labels = c("All",
                                          "Female",
                                          "Male",
                                          "18-29",
                                          "30-39",
                                          "40-49",
                                          "50-59",
                                          "60-69",
                                          "70-79",
                                          "80-89",
                                          "90+",
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
                                      paste0(" (",round(100*(df$total_midpoint6 / df[df$characteristic=="All","total_midpoint6"]),1),"%)")))

df <- df[,c("characteristic","subcharacteristic","Npercent","exposed_midpoint6")]
colnames(df) <- c("Characteristic","Subcharacteristic","N (%) derived","COVID-19 diagnoses midpoint6")

# Save Table 1 -----------------------------------------------------------------
print('Save rounded Table 1')

write.csv(df, paste0("output/table1_",cohort,"_midpoint6.csv"), row.names = FALSE)