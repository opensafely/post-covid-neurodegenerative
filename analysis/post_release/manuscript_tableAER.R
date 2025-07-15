# Specify parameters -----------------------------------------------------------
print('Specify parameters')

perpeople <- 100000 # per X people

# Load data --------------------------------------------------------------------
print('Load data')

df <- read.csv(
  "output/post_release/lifetables_compiled.csv"
)

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[
  df$aer_age == "overall" &
    df$aer_sex == "overall" &
    df$days == 196,
]

# Add plot labels --------------------------------------------------------------
print("Add plot labels")

plot_labels <- readr::read_csv("lib/plot_labels.csv", show_col_types = FALSE)

df <- merge(
  df,
  plot_labels[, c("term", "label")],
  by.x = "outcome",
  by.y = "term",
  all.x = TRUE
)
df <- dplyr::rename(df, "outcome_label" = "label")

# Format data ------------------------------------------------------------------
print("Format data")

df$excess_risk <- df$cumulative_difference_absolute_excess_risk * perpeople

if (length(unique(df$analysis)) > 1) {
  print(
    "Multiple analysis groups found: appliable for projects considering pre-existing conditions"
  )
  df$analysis <- gsub(".*(?=preex)", "", df$analysis, perl = TRUE)

  # Define factor levels for sorting
  df$analysis <- factor(df$analysis, levels = c("preex_FALSE", "preex_TRUE"))
}

df$outcome_label <- factor(
  df$outcome_label,
  levels = c(
    "Pneumonia",
    "Asthma",
    "Chronic obstructive pulmonary disease",
    "Pulmonary fibrosis"
  )
)

df <- df[, c("analysis", "outcome_label", "cohort", "day0", "excess_risk")]

# Order the rows
df <- df[order(df$outcome_label, df$analysis), ]

# Pivot table ------------------------------------------------------------------
print("Pivot table")

df$day0 <- paste0("day0", df$day0)

df <- tidyr::pivot_wider(
  df,
  names_from = c("cohort", "day0"),
  values_from = c("excess_risk")
)

# Difference attributable to day0 ----------------------------------------------
print("Difference attributable to day0")

df <- df %>%
  dplyr::group_by(analysis, outcome_label) %>%
  dplyr::mutate(
    prevax_day0diff = prevax_day0TRUE - prevax_day0FALSE,
    vax_day0diff = vax_day0TRUE - vax_day0FALSE,
    unvax_day0diff = unvax_day0TRUE - unvax_day0FALSE
  ) %>%
  dplyr::ungroup()

# Round numerics ---------------------------------------------------------------
print("Round numerics")

df <- df %>%
  dplyr::mutate_if(is.numeric, ~ round(., 0))

# Tidy table -------------------------------------------------------------------
print("Tidy table")

df <- df[
  order(df$outcome_label),
  c(
    "outcome_label",
    "analysis",
    "prevax_day0TRUE",
    "prevax_day0FALSE",
    "prevax_day0diff",
    "vax_day0TRUE",
    "vax_day0FALSE",
    "vax_day0diff",
    "unvax_day0TRUE",
    "unvax_day0FALSE",
    "unvax_day0diff"
  )
]

# Save table -------------------------------------------------------------------
print("Save table")

readr::write_csv(df, paste0(output_folder, "/tableAER.csv"), na = "-")
