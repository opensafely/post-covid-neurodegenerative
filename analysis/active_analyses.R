# Create output directory ------------------------------------------------------

fs::dir_create(here::here("lib"))

# Create empty data frame ------------------------------------------------------

df <- data.frame(cohort = character(),
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
                 stringsAsFactors = FALSE)

# Set constant values ----------------------------------------------------------

ipw <- TRUE
age_spline <- TRUE
exposure <- "exp_date_covid19_confirmed"
strata <- "cov_cat_region"
covariate_sex <- "cov_cat_sex"
covariate_age <- "cov_num_age"
cox_start <- "index_date"
cox_stop <- "end_date_outcome"
controls_per_case <- 20L
total_event_threshold <- 50L
episode_event_threshold <- 5L
covariate_threshold <- 5L

# Specify cohorts --------------------------------------------------------------

cohorts <- c("vax","unvax","prevax")

# Specify outcomes -------------------------------------------------------------

outcomes_runall <- c("out_date_alzheimer_disease", 
                     "out_date_vascular_dementia",
                     "out_date_lewy_body_dementia",
                     "out_date_any_dementia",
                     "out_date_cognitive_impairment_symptoms",
                     "out_date_parkinson_disease",
                     "out_date_restless_leg_syndrome",
                     "out_date_rem_sleep_disorder",
                     "out_date_motor_neurone_disease",
                     "out_date_multiple_sclerosis",
                     "out_date_migraine")

# Note:
# suffix _sub_out refers to the neuro specific models 
# The suffix _sub_out creates a vector of outcomes that when applied to the given subgroup, it will help to indicate which binary covariates (cov_bin / cov_bin_history) 
# should be removed from the covariate_other column in the active_analyses table.

# vascular_risk_sub_out remove cov_bin_hypertension, cov_bin_diabetes, cov_bin_history_cog_imp_sympt, and cov_bin_history_any_dementia
vascular_risk_sub_out <- c("out_date_alzheimer_disease", "out_date_vascular_dementia", "out_date_lewy_body_dementia", "out_date_any_dementia", "out_date_cognitive_impairment_symptoms")
# parkinson_risk_sub_ou remove cov_bin_history_parkinson
parkinson_risk_sub_out <- c("out_date_parkinson_disease") 
# cognitive_impairment_sub_out remove cov_bin_history_any_dementia and cov_bin_history_cog_imp_sympt
cognitive_impairment_sub_out <- c("out_date_any_dementia")
# parkinson_disease_sub_out remove cov_bin_history_any_dementia
parkinson_disease_sub_out <- c("out_date_any_dementia")

# list of covariates according to protocol
all_covars <- c("cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_ckd;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_copd;cov_bin_ami;cov_bin_isch;cov_bin_history_cog_imp_sympt;cov_bin_history_mnd;cov_bin_history_migraine;cov_bin_history_any_dementia;cov_bin_history_parkinson;cov_bin_history_ms;cov_bin_history_parkinson_risk")

# Add active analyses ----------------------------------------------------------

