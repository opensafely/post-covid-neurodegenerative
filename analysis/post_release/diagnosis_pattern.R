# diagnosis_pattern.R - a script to diagnose the pattern of post-release analysis outputs, specifically focusing on event counts across different time intervals.

library(dplyr)
library(tidyr)
library(read)
# Load data --------------------------------------------------------------------
print("Load data")

source("analysis/specify_paths.R")
# List all CSV files matching the pattern
file_list <- list.files(
  path = paste0(release, "20260429_noday0\\"),
  pattern = "^model_output-.*-midpoint6\\.csv$",
  full.names = TRUE
)

# Read and combine all CSV files into one data frame
df <- file_list %>%
  lapply(read_csv, show_col_types = FALSE) %>%
  bind_rows()

df <- df[!is.na(df$hr), ]

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[
  df$model == "mdl_max_adj" &
    grepl("days", df$term),
  c(
    "cohort",
    "analysis",
    "outcome",
    "outcome_time_median",
    "term",
    "hr",
    "conf_low",
    "conf_high",
    "source",
    "N_total_midpoint6",
    "N_exposed_midpoint6",
    "N_events_midpoint6"
  )
]

df$term <- factor(
  df$term,
  levels = c(
    "days0_28",
    "days28_183",
    "days183_365",
    "days365_730",
    "days730_1095",
    "days1095_1460",
    "days1460_1979",
    "days28_730",
    "days730_1460"
  ),
  ordered = TRUE
)

df <- unique(df) # remove duplicates

df_wide <- df %>%
  select(cohort, analysis, outcome, term, source, N_events_midpoint6) %>%
  tidyr::pivot_wider(
    names_from = term,
    values_from = N_events_midpoint6,
    id_cols = c('cohort', 'analysis', 'outcome', 'source')
  ) %>%
  # reorder columns based on term factor levels
  select(
    cohort,
    analysis,
    outcome,
    source,
    all_of(levels(df$term))
  )

df_wide["Total_Sum"] <- df_wide["days0_28"] +
  df_wide["days28_183"] +
  df_wide["days183_365"] +
  df_wide["days365_730"] +
  df_wide["days730_1095"] +
  df_wide["days1095_1460"] +
  df_wide["days1460_1979"]
df_wide["Year1_Sum"] <- df_wide["days0_28"] +
  df_wide["days28_183"] +
  df_wide["days183_365"]
df_wide["6month_Sum"] <- df_wide["days0_28"] + df_wide["days28_183"]

readr::write_csv(df_wide, "output/post_release/events_per_interval_wide.csv")
