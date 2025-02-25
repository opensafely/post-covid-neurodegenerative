# Load libraries ---------------------------------------------------------------
print("Load libraries")

library(magrittr)
library(here)

# Specify redaction threshold --------------------------------------------------
print("Specify redaction threshold")

threshold <- 6

# Source common functions ------------------------------------------------------
print("Source common functions")

source("analysis/utility.R")

# Specify arguments ------------------------------------------------------------
print("Specify arguments")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  cohort <- "vax"
} else {
  cohort <- args[[1]]
}


# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_rds(paste0("output/dataset_clean/input_", cohort, ".rds"))# "_stage1.rds"))

############################### MEDIAN_IQR_AGE #################################

if (!file.exists(here::here(paste0(table1_dir, "median_iqr_age.csv")))) {

  # Create empty output --------------------------------------------------------
  print('Create empty output')

  df_iqr <- data.frame(cohort = character(),
               median_iqr_age = character())

} else {

  df_iqr <- read.csv(paste0(table1_dir, "median_iqr_age.csv"), header = TRUE)
  df_iqr <- unique(df_iqr) # ensure it only has unique rows

}

# Calculate median (IQR) age -------------------------------------------------
print("Calculate median (IQR) age")

# if the row doesn't exist, create it. Otherwise, overwrite it
if (sum(df_iqr["cohort"] == cohort) == 0) {
  # Pastes: "Mean Age (LQ Age - UQ Age)" as a string for each cohort
  df_iqr[nrow(df_iqr)+1, ] <- c(cohort, paste0(quantile(df$cov_num_age)[3], " (", quantile(df$cov_num_age)[2], "-", quantile(df$cov_num_age)[4], ")"))
} else {
  df_iqr[df_iqr$cohort ==cohort, ] <- c(cohort, paste0(quantile(df$cov_num_age)[3], " (", quantile(df$cov_num_age)[2], "-", quantile(df$cov_num_age)[4], ")"))
}

# Save median (IQR) age --------------------------------------------------------
print("Save median (IQR) age")

df_iqr <- df_iqr[order(df_iqr$cohort), ]  # sort table into order
write.csv(df_iqr, paste0(table1_dir, "median_iqr_age.csv"), row.names = FALSE) # save

################################## TABLE 1 #####################################

print("Table 1 processing")

# Remove people with history of COVID-19 ---------------------------------------
print("Remove people with history of COVID-19")

df <- df[df$sub_bin_covidhistory == FALSE, ] # Previously sub_bin_covid19_confirmed_history

# Create exposure indicator ----------------------------------------------------
print("Create exposure indicator")

df$exposed <- !is.na(df$exp_date_covid) # Previously exp_date_covid19_confirmed

# Define age groups ------------------------------------------------------------
print("Define age groups")

# df$cov_cat_age_group <- ""
# df$cov_cat_age_group <- ifelse(df$cov_num_age >= 18 & df$cov_num_age <= 29, "18-29", df$cov_cat_age_group)
# df$cov_cat_age_group <- ifelse(df$cov_num_age >= 30 & df$cov_num_age <= 39, "30-39", df$cov_cat_age_group)
# df$cov_cat_age_group <- ifelse(df$cov_num_age >= 40 & df$cov_num_age <= 49, "40-49", df$cov_cat_age_group)
# df$cov_cat_age_group <- ifelse(df$cov_num_age >= 50 & df$cov_num_age <= 59, "50-59", df$cov_cat_age_group)
# df$cov_cat_age_group <- ifelse(df$cov_num_age >= 60 & df$cov_num_age <= 69, "60-69", df$cov_cat_age_group)
# df$cov_cat_age_group <- ifelse(df$cov_num_age >= 70 & df$cov_num_age <= 79, "70-79", df$cov_cat_age_group)
# df$cov_cat_age_group <- ifelse(df$cov_num_age >= 80 & df$cov_num_age <= 89, "80-89", df$cov_cat_age_group)
# df$cov_cat_age_group <- ifelse(df$cov_num_age >= 90, "90+", df$cov_cat_age_group)

# df$cov_cat_consrate2019 <- ""   # Previously cov_cat_consulation_rate
# df$cov_cat_consrate2019 <- ifelse(df$cov_num_consrate2019 == 0,   "0", df$cov_num_consrate2019) # Previously cov_num_consulation_rate
# df$cov_cat_consrate2019 <- ifelse(df$cov_num_consrate2019 >= 1
#                                 & df$cov_num_consrate2019 <= 5, "1-5", df$cov_num_consrate2019)
# df$cov_cat_consrate2019 <- ifelse(df$cov_num_consrate2019 >= 6,  "6+", df$cov_num_consrate2019)

