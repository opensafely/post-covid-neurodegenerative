install.packages("jsonlite")
library(jsonlite)

# Create output directory ----
fs::dir_create(here::here("lib"))

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

# Set constant values ----
ipw <- TRUE
age_spline <- TRUE
exposure <- "exp_date_covid"
strata <- "strat_cat_region"
covariate_sex <- "cov_cat_sex"
covariate_age <- "cov_num_age"
cox_start <- "index_date"
cox_stop <- "end_date_outcome"
controls_per_case <- 20L
total_event_threshold <- 50L
episode_event_threshold <- 5L
covariate_threshold <- 5L

# Define dates ----
study_dates <- fromJSON("output/study_dates.json")
prevax_start <- study_dates$pandemic_start
vax_unvax_start <- study_dates$delta_date
study_stop <- study_dates$lcd_date

# Define cut points ----
prevax_cuts <- "1;28;183;365;730;1065;1582"
vax_unvax_cuts <- "1;28;183;365;730;1065"

# Define covariates ----

## Core covariates (common across projects) ----
core_covars <- c(
  "cov_bin_ami",
  "cov_bin_cancer",
  "cov_bin_carehome",
  "cov_bin_ckd",
  "cov_num_consrate2019",
  "cov_bin_copd",
  # "cov_bin_dementia", # A core covariate, not used in this protocol
  "cov_bin_depression",
  "cov_bin_diabetes",
  "cov_cat_ethnicity",
  "cov_bin_hcworker",
  "cov_bin_hypertension",
  "cov_cat_imd",
  "cov_bin_liver_disease",
  "cov_bin_obesity",
  "cov_cat_smoking",
  "cov_bin_stroke_isch"
)

## Define project-specific covariates (e.g. neuro risk/histories) ----
project_covars <- c(
  "cov_bin_cis",
  "cov_bin_dem_any",
  "cov_bin_high_vasc_risk",
  "cov_bin_mnd",
  "cov_bin_ms",
  "cov_bin_migraine",
  "cov_bin_park",
  "cov_bin_park_risk"
)

## Combine covariates into a single string for analysis ----
all_covars <- paste0(c(core_covars, project_covars), collapse = ";")

# Specify cohorts ----
cohorts <- c("vax", "unvax", "prevax")

