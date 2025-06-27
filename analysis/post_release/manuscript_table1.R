# Define post_release output folder ------------------------------------------
output_folder <- "output/post_release" # Folder to save the transformed datasets

# Ensure output folder exists
if (!dir.exists(output_folder)) {
    dir.create(output_folder)
}

# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(
    "output/make_output/table1_output_midpoint6.csv",
    show_col_types = FALSE
)

# Clean column names: remove brackets
colnames(df) <- gsub(" \\[.*?\\]", "", colnames(df))

# Define ID columns
id_vars <- c("Characteristic", "Subcharacteristic")

# Subset preex_FALSE and preex_TRUE columns ------------------------------------
print("Split tables")

preex_false_cols <- grep("preex_FALSE$", names(df), value = TRUE)
preex_true_cols <- grep("preex_TRUE$", names(df), value = TRUE)

df_false <- df[, c(id_vars, preex_false_cols)]
df_true <- df[, c(id_vars, preex_true_cols)]

# Clean column names to standard form ------------------------------------------
clean_names <- function(df, preex_flag) {
    names(df) <- gsub(paste0("-", preex_flag, "$"), "", names(df)) # Remove suffix
    return(df)
}

df_false <- clean_names(df_false, "preex_FALSE")
df_true <- clean_names(df_true, "preex_TRUE")

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

df_false <- combine_n_pct(df_false)
df_true <- combine_n_pct(df_true)

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

df_false <- reorder_cols(df_false)
df_true <- reorder_cols(df_true)

# Save output ------------------------------------------------------------------
print("Save tables")

readr::write_csv(
    df_false,
    "output/post_release/table1_preex_false.csv",
    na = "-"
)
readr::write_csv(df_true, "output/post_release/table1_preex_true.csv", na = "-")