# df$cov_cat_age_group <- numerical_to_categorical(df$cov_num_age,c(18,30,40,50,60,70,80,90),FALSE,FALSE,FALSE) # See utility.R
df$cov_cat_age_group <- numerical_to_categorical(df$cov_num_age,c(18,40,65,85),FALSE,FALSE,FALSE) # See utility.R
df$cov_cat_age_group <- ifelse(df$cov_cat_age_group == "<=17", "", df$cov_cat_age_group) # for consistency in blanking out underage

df$cov_cat_consrate2019 <- numerical_to_categorical(df$cov_num_consrate2019,c(1,6),TRUE,FALSE,FALSE, FALSE)

# Filter data ------------------------------------------------------------------
print("Filter data")

# df <- df[, c("patient_id",   # Old table
#              "exposed",
#              "cov_cat_sex",
#              "cov_cat_age_group",
#              "cov_cat_ethnicity",
#              "cov_cat_imd", # previously cov_cat_deprivation
#              "cov_cat_smoking", # previously cov_cat_smoking_status",
#              "strat_cat_region",    # previously cov_cat_region
#              "cov_bin_carehome")] # previously cov_bin_carehome_status

df <- df[, c("patient_id",
             "exposed",
             colnames(df)[grepl("cov_cat_", colnames(df))],
             colnames(df)[grepl("strat_cat_", colnames(df))],
             colnames(df)[grepl("cov_bin_", colnames(df))]
            )]


df$All <- "All"

# Filter binary data

for (colname in colnames(df)[grepl("cov_bin_", colnames(df))]) {
  # df[[colname]] <- as.integer(df[[colname]]) # If they want as "0" and "1"
  df[[colname]] <- sapply(df[[colname]], as.character)
}

# Aggregate data ---------------------------------------------------------------
print("Aggregate data")

df <- tidyr::pivot_longer(df,
                          cols      = setdiff(colnames(df), c("patient_id", "exposed")),
                          names_to  = "characteristic",
                          values_to = "subcharacteristic")

df$total <- 1

df <- aggregate(cbind(total, exposed) ~ characteristic + subcharacteristic,
                data = df,
                sum)

# Tidy care home characteristic ------------------------------------------------
print("Remove extraneous information")

df <- df[!(df$characteristic      == "cov_bin_carehome" &
           df$subcharacteristic   == "FALSE"), ]

df$subcharacteristic <- ifelse(df$characteristic == "cov_bin_carehome",
                               "Care home resident",
                               df$subcharacteristic)

df <- df[df$subcharacteristic != FALSE, ] # From extendedtable.R
df$subcharacteristic <- ifelse(df$subcharacteristic == "", # or == "unknown"??
                               "Missing",
                               df$subcharacteristic)

# Sort characteristics ---------------------------------------------------------
print("Sort characteristics")

df <- df[order(df$subcharacteristic, decreasing = TRUE), ] # Basic sort from extendedtable, might need to clean up
df <- df[order(df$characteristic), ]

# Try loading in plot_labels.csv

df_lab <- read.csv("lib/plot_labels.csv", header = TRUE)

# df_lab <- df_lab[, c(colnames(df)[grepl("cov_cat_", colnames(df))],
#                      colnames(df)[grepl("strat_cat_", colnames(df))],
#                      colnames(df)[grepl("cov_bin_", colnames(df))]
#                    )]

# setdiff(colnames(df), c("patient_id", "exposed"))

# df$characteristic <- factor(df$characteristic,
#                             levels = c("All",
#                                        "cov_cat_sex",
#                                        "cov_cat_age_group",
#                                        "cov_cat_ethnicity",
#                                        "cov_cat_imd",
#                                        "cov_cat_smoking",
#                                        "strat_cat_region",
#                                        "cov_bin_carehome_status"),
#                             labels = c("All",
#                                        "Sex",
#                                        "Age, years",
#                                        "Ethnicity",
#                                        "Index of multiple deprivation quintile",
#                                        "Smoking status",
#                                        "Region",
#                                        "Care home resident"))

df$characteristic <- factor(df$characteristic,
                            levels = df_lab$term,
                            labels = df_lab$label)

# Sort subcharacteristics ------------------------------------------------------
print("Sort subcharacteristics")

