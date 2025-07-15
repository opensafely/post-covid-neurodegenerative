# Load data --------------------------------------------------------------------
print("Load data")

df <- read_csv("output/plot_model_output.csv")

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

clean_format <- function(x) {
  x_clean <- suppressWarnings(as.numeric(gsub("<", "", x)))

  formatted <- ifelse(
    is.na(x_clean),
    NA_character_,
    ifelse(
      x_clean < 0.0001,
      "0.000",
      ifelse(
        x_clean > 1e4,
        formatC(x_clean, format = "e", digits = 2),
        formatC(x_clean, format = "f", digits = 2)
      )
    )
  )

  return(formatted)
}

df$estimate <- ifelse(
  df$hr == "X",
  "X",
  paste0(
    clean_format(df$hr),
    " (",
    clean_format(df$conf_low),
    "-",
    clean_format(df$conf_high),
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

df$outcome_label <- factor(
  df$outcome_label,
  levels = c(
    "Pneumonia",
    "Asthma",
    "Chronic obstructive pulmonary disease",
    "Pulmonary fibrosis"
  )
)

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

# Tidy table -------------------------------------------------------------------
df <- df %>%
  arrange(subgroup, outcome_label, analysis, weeks)

# Reorder columns -------------------------------------------------------------
df <- df %>%
  dplyr::select(
    subgroup,
    outcome_label,
    analysis,
    weeks,
    prevax,
    vax,
    unvax
  )

df <- dplyr::rename(
  df,
  "Analysis" = "analysis",
  "Outcome" = "outcome_label",
  "Time since COVID-19" = "weeks",
  "Pre-vaccination cohort" = "prevax",
  "Vaccinated cohort" = "vax",
  "Unvaccinated cohort" = "unvax"
)

# Save table -------------------------------------------------------------------
print("Save table")

readr::write_csv(df, paste0(output_folder, "/table3.csv"), na = "-")
