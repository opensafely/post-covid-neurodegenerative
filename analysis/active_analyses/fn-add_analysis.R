# Helper function to add rows ----
add_analysis <- function(
  cohort,
  outcome,
  analysis_name,
  covariate_other,
  age_spline
) {
  # Define dates ----
  study_dates <- fromJSON("output/study_dates.json")
  dates <- list(
    prevax_start = study_dates$pandemic_start,
    vax_unvax_start = study_dates$delta_date,
    study_stop = study_dates$lcd_date
  )
  study_start <- ifelse(
    cohort == "prevax",
    dates$prevax_start,
    dates$vax_unvax_start
  )

  # Define cut points ----

  cut_points <- list(
    prevax = "1;28;183;365;730;1065;1582",
    vax_unvax = "1;28;183;365;730;1065"
  )
  cut_points_used <- ifelse(
    cohort == "prevax",
    cut_points$prevax,
    cut_points$vax_unvax
  )

  new_analysis <- c(
    cohort = cohort,
    exposure = "exp_date_covid",
    outcome = outcome,
    ipw = TRUE,
    strata = "strat_cat_region",
    covariate_sex = ifelse(
      grepl("sex", analysis_name),
      "NULL",
      "cov_cat_sex"
    ),
    covariate_age = "cov_num_age",
    covariate_other = covariate_other,
    cox_start = "index_date",
    cox_stop = "end_date_outcome",
    study_start = study_start,
    study_stop = dates$study_stop,
    cut_points = cut_points_used,
    controls_per_case = 20L,
    total_event_threshold = 50L,
    episode_event_threshold = 5L,
    covariate_threshold = 5L,
    age_spline = age_spline,
    analysis = analysis_name
  )

  return(new_analysis)
}