# df$subcharacteristic <- factor(df$subcharacteristic,
#                                levels = c("All",
#                                           "Female",            # Sex
#                                           "Male",
#                                           "18-39",             # Age
#                                           "40-64",
#                                           "65-84",
#                                           "85-110",
#                                           "White",            # Ethnicity
#                                           "Mixed",
#                                           "South Asian",
#                                           "Black",
#                                           "Other",
#                                           "Missing",
#                                           "1-2 (most deprived)", # IMD
#                                           "3-4",
#                                           "5-6",
#                                           "7-8",
#                                           "9-10 (least deprived)",
#                                           "Never smoker",      # Smoking
#                                           "Ever smoker",
#                                           "Current smoker",
#                                           "East",              # Region
#                                           "East Midlands",
#                                           "London",
#                                           "North East",
#                                           "North West",
#                                           "South East",
#                                           "South West",
#                                           "West Midlands",
#                                           "Yorkshire and The Humber",
#                                           "Care home resident", # Care
#                                           "Missing"),
#                                labels = c("All",
#                                           "Female",             # Sex
#                                           "Male",
#                                           "18-39",             # Age
#                                           "40-64",
#                                           "65-84",
#                                           "85-110",
#                                           "White",              # Ethnicity
#                                           "Mixed",
#                                           "South Asian",
#                                           "Black",
#                                           "Other",
#                                           "Missing",
#                                           "1: most deprived",   # IMD
#                                           "2",
#                                           "3",
#                                           "4",
#                                           "5: least deprived",
#                                           "Never smoker",       # Smoking
#                                           "Former smoker",
#                                           "Current smoker",
#                                           "East",               # Region
#                                           "East Midlands",
#                                           "London",
#                                           "North East",
#                                           "North West",
#                                           "South East",
#                                           "South West",
#                                           "West Midlands",
#                                           "Yorkshire/Humber",
#                                           "Care home resident", # Care
#                                           "Missing"))


# Sort data --------------------------------------------------------------------
print("Sort data")

df <- df[order(df$characteristic, df$subcharacteristic), ]

# Define table1 output folder ---------------------------------------------------------
print("Creating output/table1 output folder")

# setting up the sub directory
table1_dir <- "output/table1/"

# check if sub directory exists, create if not
fs::dir_create(here::here(table1_dir))

# Save Table 1 -----------------------------------------------------------------
print("Save Table 1")

write.csv(df, paste0(table1_dir, "table1_", cohort, ".csv"), row.names = FALSE)

# Perform redaction ------------------------------------------------------------
print("Perform redaction")

df$total_midpoint6   <- roundmid_any(as.numeric(df$total),   to = threshold)
df$exposed_midpoint6 <- roundmid_any(as.numeric(df$exposed), to = threshold)

# Calculate column percentages -------------------------------------------------

# df$Npercent_midpoint6_derived <- paste0(
#   df$total,
#   ifelse(df$characteristic == "All",
#          "",
#          paste0(" (",
#                 round(100*(df$total_midpoint6 / df[df$characteristic=="All","total_midpoint6"]),1),
#                 "%)"))
# )

df$N_midpoint6_derived <- df$total

df$percent_midpoint6_derived <- paste0(
  ifelse(df$characteristic == "All",
         "",
         paste0(" (",
                round(100*(df$total_midpoint6 / df[df$characteristic=="All","total_midpoint6"]),1),
                "%)"))
)

df      <- df[, c("characteristic",
                  "subcharacteristic",
                  "N_midpoint6_derived",
                  "percent_midpoint6_derived",
                  "exposed_midpoint6")]

colnames(df) <- c("Characteristic",
                  "Subcharacteristic",
                  "N [midpoint6_derived]",
                  "(%) [midpoint6_derived]",
                  "COVID-19 diagnoses [midpoint6]")

# Save Table 1 -----------------------------------------------------------------
print("Save rounded Table 1")

write.csv(df, paste0(table1_dir, "table1_", cohort, "_midpoint6.csv"), row.names = FALSE)



# Median IQR age

if (!file.exists(here::here(paste0(table1_dir, "median_iqr_age.csv")))) {

  # Create empty output ----------------------------------------------------------
  print('Create empty output')

  df_iqr <- data.frame(cohort = character(),
                  median_iqr_age = character())

  # Loop over cohorts ------------------------------------------------------------
  print("Loop over cohorts")

  for (cohort in c("prevax", "vax", "unvax")) { #c("prevax_extf", "vax", "unvax_extf")

    # Load data ------------------------------------------------------------------
    print(paste0("Load data for cohort: ", cohort))

    tmp <- readr::read_rds(paste0("output/dataset_clean/input_", cohort, ".rds")) #"_stage1.rds"

    # Calculate median (IQR) age -------------------------------------------------
    print("Calculate median (IQR) age")

    # Pastes: "Mean Age (LQ Age - UQ Age)" as a string for each cohort
    df_iqr[nrow(df_iqr)+1, ] <- c(cohort, paste0(quantile(tmp$cov_num_age)[3], " (", quantile(tmp$cov_num_age)[2], "-", quantile(tmp$cov_num_age)[4], ")"))
    
  }

  # Save median (IQR) age --------------------------------------------------------
  print('Save median (IQR) age')

  write.csv(df_iqr, paste0(table1_dir, "median_iqr_age.csv"), row.names = FALSE)

}
