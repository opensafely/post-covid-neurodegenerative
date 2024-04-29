# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(path_table1,
                      show_col_types = FALSE)

# Pivot table ------------------------------------------------------------------
print("Pivot table")

df <- tidyr::pivot_wider(df, 
                         names_from = "cohort",
                         values_from = c("N (%) midpoint6 derived","COVID-19 diagnoses midpoint6"))

# Tidy table -------------------------------------------------------------------
print("Tidy table")

df <- df[,c("Characteristic","Subcharacteristic",
            paste0(c("N (%) midpoint6 derived","COVID-19 diagnoses midpoint6"),"_prevax"),
            paste0(c("N (%) midpoint6 derived","COVID-19 diagnoses midpoint6"),"_vax"),
            paste0(c("N (%) midpoint6 derived","COVID-19 diagnoses midpoint6"),"_unvax"))]

# Save table -------------------------------------------------------------------
print("Save table")

readr::write_csv(df, "output/post_release/table1.csv", na = "-")