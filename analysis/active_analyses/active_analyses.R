library(jsonlite)
library(dplyr)

# Create output directory ----
fs::dir_create(here::here("lib"))

# Source common functions ----
lapply(
  list.files("analysis/active_analyses/", full.names = TRUE, pattern = "fn-"),
  source
)

# Define cohorts ----
cohorts <- c("vax", "unvax", "prevax")

# Define outcomes ----
outcomes_all <- c(
  "out_date_dem_alz", # Alzheimer's Disease
  "out_date_dem_vasc", # Vascular Dementia
  "out_date_dem_lb", # Lewy Body Dementia
  "out_date_dem_any", # Any Dementia
  "out_date_cis", # Cognitive Impairment Symptoms
  "out_date_park", # Parkinson's Disease
  "out_date_rls", # Restless Leg Syndrome
  "out_date_rsd", # REM Sleep Disorder
  "out_date_mnd", # Motor Neurone Disease
  "out_date_ms", # Multiple Sclerosis
  "out_date_migraine"
)

## Define more refined outcome groups ----
outcomes_cis <- c("out_date_dem_any")
outcomes_park <- c("out_date_dem_any")
outcomes_parkrisk <- c("out_date_park")
outcomes_highvascrisk <- c(
  "out_date_dem_alz",
  "out_date_dem_vasc",
  "out_date_dem_lb",
  "out_date_dem_any",
  "out_date_cis"
)

# Define subgroups ----
subgroups <- c(
  "sub_covidhospital_TRUE",
  "sub_covidhospital_FALSE",
  "sub_covidhistory",
  "sub_sex_female",
  "sub_sex_male",
  "sub_age_18_49",
  "sub_age_50_64",
  "sub_age_65_84",
  "sub_age_85_110",
  "sub_ethnicity_white",
  "sub_ethnicity_black",
  "sub_ethnicity_mixed",
  "sub_ethnicity_asian",
  "sub_ethnicity_other"
)

subgroups_cis <- c(
  "sub_cis_TRUE",
  "sub_cis_FALSE"
)

subgroups_park <- c(
  "sub_park_TRUE",
  "sub_park_FALSE"
)

subgroups_parkrisk <- c(
  "sub_parkrisk_TRUE",
  "sub_parkrisk_FALSE"
)

subgroups_highvascrisk <- c(
  "sub_highvascrisk_TRUE",
  "sub_highvascrisk_FALSE"
)

# Define covariates ----
core_covars <- c(
  "cov_cat_ethnicity",
  "cov_cat_imd",
  "cov_num_consrate2019",
  "cov_bin_hcworker",
  "cov_cat_smoking",
  "cov_bin_carehome",
  "cov_bin_obesity",
  "cov_bin_ami",
  # "cov_bin_dementia", # A core covariate, not used in this protocol
  "cov_bin_liver_disease",
  "cov_bin_ckd",
  "cov_bin_cancer",
  "cov_bin_hypertension",
  "cov_bin_diabetes",
  "cov_bin_depression",
  "cov_bin_copd",
  "cov_bin_stroke_isch"
)

## Define project-specific covariates (e.g. neuro risk/histories) ----
project_covars <- c(
  "cov_bin_cis",
  "cov_bin_dem_any",
  "cov_bin_highvascrisk",
  "cov_bin_mnd",
  "cov_bin_ms",
  "cov_bin_migraine",
  "cov_bin_park",
  "cov_bin_parkrisk"
)

covariate_other <- paste0(c(core_covars, project_covars), collapse = ";")

# Create empty data frame ----
df <- data.frame(
  cohort = character(),
  exposure = character(),
  outcome = character(),
  ipw = logical(),
  strata = character(),
  covariate_sex = character(),
  covariate_age = character(),
  covariate_other = character(),
  cox_start = character(),
  cox_stop = character(),
  study_start = character(),
  study_stop = character(),
  cut_points = character(),
  controls_per_case = numeric(),
  total_event_threshold = numeric(),
  episode_event_threshold = numeric(),
  covariate_threshold = numeric(),
  age_spline = logical(),
  analysis = character(),
  stringsAsFactors = FALSE
)

