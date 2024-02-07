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
  cohort <- "prevax"
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

df$exposed <- !is.na(df$exp_date_covid19_confirmed)

# Define consultation rate groups ----------------------------------------------
print("Define consultation rate groups")

df$cov_cat_consulation_rate <- ""
df$cov_cat_consulation_rate <- ifelse(df$cov_num_consulation_rate==0, "0", df$cov_cat_consulation_rate)
df$cov_cat_consulation_rate <- ifelse(df$cov_num_consulation_rate>=1 & df$cov_num_consulation_rate<=5, "1-5", df$cov_cat_consulation_rate)
df$cov_cat_consulation_rate <- ifelse(df$cov_num_consulation_rate>=6, "6+", df$cov_cat_consulation_rate)

# Filter data ------------------------------------------------------------------
print("Filter data")

vars <- setdiff(c(colnames(df)[grepl("cov_cat_",colnames(df))], 
                  colnames(df)[grepl("cov_bin_",colnames(df))]),
                c("cov_cat_sex",
                  "cov_cat_ethnicity",
                  "cov_cat_deprivation",
                  "cov_cat_smoking_status",
                  "cov_cat_region",
                  "cov_bin_carehome_status"))

df <- df[,c("patient_id", "exposed", vars)]

df$All <- "All"

# Aggregate data ---------------------------------------------------------------
print("Aggregate data")

df <- tidyr::pivot_longer(df,
                          cols = setdiff(colnames(df),c("patient_id","exposed")),
                          names_to = "characteristic",
                          values_to = "subcharacteristic")

df$total <- 1

df <- aggregate(cbind(total, exposed) ~ characteristic + subcharacteristic, 
                data = df,
                sum)

df <- df[df$subcharacteristic!=FALSE,]
df$subcharacteristic <- ifelse(df$subcharacteristic=="","Missing",df$subcharacteristic)


# Sort data --------------------------------------------------------------------
print("Sort data")

df <- df[order(df$subcharacteristic, decreasing = TRUE),]
df <- df[order(df$characteristic),]

# Save Table 1 -----------------------------------------------------------------
print('Save Table 1')

write.csv(df, paste0("output/extendedtable1_",cohort,".csv"), row.names = FALSE)

# Perform redaction ------------------------------------------------------------
print('Perform redaction')

df[,setdiff(colnames(df),c("characteristic","subcharacteristic"))] <- lapply(df[,setdiff(colnames(df),c("characteristic","subcharacteristic"))],
                                                                             FUN=function(y){roundmid_any(as.numeric(y), to=threshold)})

# Calculate column percentages -------------------------------------------------

df$Npercent <- paste0(df$total,ifelse(df$characteristic=="All","",
                                      paste0(" (",round(100*(df$total / df[df$characteristic=="All","total"]),1),"%)")))

df <- df[,c("characteristic","subcharacteristic","Npercent","exposed")]
colnames(df) <- c("Characteristic","Subcharacteristic","N (%) derived","COVID-19 diagnoses midpoint6")

# Save Table 1 -----------------------------------------------------------------
print('Save rounded Table 1')

write.csv(df, paste0("output/extendedtable1_",cohort,"_midpoint6.csv"), row.names = FALSE)