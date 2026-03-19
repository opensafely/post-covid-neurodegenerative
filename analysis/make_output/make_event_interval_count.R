library(dplyr)
library(tidyr)
# Load data --------------------------------------------------------------------
print("Load data")

print("Load model output")

# List all CSV files matching the pattern
file_list <- list.files(
  path = "output/make_output/",
  pattern = "^model_output-.*-midpoint6\\.csv$",
  full.names = TRUE
)

# Read and combine all CSV files into one data frame
df <- file_list %>%
  lapply(read_csv, show_col_types = FALSE) %>%
  bind_rows()

# Find analyses with <12 midpoint6 events at any timepoint
low_event_list <- unique(na.omit(df[df$N_events_midpoint6 < 12, ]$name)) # find list

df_filtered <- df[!(df$name %in% low_event_list), ] # apply reduction

# Save list of removed files
sink('output/make_output/removed_models_low_events.txt')
print(low_event_list)
sink() #close external connection to file

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
    "days1460_1979"
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

df_wide["6month_Sum"] <- df_wide["days0_28"] + df_wide["days28_183"]
df_wide["Year1_Sum"] <- df_wide["days0_28"] +
  df_wide["days28_183"] +
  df_wide["days183_365"]
df_wide["Total_Sum"] <- df_wide["days0_28"] +
  df_wide["days28_183"] +
  df_wide["days183_365"] +
  df_wide["days365_730"] +
  df_wide["days730_1095"] +
  df_wide["days1095_1460"] +
  df_wide["days1460_1979"]

readr::write_csv(
  df_wide,
  "output/make_output/events_per_interval_midpoint6.csv"
)
