library(dplyr)
library(tidyr)
library(readr)
library(stringr)
# Load data --------------------------------------------------------------------
print("Load data")

# List all CSV files matching the pattern
file_list <- list.files(
  path = "output/make_output/",
  pattern = "^model_output-.*-midpoint6\\.csv$",
  full.names = TRUE
)

# Read and combine all CSV files into one data frame
df <- file_list %>%
  lapply(
    read_csv,
    show_col_types = FALSE,
    col_select = c(
      # "name",
      "cohort",
      "analysis",
      "outcome",
      "term",
      "model",
      "source",
      "hr",
      "N_events_midpoint6"
    )
  ) %>%
  bind_rows()

# # Find analyses with <12 midpoint6 events at any timepoint
# low_event_list <- unique(na.omit(df[df$N_events_midpoint6 < 12, ]$name)) # find list
#
# df_filtered <- df[!(df$name %in% low_event_list), ] # apply reduction
#
# # Save list of removed files
# sink('output/make_output/removed_models_low_events.txt')
# print(low_event_list)
# sink() #close external connection to file

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[
  df$model == "mdl_max_adj" &
    grepl("days", df$term),
  c(
    "cohort",
    "analysis",
    "outcome",
    "term",
    "source",
    "N_events_midpoint6"
  )
]

days_list <- unique(df$term[grepl("days", df$term)])

sorted_days <- days_list[order(sapply(days_list, function(x) {
  if (x == "days_pre") return(-1) # Ensure 'pre' is always first
  as.numeric(str_extract(x, "\\d+")) # Extract the first number
}))]

df$term <- factor(
  df$term,
  levels = sorted_days,
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

df_wide <- df_wide[!is.na(df_wide$analysis), ]

# From day1 sums
df_wide["days0_183_derived"] <- df_wide["days0_28"] + df_wide["days28_183"]
df_wide["days0_365_derived"] <- df_wide["days0_28"] +
  df_wide["days28_183"] +
  df_wide["days183_365"]
df_wide["Total"] <- rowSums(
  df_wide[sorted_days[2:length(sorted_days)]],
  na.rm = TRUE
)

# Later sums
# df_wide["days0_28A"] <- df_wide["days0_28"]
df_wide["days28_365_derived"] <- df_wide["days28_183"] + df_wide["days183_365"]
df_wide["days365_1460_derived"] <- df_wide["days365_730"] +
  df_wide["days730_1095"] +
  df_wide["days1095_1460"]
# df_wide["days0_28B"] <- df_wide["days0_28"]
df_wide["days28_730_derived"] <- df_wide["days28_183"] +
  df_wide["days183_365"] +
  df_wide["days365_730"]
df_wide["days730_1460_derived"] <- df_wide["days730_1095"] +
  df_wide["days1095_1460"]
# df_wide["days0_28C"] <- df_wide["days0_28"]
# df_wide["days28_183C"] <- df_wide["days28_183"]
df_wide["days183_730_derived"] <- df_wide["days183_365"] +
  df_wide["days365_730"]
# df_wide["days730_1460_derived"] <- df_wide["days730_1095"] +
# df_wide["days1095_1460"]

readr::write_csv(
  df_wide,
  "output/make_output/events_per_interval_midpoint6.csv"
)
