# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(path_table1,
                      show_col_types = FALSE)

# Rename columns for Results pack ----------------------------------------------
print("Rename columns")

df <- dplyr::rename(df,
                    "N (%)" = "N (%) midpoint6 derived",
                    "COVID-19 diagnoses" = "COVID-19 diagnoses midpoint6")

# Pivot table ------------------------------------------------------------------
print("Pivot table")

df <- tidyr::pivot_wider(df, 
                         names_from = "cohort",
                         values_from = c("N (%)","COVID-19 diagnoses"))

# Tidy table -------------------------------------------------------------------
print("Tidy table")

df <- df[,c("Characteristic","Subcharacteristic",
            paste0(c("N (%)","COVID-19 diagnoses"),"_prevax"),
            paste0(c("N (%)","COVID-19 diagnoses"),"_vax"),
            paste0(c("N (%)","COVID-19 diagnoses"),"_unvax"))]

# Save table -------------------------------------------------------------------
print("Save table")

readr::write_csv(df, "output/post_release/table1.csv", na = "-")