# Load packages ----------------------------------------------------------------
print("Load packages")

library(dplyr)
library(readr)

# Define the directory containing the CSV files
input_dir <- "output/make_output"

# Define post_release output folder ------------------------------------------
output_folder <- "output/post_release" # Folder to save the transformed datasets

# Ensure output folder exists
if (!dir.exists(output_folder)) {
    dir.create(output_folder)
}

# Load data --------------------------------------------------------------------
print("Load data")

# List all CSV files matching the pattern
file_list <- list.files(
    path = input_dir,
    pattern = "^model_output-.*-midpoint6\\.csv$",
    full.names = TRUE
)

# Read and combine all CSV files into one data frame
df <- file_list %>%
    lapply(read_csv, show_col_types = FALSE) %>%
    bind_rows()

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[grepl("days", df$term), ]

df <- df[
    df$model == "mdl_max_adj",
    c("analysis", "cohort", "outcome", "term", "hr", "conf_low", "conf_high")
]

df <- df[df$term != "days_pre", ]

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

# Tidy estimate ----------------------------------------------------------------
print("Tidy estimate")

df$estimate <- ifelse(
    df$hr == "X",
    "X",
    paste0(
        formatC(as.numeric(df$hr), format = "f", digits = 2),
        " (",
        formatC(as.numeric(df$conf_low), format = "f", digits = 2),
        "-",
        formatC(as.numeric(df$conf_high), format = "f", digits = 2),
        ")"
    )
)

# Tidy term --------------------------------------------------------------------
print("Tidy term")

df <- df %>%
    mutate(
        weeks = case_when(
            term == "days0_1" ~ "Day 0",
            term == "days1_7" ~ "Week 1, without day 0",
            term == "days7_14" ~ "Week 2",
            term == "days14_28" ~ "Weeks 3-4",
            term == "days28_56" ~ "Weeks 5-8",
            term == "days56_84" ~ "Weeks 9-12",
            term == "days84_183" ~ "Weeks 13-26",
            term == "days183_365" ~ "Weeks 27-52",
            term == "days365_730" ~ "Weeks 53-104",
            term == "days730_1065" ~ "Weeks 105-152",
            term == "days1065_1582" ~ "Weeks 153-226",
            TRUE ~ NA_character_
        )
    )

# Define the desired order for the 'weeks' factor
weeks_levels <- c(
    "Day 0",
    "Week 1, without day 0",
    "Week 2",
    "Weeks 3-4",
    "Weeks 5-8",
    "Weeks 9-12",
    "Weeks 13-26",
    "Weeks 27-52",
    "Weeks 53-104",
    "Weeks 105-152",
    "Weeks 153-226"
)

# Convert 'weeks' to a factor with specified levels
df$weeks <- factor(df$weeks, levels = weeks_levels)

# Can change this bit for sub-group analyses
df$subgroup <- sub("_preex.*", "", df$analysis)
df$analysis <- gsub(".*(?=preex)", "", df$analysis, perl = TRUE)

# Define factor levels for sorting
df$analysis <- factor(df$analysis, levels = c("preex_FALSE", "preex_TRUE"))

# Order the rows
df <- df[order(df$analysis, df$outcome_label, df$weeks), ]

# Pivot table ------------------------------------------------------------------
print("Pivot table")

df <- df[, c(
    "subgroup",
    "analysis",
    "cohort",
    "outcome_label",
    "weeks",
    "estimate"
)]

df <- tidyr::pivot_wider(
    df,
    names_from = "cohort",
    values_from = "estimate"
)

# Tidy table ------------------------------------------------------------------
df <- df %>%
    arrange(subgroup, analysis, outcome_label, weeks)

df <- dplyr::rename(
    df,
    "Analysis" = "analysis",
    "Outcome" = "outcome_label",
    "Time since COVID-19" = "weeks",
    "Pre-vaccine availability cohort" = "prevax",
    "Vaccinated cohort" = "vax",
    "Unvaccinated cohort" = "unvax"
)

# Save table -------------------------------------------------------------------
print("Save table")

readr::write_csv(df, "output/post_release/table3.csv", na = "-")
