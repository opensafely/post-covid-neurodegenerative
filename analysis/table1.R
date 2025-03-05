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

table1_dir <- "output/table1/"

# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_rds(paste0("output/dataset_clean/input_", cohort, ".rds"))# "_stage1.rds"))

# Table 1 Processing Start -----------------------------------------------------
print("Table 1 processing")

# Remove people with history of COVID-19 ---------------------------------------
print("Remove people with history of COVID-19")

df <- df[df$sub_bin_covidhistory == FALSE, ] # Previously sub_bin_covid19_confirmed_history

# Create exposure indicator ----------------------------------------------------
print("Create exposure indicator")

df$exposed <- !is.na(df$exp_date_covid) # Previously exp_date_covid19_confirmed

# Define age groups ------------------------------------------------------------
print("Define age groups")

# df$cov_cat_age_group <- numerical_to_categorical(df$cov_num_age,c(18,30,40,50,60,70,80,90)) # See utility.R
df$cov_cat_age_group <- numerical_to_categorical(df$cov_num_age,c(18,40,65,85)) # See utility.R
df$cov_cat_age_group <- ifelse(df$cov_cat_age_group == "<=17", "", df$cov_cat_age_group) # for consistency in blanking out underage

df$cov_cat_consrate2019 <- numerical_to_categorical(df$cov_num_consrate2019,c(1,6),zero_flag=TRUE)

median_iqr_string <- paste0(quantile(df$cov_num_age)[3], " (", quantile(df$cov_num_age)[2], "-", quantile(df$cov_num_age)[4], ")")

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[, c("patient_id",
             "exposed",
             colnames(df)[grepl("cov_cat_", colnames(df))],
             colnames(df)[grepl("strat_cat_", colnames(df))],
             colnames(df)[grepl("cov_bin_", colnames(df))]
            )]


df$All <- "All"

# Filter binary data

for (colname in colnames(df)[grepl("cov_bin_", colnames(df))]) {
  df[[colname]] <- sapply(df[[colname]], as.character)
}

# Aggregate data ---------------------------------------------------------------
print("Aggregate data")

df <- tidyr::pivot_longer(df,
                          cols      = setdiff(colnames(df), c("patient_id", "exposed")),
                          names_to  = "characteristic",
                          values_to = "subcharacteristic")
                          #as.factor or factor to convert binary functions

df$total <- 1

df <- aggregate(cbind(total, exposed) ~ characteristic + subcharacteristic,
                data = df,
                sum)

# Try loading in plot_labels.csv
print("Loading output/study_labels.csv")

df_lab <- read.csv("output/study_labels.csv", header = TRUE)


# Tidy care home characteristic ------------------------------------------------
print("Remove extraneous information")

df <- df[df$subcharacteristic != FALSE, ] 
df$subcharacteristic <- ifelse(df$subcharacteristic == "" | df$subcharacteristic == "unknown",
                               "Missing",
                               df$subcharacteristic)

for (bin_char in df$characteristic[grepl("cov_bin_", df$characteristic)]) { 
      df$subcharacteristic <- ifelse(df$characteristic == bin_char,
                               df_lab[df_lab$term == bin_char, ]$label,
                               df$subcharacteristic)
}

# Sort characteristics ---------------------------------------------------------
print("Sort characteristics")

df <- df[order(df$subcharacteristic, decreasing = TRUE), ] # Basic sort from extendedtable, might need to clean up
df <- df[order(df$characteristic), ]

df$characteristic <- factor(df$characteristic,
                            levels = df_lab$term,
                            labels = df_lab$label)

# Add in Median IQR
print('Add median (IQR) age')

# Pastes: "Mean Age (LQ Age - UQ Age)" as a string for each cohort
df[nrow(df)+1, ] <- c("Age, years", "Median (IQR)", median_iqr_string, 0)

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

df <- df[df$subcharacteristic != "Median (IQR)", ] # Remove Median IQR row

df$total_midpoint6   <- roundmid_any(as.numeric(df$total),   to = threshold)
df$exposed_midpoint6 <- roundmid_any(as.numeric(df$exposed), to = threshold)

# Calculate column percentages -------------------------------------------------

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
