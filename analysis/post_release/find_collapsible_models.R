library(dplyr)
library(tidyr)
library(readr)
# Load data --------------------------------------------------------------------
print("Load data")

source("analysis/specify_paths.R")
# List all CSV files matching the pattern
file_list <- list.files(
  path = paste0(release, "20260416_noday0\\"),
  pattern = "^model_output-.*-midpoint6\\.csv$",
  full.names = TRUE
)

# Read and combine all CSV files into one data frame
df <- file_list %>%
  lapply(read_csv, show_col_types = FALSE) %>%
  bind_rows()

df <- df[!is.na(df$hr), ]
df <- df[!grepl("_collapsed", df$analysis), ] # remove collapsed

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[
  df$model == "mdl_max_adj" &
    grepl("days", df$term),
  c(
    "name",
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
    # "days28_730", #don't keep collapsed
    # "days730_1460"  #don't keep collapsed
  ),
  ordered = TRUE
)

df <- unique(df) # remove duplicates

df_wide <- df %>%
  select(name, cohort, analysis, outcome, term, source, N_events_midpoint6) %>%
  tidyr::pivot_wider(
    names_from = term,
    values_from = N_events_midpoint6,
    id_cols = c('name', 'cohort', 'analysis', 'outcome', 'source')
  ) %>%
  # reorder columns based on term factor levels
  select(
    name,
    cohort,
    analysis,
    outcome,
    source,
    all_of(levels(df$term))
  )

# Find collapsible models ------------------------------------------------------

# Only keep models <12 at some point in first year
df_filt <- df_wide[
  df_wide$days0_28 < 12 | df_wide$days28_183 < 12 | df_wide$days183_365 < 12,
]

# Keep only models in main manuscript/supplement
df_filt <- df_filt[
  df_filt$analysis == "main" |
    grepl("covidhospital", df_filt$analysis) |
    grepl("park_risk", df_filt$analysis) |
    df_filt$outcome == "cis" |
    df_filt$outcome == "dem_any",
]


# Save Output ------------------------------------------------------------------

readr::write_csv(df_filt, "output/post_release/find_collapsible_models.csv")
