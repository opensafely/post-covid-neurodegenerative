# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(path_extendedtable1,
                      show_col_types = FALSE)

# Pivot table ------------------------------------------------------------------
print("Pivot table")

df <- tidyr::pivot_wider(df, 
                         names_from = "cohort",
                         values_from = c("N (%)","COVID-19 diagnoses"))



# Remove diabetes components ---------------------------------------------------
print("Remove diabetes components")

df <- df[!grepl("cov_bin_diabetes_",df$Characteristic),]

# Add plot labels --------------------------------------------------------------
print("Add plot labels")

plot_labels <- readr::read_csv("lib/plot_labels.csv", show_col_types = FALSE)

df$Subcharacteristic <- ifelse(df$Subcharacteristic=="TRUE",df$Characteristic,df$Subcharacteristic)
df$Characteristic <- ifelse(grepl("cov_bin_",df$Characteristic),"Medical history",df$Characteristic)
df <- merge(df, plot_labels, by.x = "Characteristic", by.y = "term", all.x = TRUE)
df$Characteristic <- NULL
df <- dplyr::rename(df, "Characteristic" = "label")
df$Characteristic <- ifelse(is.na(df$Characteristic),"Medical history",df$Characteristic)

df <- merge(df, plot_labels, by.x = "Subcharacteristic", by.y = "term", all.x = TRUE)
df$label <- ifelse(df$Characteristic=="GP consultations in 2019",df$Subcharacteristic,df$label)
df$Subcharacteristic <- NULL
df <- dplyr::rename(df, "Subcharacteristic" = "label")

# Tidy table -------------------------------------------------------------------
print("Tidy table")

df <- df[order(df$Characteristic),
         c("Characteristic","Subcharacteristic",
           paste0(c("N (%)","COVID-19 diagnoses"),"_prevax"),
           paste0(c("N (%)","COVID-19 diagnoses"),"_vax"),
           paste0(c("N (%)","COVID-19 diagnoses"),"_unvax"))]

# Save table -------------------------------------------------------------------
print("Save table")

readr::write_csv(df, "output/post_release/extendedtable1.csv", na = "-")