# Generate analyses ----
for (c in cohorts) {
  for (i in outcomes_all) {
    # Add main analysis ----
    df[nrow(df) + 1, ] <- add_analysis(
      cohort = c,
      outcome = i,
      analysis_name = "main",
      covariate_other = covariate_other,
      age_spline = TRUE
    )

    # Add subgroup analyses ----
    for (sub in subgroups) {
      # Skip sub_covidhistory if cohort is "prevax"
      if (sub == "sub_covidhistory" && c == "prevax") {
        next
      }

      # Adjust covariate_other for ethnicity subgroup
      adjusted_covariate_other <- covariate_other
      if (grepl("sub_ethnicity", sub)) {
        adjusted_covariate_other <- paste0(
          setdiff(strsplit(covariate_other, ";")[[1]], "cov_cat_ethnicity"),
          collapse = ";"
        )
      }

      # Add analysis for the subgroup
      df[nrow(df) + 1, ] <- add_analysis(
        cohort = c,
        outcome = i,
        analysis_name = sub,
        covariate_other = adjusted_covariate_other,
        age_spline = ifelse(grepl("sub_age", sub), FALSE, TRUE)
      )
    }
  }
  for (i in outcomes_cis) {
    for (sub in subgroups_cis) {
      df[nrow(df) + 1, ] <- add_analysis(
        cohort = c,
        outcome = i,
        analysis_name = sub,
        covariate_other = gsub("cov_bin_cis(;|$)", "", covariate_other),
        age_spline = TRUE
      )
    }
  }
  for (i in outcomes_park) {
    for (sub in subgroups_park) {
      df[nrow(df) + 1, ] <- add_analysis(
        cohort = c,
        outcome = i,
        analysis_name = sub,
        covariate_other = gsub("cov_bin_park(;|$)", "", covariate_other),
        age_spline = TRUE
      )
    }
  }

  for (i in outcomes_highvascrisk) {
    for (sub in subgroups_highvascrisk) {
      df[nrow(df) + 1, ] <- add_analysis(
        cohort = c,
        outcome = i,
        analysis_name = sub,
        covariate_other = gsub(
          "cov_bin_highvascrisk(;|$)",
          "",
          covariate_other
        ),
        age_spline = TRUE
      )
    }
  }

  for (i in outcomes_parkrisk) {
    for (sub in subgroups_parkrisk) {
      df[nrow(df) + 1, ] <- add_analysis(
        cohort = c,
        outcome = i,
        analysis_name = sub,
        covariate_other = gsub("cov_bin_parkrisk(;|$)", "", covariate_other),
        age_spline = TRUE
      )
    }
  }
}


# noday0 processing ---------------------------------------------------------
df_noday0 <- df
df_noday0$analysis <- paste0(df_noday0$analysis, "_noday0") # update analysis names
df_noday0$cut_points <- gsub("1;", "", df_noday0$cut_points) # update cut points
df <- df_noday0 # update main analysis list to be just noday0

# Add name for each analysis ----
df$name <- paste0(
  "cohort_",
  df$cohort,
  "-",
  df$analysis,
  "-",
  gsub("out_date_", "", df$outcome)
)

# Remove covariates according to each outcome -----
print("Removing covariates according to each outcome")

# Variables which require removal of their own history from covariates
clean_loop <- c("_cis", "_park", "_ms", "_mnd", "_migraine")

for (i in clean_loop) {
  df$covariate_other <- ifelse(
    df$outcome == paste0("out_date", i),
    gsub(paste0("cov_bin", i, "(;|$)"), "", df$covariate_other),
    df$covariate_other
  )
}

# Variables which require the removal of Any Dementia
dem_loop <- c("_dem_any", "_dem_alz", "_dem_lb", "_dem_vasc", "_park")
for (i in dem_loop) {
  df$covariate_other <- ifelse(
    df$outcome == paste0("out_date", i),
    gsub("cov_bin_dem_any(;|$)", "", df$covariate_other),
    df$covariate_other
  )
}

# Replace parkrisk history with rsd for the rls outcome, and vice-versa (i.e. to remove only own history)
df$covariate_other <- ifelse(
  df$outcome == "out_date_rsd",
  gsub("cov_bin_parkrisk", "cov_bin_rls", df$covariate_other),
  df$covariate_other
)

df$covariate_other <- ifelse(
  df$outcome == "out_date_rls",
  gsub("cov_bin_parkrisk", "cov_bin_rsd", df$covariate_other),
  df$covariate_other
)

# Ensure no trailing ; at the end of the list
df$covariate_other <- gsub(";$", "", df$covariate_other)

# Check names are unique and save active analyses list ----
if (!dir.exists("lib")) {
  dir.create("lib")
}

# Check names are unique and save active analyses list ----
if (length(unique(df$name)) == nrow(df)) {
  saveRDS(df, file = "lib/active_analyses.rds", compress = "gzip")
} else {
  stop("ERROR: names must be unique in active analyses table")
}
