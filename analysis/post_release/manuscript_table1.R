# Comment out these two lines once table is in the right format
path_table1 = "C:\\Users\\pp24053\\Documents\\GitHub\\post-covid-neurodegenerative\\output\\make_output\\table1_output_midpoint6.csv"
output_folder = "output\\post_release\\"

# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(path_table1, show_col_types = FALSE)

# Clean column names: remove brackets
colnames(df) <- gsub(" \\[.*?\\]", "", colnames(df))

# Define ID columns
id_vars <- c("Characteristic", "Subcharacteristic")

# Combine N and % columns ------------------------------------------------------
combine_n_pct <- function(df) {
  for (group in c("prevax", "vax", "unvax")) {
    n_col <- paste0("N_", group)
    pct_col <- paste0("(%)_", group)
    combined_col <- paste0("N (%)_", group)

    if (all(c(n_col, pct_col) %in% names(df))) {
      df[[combined_col]] <- ifelse(
        tolower(df$Subcharacteristic) %in% c("all", "median (iqr)"),
        df[[n_col]], # show only N
        paste0(df[[n_col]], " ", df[[pct_col]]) # combine N and (%)
      )
    }
  }

  # Drop original N and (%) columns
  df <- df[,
    !names(df) %in%
      c(
        paste0("N_", c("prevax", "vax", "unvax")),
        paste0("(%)_", c("prevax", "vax", "unvax"))
      )
  ]
  return(df)
}

df <- combine_n_pct(df)


# Reorder columns to match: N (%), Diagnoses per cohort ------------------------
reorder_cols <- function(df) {
  df[, c(
    "Characteristic",
    "Subcharacteristic",
    "N (%)_prevax",
    "COVID-19 diagnoses_prevax",
    "N (%)_vax",
    "COVID-19 diagnoses_vax",
    "N (%)_unvax",
    "COVID-19 diagnoses_unvax"
  )]
}

df <- reorder_cols(df)

# Save output ------------------------------------------------------------------
print("Save tables")

readr::write_csv(
  df,
  paste0(output_folder, "/table1.csv"),
  na = "-"
)