for (c in cohorts) {

    for (i in outcomes_runall) {
    
    ## analysis: main ----------------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = all_covars,
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "main")
    
    ## analysis: sub_covid_hospitalised ----------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = all_covars,
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_covid_hospitalised")

    ## analysis: sub_covid_nonhospitalised -------------------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = all_covars,
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_covid_nonhospitalised")

    ## analysis: sub_covid_history ---------------------------------------------

    if (c!="prevax") {

      df[nrow(df)+1,] <- c(cohort = c,
                           exposure = exposure,
                           outcome = i,
                           ipw = ipw,
                           strata = strata,
                           covariate_sex = covariate_sex,
                           covariate_age = covariate_age,
                           covariate_other = all_covars,
                           cox_start = cox_start,
                           cox_stop = cox_stop,
                           study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                           study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
                           cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
                           controls_per_case = controls_per_case,
                           total_event_threshold = total_event_threshold,
                           episode_event_threshold = episode_event_threshold,
                           covariate_threshold = covariate_threshold,
                           age_spline = TRUE,
                           analysis = "sub_covid_history")

    }
  
    ## analysis: sub_sex_female ------------------------------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = "NULL",
                         covariate_age = covariate_age,
                         covariate_other = all_covars,
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_sex_female")

    ## analysis: sub_sex_male --------------------------------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = "NULL",
                         covariate_age = covariate_age,
                         covariate_other = all_covars,
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_sex_male")
    
    ## analysis: sub_age_18_39 ------------------------------------------------
    
    # df[nrow(df)+1,] <- c(cohort = c,
    #                      exposure = exposure, 
    #                      outcome = i,
    #                      ipw = ipw, 
    #                      strata = strata,
    #                      covariate_sex = covariate_sex,
    #                      covariate_age = covariate_age,
    #                      covariate_other = all_covars,
    #                      cox_start = cox_start,
    #                      cox_stop = cox_stop,
    #                      study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
    #                      study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
    #                      cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
    #                      controls_per_case = controls_per_case,
    #                      total_event_threshold = total_event_threshold,
    #                      episode_event_threshold = episode_event_threshold,
    #                      covariate_threshold = covariate_threshold,
    #                      age_spline = FALSE,
    #                      analysis = "sub_age_18_39")
    # 
    # ## analysis: sub_age_40_59 ------------------------------------------------
    # 
    # df[nrow(df)+1,] <- c(cohort = c,
    #                      exposure = exposure, 
    #                      outcome = i,
    #                      ipw = ipw, 
    #                      strata = strata,
    #                      covariate_sex = covariate_sex,
    #                      covariate_age = covariate_age,
    #                      covariate_other = all_covars,
    #                      cox_start = cox_start,
    #                      cox_stop = cox_stop,
    #                      study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
    #                      study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
    #                      cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
    #                      controls_per_case = controls_per_case,
    #                      total_event_threshold = total_event_threshold,
    #                      episode_event_threshold = episode_event_threshold,
    #                      covariate_threshold = covariate_threshold,
    #                      age_spline = FALSE,
    #                      analysis = "sub_age_40_59")
    # 
    # ## analysis: sub_age_60_79 ------------------------------------------------
    # 
    # df[nrow(df)+1,] <- c(cohort = c,
    #                      exposure = exposure, 
    #                      outcome = i,
    #                      ipw = ipw, 
    #                      strata = strata,
    #                      covariate_sex = covariate_sex,
    #                      covariate_age = covariate_age,
    #                      covariate_other = all_covars,
    #                      cox_start = cox_start,
    #                      cox_stop = cox_stop,
    #                      study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
    #                      study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
    #                      cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
    #                      controls_per_case = controls_per_case,
    #                      total_event_threshold = total_event_threshold,
    #                      episode_event_threshold = episode_event_threshold,
    #                      covariate_threshold = covariate_threshold,
    #                      age_spline = FALSE,
    #                      analysis = "sub_age_60_79")
    # 
    # ## analysis: sub_age_80_110 ------------------------------------------------
    # 
    # df[nrow(df)+1,] <- c(cohort = c,
    #                      exposure = exposure, 
    #                      outcome = i,
    #                      ipw = ipw, 
    #                      strata = strata,
    #                      covariate_sex = covariate_sex,
    #                      covariate_age = covariate_age,
    #                      covariate_other = all_covars,
    #                      cox_start = cox_start,
    #                      cox_stop = cox_stop,
    #                      study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
    #                      study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
    #                      cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
    #                      controls_per_case = controls_per_case,
    #                      total_event_threshold = total_event_threshold,
    #                      episode_event_threshold = episode_event_threshold,
    #                      covariate_threshold = covariate_threshold,
    #                      age_spline = FALSE,
    #                      analysis = "sub_age_80_110")
    
    ## analysis: sub_ethnicity_white -------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub("cov_cat_ethnicity;","",all_covars),
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_white")

    ## analysis: sub_ethnicity_black -------------------------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub("cov_cat_ethnicity;","",all_covars),
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_black")

    ## analysis: sub_ethnicity_mixed -------------------------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub("cov_cat_ethnicity;","",all_covars),
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_mixed")

    ## analysis: sub_ethnicity_asian -------------------------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub("cov_cat_ethnicity;","",all_covars),
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_asian")

    ## analysis: sub_ethnicity_other -------------------------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub("cov_cat_ethnicity;","",all_covars),
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"), #original study stop: 2021-06-18
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"), #original cut points: 28;197;365
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_other")

  }

    for (i in cognitive_impairment_sub_out) { #remove cov_bin_history_any_dementia

    ## analysis: sub_history_cognitive_impairment_true ---------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub("cov_bin_history_any_dementia;","",all_covars), #remove cov_bin_history_any_dementia
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_history_cognitive_impairment_true")

    ## analysis: sub_history_cognitive_impairment_false --------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub("cov_bin_history_any_dementia;","",all_covars),# remove cov_bin_history_any_dementia
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_history_cognitive_impairment_false")

    }

    for (i in parkinson_disease_sub_out) { #remove cov_bin_history_any_dementia

    ## analysis: sub_history_parkinson_true ---------------------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub("cov_bin_history_parkinson;","",all_covars), #remove cov_bin_history_parkinson
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_history_parkinson_true")

    ## analysis: sub_history_parkinson_false --------------------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub("cov_bin_history_parkinson;","",all_covars), #remove cov_bin_history_parkinson
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_history_parkinson_false")
    }
  
  for (i in vascular_risk_sub_out) { #remove cov_bin_history_alzheimer_disease, cov_bin_history_vascular_dementia, cov_bin_history_lewy_body, cov_bin_history_any_dementia, cov_bin_history_cog_imp_sympt

    ## analysis: sub_bin_vascular_risk_true --------------------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub("cov_bin_hypertension;|cov_bin_diabetes;","",all_covars), #remove cov_bin_hypertension & cov_bin_diabetes, history variables removed in make_model_input
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_bin_vascular_risk_true")

    ## analysis: sub_bin_vascular_risk_false -------------------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub("cov_bin_hypertension;|cov_bin_diabetes;","",all_covars), #remove cov_bin_hypertension & cov_bin_diabetes, history variables removed in make_model_input
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_bin_vascular_risk_false")

  }

  for (i in parkinson_risk_sub_out) { #remove cov_bin_history_parkinson

    ## analysis: sub_history_parkinson_risk_true ---------------------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub("cov_bin_history_parkinson;","",all_covars), # remove cov_bin_history_parkinson
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_history_parkinson_risk_true")

    ## analysis: sub_history_parkinson_risk_false --------------------------------------

    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure,
                         outcome = i,
                         ipw = ipw,
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub("cov_bin_history_parkinson;","",all_covars), # remove cov_bin_history_parkinson
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-12-14", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "1;28;197;365;714", "1;28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_history_parkinson_risk_false")
  }
}

