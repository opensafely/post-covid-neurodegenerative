library(dplyr)
library(tidyr)
# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(
  "output/post_release/plot_model_output.csv",
  show_col_types = FALSE
)
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
    "days730_1065",
    "days1065_1582"
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
  df_wide["days730_1065"] +
  df_wide["days1065_1582"]
df_wide["Year1_Sum"] <- df_wide["days0_28"] +
  df_wide["days28_183"] +
  df_wide["days183_365"]
df_wide["6month_Sum"] <- df_wide["days0_28"] + df_wide["days28_183"]

readr::write_csv(df_wide, "output/post_release/events_per_interval_wide.csv")

# Identify cohorts and analyses with N_total_midpoint6 < 4,000,000 ----
df_filtered <- df %>%
  filter(
    source == "R",
    N_total_midpoint6 < 4000000
  ) %>%
  distinct(cohort, analysis)

# View the result
print(df_filtered)

df_filtered %>%
  arrange(cohort, analysis)

# Only include columns that start with "days"
day_cols <- grep("^days", names(df_wide), value = TRUE, perl = TRUE)
# day_cols <- grep("^days", names(df_wide), value = TRUE)
# day_cols <- setdiff(day_cols, c("days0_1", "days1_28"))
# For each row, find the columns corresponding to the 4 lowest values
df_ranked <- df_wide %>%
  rowwise() %>%
  mutate(
    lowest_days_1 = day_cols[order(c_across(all_of(day_cols)))[1]],
    lowest_days_2 = day_cols[order(c_across(all_of(day_cols)))[2]],
    lowest_days_3 = day_cols[order(c_across(all_of(day_cols)))[3]],
    lowest_days_4 = day_cols[order(c_across(all_of(day_cols)))[4]]
  ) %>%
  ungroup()

# View relevant results
df_ranked %>%
  select(
    cohort,
    analysis,
    outcome,
    lowest_days_1,
    lowest_days_2,
    lowest_days_3,
    lowest_days_4
  )

# Combine all lowest_days_* columns into one long column
summary_lowest <- df_ranked %>%
  select(starts_with("lowest_days")) %>%
  pivot_longer(
    cols = everything(),
    names_to = "rank_position",
    values_to = "days_column"
  ) %>%
  group_by(rank_position, days_column) %>%
  summarise(count = n(), .groups = "drop") %>%
  arrange(rank_position, desc(count))

summary_lowest


# View the result
print(df_wide, n = 30)
