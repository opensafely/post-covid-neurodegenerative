# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(
    path_table2,
    show_col_types = FALSE
)

colnames(df) <- gsub("_midpoint6", "", colnames(df))

# Keep totals ------------------------------------------------------------------
print("Keep totals")

totals <- df %>%
    filter(grepl("main", analysis)) %>%
    distinct(cohort, analysis, sample_size) %>%
    pivot_wider(names_from = cohort, values_from = sample_size) %>%
    rename_with(~ paste0("event_personyears_", .x), .cols = -analysis) %>%
    mutate(
        analysis = gsub("main_", "", analysis),
        outcome_label = "N"
    )
# Convert all event_personyears_* columns in totals to character
cols_to_convert <- grep("^event_personyears_", colnames(totals), value = TRUE)

totals[cols_to_convert] <- lapply(totals[cols_to_convert], as.character)

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[
    grepl("main|sub_covidhospital", df$analysis),
    c(
        "cohort",
        "analysis",
        "outcome",
        "sample_size",
        "unexposed_events",
        "exposed_events",
        "unexposed_person_days",
        "exposed_person_days"
    )
]

df$events <- ifelse(
    grepl("main", df$analysis),
    df$unexposed_events,
    df$exposed_events
)
df$person_days <- ifelse(
    grepl("main", df$analysis),
    df$unexposed_person_days,
    df$exposed_person_days
)

df <- df[, c("cohort", "analysis", "outcome", "events", "person_days")]

# Add plot labels --------------------------------------------------------------
print("Add plot labels")

plot_labels <- readr::read_csv("lib/plot_labels.csv", show_col_types = FALSE)

df$outcome <- gsub("out_date_", "", df$outcome)
df <- merge(
    df,
    plot_labels[, c("term", "label")],
    by.x = "outcome",
    by.y = "term",
    all.x = TRUE
)
df <- dplyr::rename(df, "outcome_label" = "label")

df <- merge(
    df,
    plot_labels[, c("term", "label")],
    by.x = "analysis",
    by.y = "term",
    all.x = TRUE
)
df <- dplyr::rename(df, "covid19_severity" = "label")

# Add other columns ------------------------------------------------------------
print("Add other columns")

df$event_personyears <- paste0(df$events, "/", round((df$person_days / 365.25)))
df$incidencerate <- round(df$events / ((df$person_days / 365.25) / 100000))

# Pivot table ------------------------------------------------------------------
print("Pivot table")

df <- df[, c(
    "analysis",
    "cohort",
    "outcome_label",
    "covid19_severity",
    "event_personyears",
    "incidencerate"
)]

df$analysis <- gsub(".*(?=preex)", "", df$analysis, perl = TRUE)

# Define factor levels for sorting
df$outcome_label <- factor(
    df$outcome_label,
    levels = c(
        "Pneumonia",
        "Asthma",
        "Chronic obstructive pulmonary disease",
        "Pulmonary fibrosis"
    )
)

df$analysis <- factor(df$analysis, levels = c("preex_FALSE", "preex_TRUE"))

df$covid19_severity <- factor(
    df$covid19_severity,
    levels = c(
        "No COVID-19",
        "Hospitalised COVID-19",
        "Non-hospitalised COVID-19"
    )
)

# Order the rows
df <- df[order(df$outcome_label, df$analysis, df$covid19_severity), ]

df <- tidyr::pivot_wider(
    df,
    names_from = "cohort",
    values_from = c("event_personyears", "incidencerate")
)

# Reorder columns
column_order <- c(
    "analysis",
    "outcome_label",
    "covid19_severity",
    "event_personyears_prevax",
    "incidencerate_prevax",
    "event_personyears_vax",
    "incidencerate_vax",
    "event_personyears_unvax",
    "incidencerate_unvax"
)

df <- df[, column_order]

# Add totals to table ----------------------------------------------------------
print("Add totals to table")

# Step 1: Define a function to insert a total row before the first match
insert_total_row <- function(df, total_row) {
    analysis_value <- total_row$analysis
    first_idx <- which(df$analysis == analysis_value)[1]

    # If no match, append
    if (is.na(first_idx)) {
        out <- dplyr::bind_rows(df, total_row)
    } else if (first_idx == 1) {
        out <- dplyr::bind_rows(total_row, df)
    } else {
        out <- dplyr::bind_rows(
            df[1:(first_idx - 1), ],
            total_row,
            df[first_idx:nrow(df), ]
        )
    }

    # Force original column order
    out <- out[, colnames(df)]

    return(out)
}

for (i in seq_len(nrow(totals))) {
    df <- insert_total_row(df, totals[i, ])
}

# Tidy table -------------------------------------------------------------------
print("Tidy table")

df <- dplyr::rename(
    df,
    "Outcome" = "outcome_label",
    "COVID-19 severity" = "covid19_severity"
)


# Save table -------------------------------------------------------------------
print("Save table")

readr::write_csv(df, paste0(output_folder, "/table2_severity.csv"), na = "-")