# Assign unique name -----------------------------------------------------------

df$name <- paste0("cohort_",df$cohort, "-", 
                  df$analysis, "-", 
                  gsub("out_date_","",df$outcome))

# Remove covariate according to each outcome -----------------------------------
print("Removing coviriates according to each outcome")

for (i in 1:nrow(df)) {

  analysis <- df$analysis[i]
  outcome <- df$outcome[i]

  # Cognitive impairment symptoms

  if (outcome == "out_date_cognitive_impairment_symptoms" &
      analysis == "main" | analysis == "sub_covid_hospital" | analysis == "sub_covid_nonhospitalised" | analysis == "sub_covid_history" |
      analysis == "sub_sex_male" | analysis == "sub_sex_female" | analysis == "sub_ethnicity_white" | analysis == "sub_ethnicity_black" |
      analysis == "sub_ethnicity_mixed" | analysis == "sub_ethnicity_asian" | analysis == "sub_ethnicity_other" |
      analysis == "sub_history_cognitive_impairment_true" | analysis == "sub_history_cognitive_impairment_false" |
      analysis == "sub_bin_vascular_risk_true" | analysis == "sub_bin_vascular_risk_false") {

    df$covariate_other[i] <- gsub("cov_bin_history_cog_imp_sympt;", "", df$covariate_other[i])

  # Parkinson disease 

  } else if (outcome == "out_date_parkinson_disease" &
             analysis == "main" | analysis == "sub_covid_hospital" | analysis == "sub_covid_nonhospitalised" | analysis == "sub_covid_history" |
             analysis == "sub_sex_male" | analysis == "sub_sex_female" | analysis == "sub_ethnicity_white" | analysis == "sub_ethnicity_black" |
             analysis == "sub_ethnicity_mixed" | analysis == "sub_ethnicity_asian" | analysis == "sub_ethnicity_other" |
             analysis == "sub_history_parkinson_true" | analysis == "sub_history_parkinson_false" |
             analysis == "sub_history_parkinson_risk_true" | analysis == "sub_history_parkinson_risk_false") {

    df$covariate_other[i] <- gsub("cov_bin_history_parkinson;", "", df$covariate_other[i])
    
  # Alzheimer 

  } else if (outcome == "out_date_alzheimer_disease" |
             analysis == "main" | analysis == "sub_covid_hospital" | analysis == "sub_covid_nonhospitalised" | analysis == "sub_covid_history" |
             analysis == "sub_sex_male" | analysis == "sub_sex_female" | analysis == "sub_ethnicity_white" | analysis == "sub_ethnicity_black" |
             analysis == "sub_ethnicity_mixed" | analysis == "sub_ethnicity_asian" | analysis == "sub_ethnicity_other" |
             analysis == "sub_bin_vascular_risk_true" | analysis == "sub_bin_vascular_risk_false") {

    df$covariate_other[i] <- gsub("cov_bin_history_alzheimer_disease;", "", df$covariate_other[i])

  # Vascular dementia 

  } else if (outcome == "out_date_vascular_dementia" &
             analysis == "main" | analysis == "sub_covid_hospital" | analysis == "sub_covid_nonhospitalised" | analysis == "sub_covid_history" |
             analysis == "sub_sex_male" | analysis == "sub_sex_female" | analysis == "sub_ethnicity_white" | analysis == "sub_ethnicity_black" |
             analysis == "sub_ethnicity_mixed" | analysis == "sub_ethnicity_asian" | analysis == "sub_ethnicity_other" |
             analysis == "sub_bin_vascular_risk_true" | analysis == "sub_bin_vascular_risk_false") {

    df$covariate_other[i] <- gsub("cov_bin_history_vascular_dementia;", "", df$covariate_other[i])

  # Lewy body 

  } else if (outcome == "out_date_lewy_body_dementia" &
             analysis == "main" | analysis == "sub_covid_hospital" | analysis == "sub_covid_nonhospitalised" | analysis == "sub_covid_history" |
             analysis == "sub_sex_male" | analysis == "sub_sex_female" | analysis == "sub_ethnicity_white" | analysis == "sub_ethnicity_black" |
             analysis == "sub_ethnicity_mixed" | analysis == "sub_ethnicity_asian" | analysis == "sub_ethnicity_other" |
             analysis == "sub_bin_vascular_risk_true" | analysis == "sub_bin_vascular_risk_false") {

    df$covariate_other[i] <- gsub("cov_bin_history_lewy_body_dementia;", "", df$covariate_other[i])

  }
}
 