# Specify outcomes ----
outcomes_all <- c(
  "out_date_dem_alz", # Alzheimer's Disease
  "out_date_dem_vasc", # Vascular Dementia
  "out_date_dem_lb", # Lewy Body Dementia
  "out_date_dem_other", # Other Dementia
  "out_date_dem_unspec", # Unspecified Dementia
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
park_risk_sub_out <- c("out_date_park")
cis_sub_out <- c("out_date_dem_any")
park_sub_out <- c("out_date_dem_any")
vasc_risk_sub_out <- c(
  "out_date_dem_alz",
  "out_date_dem_vasc",
  "out_date_dem_lb",
  "out_date_dem_any",
  "out_date_cis"
)

# For each cohort ----

for (c in cohorts) {
  # For each outcome ----

  for (i in c(outcomes_all)) {
    # Define analyses ----

    ## analysis: main ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = all_covars,
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "main"
    )

    ## analysis: sub_covidhospital_TRUE ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = all_covars,
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_covidhospital_TRUE"
    )

    ## analysis: sub_covidhospital_FALSE ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = all_covars,
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_covidhospital_FALSE"
    )

    ## analysis: sub_covidhistory ----
    if (c != "prevax") {
      df[nrow(df) + 1, ] <- c(
        cohort = c,
        exposure = exposure,
        outcome = i,
        ipw = ipw,
        strata = strata,
        covariate_sex = covariate_sex,
        covariate_age = covariate_age,
        covariate_other = all_covars,
        cox_start = cox_start,
        cox_stop = cox_stop,
        study_start = vax_unvax_start,
        study_stop = study_stop,
        cut_points = vax_unvax_cuts,
        controls_per_case = controls_per_case,
        total_event_threshold = total_event_threshold,
        episode_event_threshold = episode_event_threshold,
        covariate_threshold = covariate_threshold,
        age_spline = TRUE,
        analysis = "sub_covidhistory"
      )
    }

    ## analysis: sub_sex_female ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = "NULL",
      covariate_age = covariate_age,
      covariate_other = all_covars,
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_sex_female"
    )

    ## analysis: sub_sex_male ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = "NULL",
      covariate_age = covariate_age,
      covariate_other = all_covars,
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_sex_male"
    )

    ## analysis: sub_age_18_39 ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = all_covars,
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = FALSE,
      analysis = "sub_age_18_39"
    )

    ## analysis: sub_age_40_64 ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = all_covars,
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = FALSE,
      analysis = "sub_age_40_64"
    )

    ## analysis: sub_age_65_84 ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = all_covars,
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = FALSE,
      analysis = "sub_age_65_84"
    )

    ## analysis: sub_age_85_110 ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = all_covars,
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = FALSE,
      analysis = "sub_age_85_110"
    )

    ## analysis: sub_ethnicity_white ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = gsub("cov_cat_ethnicity;", "", all_covars),
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_ethnicity_white"
    )

    ## analysis: sub_ethnicity_black ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = gsub("cov_cat_ethnicity;", "", all_covars),
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_ethnicity_black"
    )

    ## analysis: sub_ethnicity_mixed ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = gsub("cov_cat_ethnicity;", "", all_covars),
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_ethnicity_mixed"
    )

    ## analysis: sub_ethnicity_asian ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = gsub("cov_cat_ethnicity;", "", all_covars),
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_ethnicity_south_asian"
    )

    ## analysis: sub_ethnicity_other ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = gsub("cov_cat_ethnicity;", "", all_covars),
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_ethnicity_other"
    )
  }

  for (i in cis_sub_out) {
    ## analysis: sub_cis_TRUE ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = gsub("cov_bin_cis;", "", all_covars),
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_cis_TRUE"
    )

    ## analysis: sub_cis_FALSE ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = gsub("cov_bin_cis;", "", all_covars),
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_cis_FALSE"
    )
  }

  for (i in park_sub_out) {
    ## analysis: sub_park_TRUE ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = gsub("cov_bin_park;", "", all_covars),
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_park_TRUE"
    )

    ## analysis: sub_park_FALSE ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = gsub("cov_bin_park;", "", all_covars),
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_park_FALSE"
    )
  }

  for (i in vasc_risk_sub_out) {
    ## analysis: sub_bin_high_vasc_risk_TRUE ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = gsub("cov_bin_high_vasc_risk;", "", all_covars),
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_bin_high_vasc_risk_TRUE"
    )

    ## analysis: sub_bin_high_vasc_risk_FALSE ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = gsub("cov_bin_high_vasc_risk;", "", all_covars),
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_bin_high_vasc_risk_FALSE"
    )
  }

  for (i in park_risk_sub_out) {
    ## analysis: sub_park_risk_TRUE ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = gsub("cov_bin_park_risk;", "", all_covars),
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_park_risk_TRUE"
    )

    ## analysis: sub_park_risk_FALSE ----
    df[nrow(df) + 1, ] <- c(
      cohort = c,
      exposure = exposure,
      outcome = i,
      ipw = ipw,
      strata = strata,
      covariate_sex = covariate_sex,
      covariate_age = covariate_age,
      covariate_other = gsub("cov_bin_park_risk;", "", all_covars),
      cox_start = cox_start,
      cox_stop = cox_stop,
      study_start = ifelse(c == "prevax", prevax_start, vax_unvax_start),
      study_stop = study_stop,
      cut_points = ifelse(c == "prevax", prevax_cuts, vax_unvax_cuts),
      controls_per_case = controls_per_case,
      total_event_threshold = total_event_threshold,
      episode_event_threshold = episode_event_threshold,
      covariate_threshold = covariate_threshold,
      age_spline = TRUE,
      analysis = "sub_park_risk_FALSE"
    )
  }
}

# Add name for each analysis ----
df$name <- paste0(
  "cohort_",
  df$cohort,
  "-",
  df$analysis,
  "-",
  gsub("out_date_", "", df$outcome)
)

# Remove covariate according to each outcome -----
print("Removing covariates according to each outcome")

# Variables which only require removal of their own history from covariates
clean_loop <- c("_cis", "_dem_any", "_park", "_ms", "_mnd", "_migraine")

for (i in clean_loop) {
  df$covariate_other <- ifelse(
    df$outcome == paste0("out_date", i),
    gsub(paste0("cov_bin", i, ";"), "", df$covariate_other),
    df$covariate_other
  )
}

# Parkinson disease requires removal of Parkinsons and any Dementia
df$covariate_other <- ifelse(
  df$outcome == "out_date_park",
  gsub("cov_bin_park;|cov_bin_dem_any;", "", df$covariate_other),
  df$covariate_other
)

# Check names are unique and save active analyses list ----
if (!dir.exists("lib")) {
  dir.create("lib")
}
if (length(unique(df$name)) == nrow(df)) {
  saveRDS(df, file = "lib/active_analyses.rds", compress = "gzip")
} else {
  stop(paste0("ERROR: names must be unique in active analyses table"))
}
