# Load libraries ---------------------------------------------------------------
print('Load libraries')

library(readr)
library(dplyr)
library(magrittr)

# Define table1 output folder ---------------------------------------------------------
print("Creating output/table2 output folder")

table2_dir <- "output/table2/"
fs::dir_create(here::here(table2_dir))

# Source common functions ------------------------------------------------------
print('Source common functions')

source("analysis/utility.R")

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  cohort <- "prevax"
  subgroup <- "covidhospital"
} else {
  cohort <- args[[1]]
  subgroup <- args[[2]]
}

# Load active analyses ---------------------------------------------------------
print('Load active analyses')

active_analyses <- readr::read_rds("lib/active_analyses.rds")

table2_names <-
  unique(
    active_analyses[
      active_analyses$cohort ==
        {
          cohort
        },
    ]$name
  )

table2_names <- table2_names[
  grepl("-main", table2_names) |
    grepl(paste0("-sub_", subgroup), table2_names)
]

active_analyses <- active_analyses[active_analyses$name %in% table2_names, ]

# Make empty table 2 -----------------------------------------------------------
print('Make empty table 2')

table2 <- data.frame(
  name = character(),
  cohort = character(),
  exposure = character(),
  outcome = character(),
  analysis = character(),
  unexposed_person_days = numeric(),
  unexposed_events = numeric(),
  exposed_person_days = numeric(),
  exposed_events = numeric(),
  total_person_days = numeric(),
  total_events = numeric(),
  day0_events = numeric(),
  total_exposed = numeric(),
  sample_size = numeric()
)

# Record number of events and person days for each active analysis -------------
print('Record number of events and person days for each active analysis')

for (i in 1:nrow(active_analyses)) {
  ## Load data -----------------------------------------------------------------
  print(paste0("Load data for ", active_analyses$name[i]))

  df <- read_rds(paste0(
    "output/model/model_input-",
    active_analyses$name[i],
    ".rds"
  ))
  df <- df[, c(
    "patient_id",
    "index_date",
    "exp_date",
    "out_date",
    "end_date_exposure",
    "end_date_outcome"
  )]

  ## Make exposed subset -------------------------------------------------------
  print('Make exposed subset')

  exposed <- df[
    !is.na(df$exp_date),
    c("patient_id", "exp_date", "out_date", "end_date_outcome")
  ]

  exposed <- exposed[exposed$exp_date <= exposed$end_date_outcome, ]

  exposed <- exposed %>%
    dplyr::mutate(
      person_days = as.numeric((end_date_outcome - exp_date)) + 1
    )

  ## Make unexposed subset -----------------------------------------------------
  print('Make unexposed subset')

  unexposed <- df[, c(
    "patient_id",
    "index_date",
    "exp_date",
    "out_date",
    "end_date_outcome"
  )]

  unexposed <- unexposed %>%
    dplyr::mutate(
      fup_start = index_date,
      fup_end = pmin(exp_date - 1, end_date_outcome, na.rm = TRUE),
      out_date = replace(out_date, which(out_date > fup_end), NA)
    )

  unexposed <- unexposed[unexposed$fup_start <= unexposed$fup_end, ]

  unexposed <- unexposed %>%
    dplyr::mutate(
      person_days = as.numeric((fup_end - fup_start)) + 1
    )

  ## Append to table 2 ---------------------------------------------------------
  print('Append to table 2')

  table2[nrow(table2) + 1, ] <- c(
    name = active_analyses$name[i],
    cohort = active_analyses$cohort[i],
    exposure = active_analyses$exposure[i],
    outcome = active_analyses$outcome[i],
    analysis = active_analyses$analysis[i],
    unexposed_person_days = sum(unexposed$person_days),
    unexposed_events = nrow(unexposed[
      !is.na(unexposed$out_date),
    ]),
    exposed_person_days = sum(exposed$person_days, na.rm = TRUE),
    exposed_events = nrow(exposed[
      !is.na(exposed$out_date),
    ]),
    total_person_days = sum(unexposed$person_days) +
      sum(exposed$person_days, na.rm = TRUE),
    total_events = nrow(unexposed[!is.na(unexposed$out_date), ]) +
      nrow(exposed[!is.na(exposed$out_date), ]),
    day0_events = nrow(exposed[
      exposed$exp_date == exposed$out_date &
        !is.na(exposed$exp_date) &
        !is.na(exposed$out_date),
    ]),
    total_exposed = nrow(exposed),
    sample_size = nrow(df)
  )
}

# Save Table 2 -----------------------------------------------------------------
print('Save Table 2')

write.csv(
  table2,
  paste0(table2_dir, "table2-cohort_", cohort, "-sub_", subgroup, ".csv"),
  row.names = FALSE
)

# Perform redaction ------------------------------------------------------------
print('Perform redaction')

cols <- c(
  "sample_size",
  "day0_events",
  "total_exposed",
  "unexposed_events",
  "exposed_events"
)
new_names <- paste0(cols, "_midpoint6")

table2[new_names] <- lapply(
  table2[cols],
  function(x) roundmid_any(x)
)

table2$total_events_midpoint6_derived <- table2$unexposed_events_midpoint6 +
  table2$exposed_events_midpoint6

table2 <- table2[, c(
  "name",
  "cohort",
  "exposure",
  "outcome",
  "analysis",
  "unexposed_person_days",
  "unexposed_events_midpoint6",
  "exposed_person_days",
  "exposed_events_midpoint6",
  "total_person_days",
  "total_events_midpoint6_derived",
  "day0_events_midpoint6",
  "total_exposed_midpoint6",
  "sample_size_midpoint6"
)]

# Save Table 2 -----------------------------------------------------------------
print('Save rounded Table 2')

write.csv(
  table2,
  paste0(
    table2_dir,
    "table2-cohort_",
    cohort,
    "-sub_",
    subgroup,
    "-midpoint6.csv"
  ),
  row.names = FALSE
)