# Remove covariate according to outcome (outsde loop) --------------------------
# Note: gsub and stringr not working for any_dementia, motor neurone disease, multiple sclerosis, and migraine
print("Remove covariate according to outcome (outside loop)")
 
  # Any dementia (50)
  print("Create dataframe for any dementia")
  
  any_dementia <- df |>
    subset(outcome == "out_date_any_dementia")
  any_dementia_covars <- c("cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_ckd;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_copd;cov_bin_ami;cov_bin_isch;cov_bin_history_cog_imp_sympt;cov_bin_history_mnd;cov_bin_history_migraine;cov_bin_history_parkinson;cov_bin_history_ms;cov_bin_history_parkinson_risk")
  any_dementia$covariate_other <- NULL
  any_dementia[,"covariate_other"] <- any_dementia_covars
  
  # Motor neurone disease (32)
  print("Create dataframe for motor neurone disease")
  
  mnd <- df |>
    subset(outcome == "out_date_motor_neurone_disease")
  mnd_covars <- c("cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_ckd;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_copd;cov_bin_ami;cov_bin_isch;cov_bin_history_cog_imp_sympt;cov_bin_history_migraine;cov_bin_history_any_dementia;cov_bin_history_parkinson;cov_bin_history_ms;cov_bin_history_parkinson_risk")
  mnd$covariate_other <- NULL
  mnd[,"covariate_other"] <- mnd_covars
  
  # Multiple sclerosis (32)
  print("Create dataframe for multiple sclerosis")
  
  ms <- df |>
    subset(outcome == "out_date_multiple_sclerosis")
  ms_covars <- c("cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_ckd;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_copd;cov_bin_ami;cov_bin_isch;cov_bin_history_cog_imp_sympt;cov_bin_history_mnd;cov_bin_history_migraine;cov_bin_history_any_dementia;cov_bin_history_parkinson;cov_bin_history_parkinson_risk")
  ms$covariate_other <- NULL
  ms[,"covariate_other"] <- ms_covars
  
  # Migraine (32)
  print("Create dataframe for migriane")
  
  migraine <- df |>
    subset(outcome == "out_date_migraine")
  migraine_covars <- c("cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_ckd;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_copd;cov_bin_ami;cov_bin_isch;cov_bin_history_cog_imp_sympt;cov_bin_history_mnd;cov_bin_history_any_dementia;cov_bin_history_parkinson;cov_bin_history_ms;cov_bin_history_parkinson_risk")
  migraine$covariate_other <- NULL
  migraine[,"covariate_other"] <- migraine_covars

  # Remove outcomes from original dataframe (any_dementia, multiple sclerosis, motor neurone disease, migraine)
  print("Remove rows for outcomes any_dementia, multiple sclerosis, motor neurone disease, migraine")
  
  df <- df[!(df$outcome == "out_date_migraine" | df$outcome == "out_date_multiple_sclerosis" | df$outcome == "out_date_motor_neurone_disease" | df$outcome == "out_date_any_dementia"),] 
  
  # Combine in one dataframe
  print("Comnine all dataframes into one")
  
  df <- as.data.frame(Reduce(function(x,y) merge(x, y, all = TRUE), list(df, any_dementia, mnd, ms, migraine)))
  
  # Remove any dementia, motor neurone disease, multiple sclerosis, and migraine from environment
  print("Remove subset dataframes")
  
  rm(any_dementia, mnd, ms, migraine)

# Check names are unique and save active analyses list -------------------------

if (length(unique(df$name))==nrow(df)) {
  saveRDS(df, file = "lib/active_analyses.rds", compress = "gzip")
} else {
  stop(paste0("ERROR: names must be unique in active analyses table"))
}