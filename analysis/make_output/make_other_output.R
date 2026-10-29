# Load packages ----------------------------------------------------------------
print('Load packages')

library(magrittr)
library(data.table)
library(tidyr)

# Define make_output output folder ------------------------------------------
print("Creating output/make_output output folder")

makeout_dir <- "output/make_output/"
fs::dir_create(here::here(makeout_dir))

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  output <- "table1" # the action to apply
  cohorts <- "prevax;vax;unvax" # The iterative label
  subgroup <- ""
} else {
  output <- args[[1]]
  cohorts <- args[[2]]
  if (length(args) < 3) {
    subgroup <- "" # an optional subgroup label (e.g. preex_FALSE)
  } else {
    subgroup <- args[[3]]
  }
}

# Separate cohorts -------------------------------------------------------------
print('Separate cohorts')

cohorts <- stringr::str_split(as.vector(cohorts), ";")[[1]]

# Generate output/saving string ------------------------------------------------
print('Generate strings')

if (grepl("_noday0", subgroup)) {
  noday0_str <- "_noday0"
  subgroup <- gsub("_noday0", "", subgroup)
} else {
  noday0_str <- ""
}

if (subgroup == "All" | subgroup == "") {
  sub_str <- "" # if no subgroup is specified, don't have anything in the filename
} else if (subgroup == "main") {
  sub_str <- "-main" # if main is specified, use -main in the filename
} else {
  if (grepl("preex", subgroup)) {
    sub_str <- paste0("-", subgroup)
  } else {
    sub_str <- paste0("-sub_", subgroup) # if any other subgroup is specified, use -sub_{subgroup} in the filename
  }
}

# Create blank table -----------------------------------------------------------
print('Create blank table')

df <- NULL

# Add output from each cohort --------------------------------------------------
print('Add output from each cohort')

for (i in cohorts) {
  # load input
  if (output == "flow") {
    tmp <- readr::read_csv(paste0(
      "output/dataset_clean/flow-cohort_",
      i,
      "-midpoint6.csv"
    ))
    tmp$flow <- 1:nrow(tmp)
  } else {
    tmp <- readr::read_csv(paste0(
      "output/",
      output,
      "/",
      output,
      "-cohort_",
      i,
      sub_str,
      noday0_str,
      "-midpoint6.csv"
    ))
  }

  # create column for cohort
  tmp$cohort <- i

  # combining dataframes
  df <- rbind(df, tmp, fill = TRUE)
}

df <- df[df["cohort"] != TRUE, ]

# table1-specific processing ---------------------------------------------------
if (output == "table1") {
  print("table1 processing")
  df <- pivot_wider(
    df,
    names_from = "cohort",
    values_from = c(
      "N [midpoint6_derived]",
      "(%) [midpoint6_derived]",
      "COVID-19 diagnoses [midpoint6]"
    ),
    names_vary = "slowest"
  )
}

# Save output ------------------------------------------------------------------
print('Save output')

readr::write_csv(
  df,
  paste0(
    makeout_dir,
    "/",
    output,
    sub_str,
    noday0_str,
    "_output_midpoint6.csv"
  ),
  na = "-"
)
