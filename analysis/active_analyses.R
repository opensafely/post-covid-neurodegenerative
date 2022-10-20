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
                 priorhistory_var = character(),
                 stringsAsFactors = FALSE)

# Set constant values ----------------------------------------------------------

ipw <- TRUE
age_spline <- TRUE
exposure <- "exp_date_covid19_confirmed"
strata <- "cov_cat_region"
covariate_sex <- "cov_cat_sex"
covariate_age <- "cov_num_age"
cox_start <- "index_date"
cox_stop <- "end_date"
cut_points <- "28;197"
controls_per_case <- 20L
total_event_threshold <- 50L
episode_event_threshold <- 5L
covariate_threshold <- 5L

# Specify cohorts --------------------------------------------------------------

cohorts <- c("vax","unvax","prevax")

# Specify outcomes -------------------------------------------------------------

outcomes_runall <- c("out_date_alzheimer_disease", 
                     "out_date_parkinson_disease")

outcomes_runmain <- c("out_date_vascular_dementia",
                      "out_date_other_dementias",
                      "out_date_unspecified_dementias",
                      "out_date_any_dementia",
                      "out_date_cognitive_impairment",
                      "out_date_restless_leg_syndrome",
                      "out_date_rem_sleep_disorder",
                      "out_date_motor_neurone_disease",
                      "out_date_multiple_sclerosis",
                      "out_date_migraine")

# Add active analyses ----------------------------------------------------------

for (c in cohorts) {
  
  for (i in c(outcomes_runmain, outcomes_runall)) {
    
    ## analysis: main ----------------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "main",
                         priorhistory_var = "")
    
    ## analysis: sub_covid_hospitalised ----------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_covid_hospitalised",
                         priorhistory_var = "")
    
    ## analysis: sub_covid_nonhospitalised -------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_covid_nonhospitalised",
                         priorhistory_var = "")
    
    ## analysis: sub_covid_history ---------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_covid_history",
                         priorhistory_var = "")
    
  }
  
  for (i in outcomes_runall) {
    
    ## analysis: sub_sex_female ------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = "",
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_sex_female",
                         priorhistory_var = "")
    
    ## analysis: sub_sex_male --------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = "",
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_sex_male",
                         priorhistory_var = "")
    
    ## analysis: sub_age_18_39 ------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = FALSE,
                         analysis = "sub_age_18_39",
                         priorhistory_var = "")
    
    ## analysis: sub_age_40_59 ------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = FALSE,
                         analysis = "sub_age_40_59",
                         priorhistory_var = "")
    
    ## analysis: sub_age_60_79 ------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = FALSE,
                         analysis = "sub_age_60_79",
                         priorhistory_var = "")
    
    ## analysis: sub_age_80_110 ------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = FALSE,
                         analysis = "sub_age_80_110",
                         priorhistory_var = "")
    
    ## analysis: sub_ethnicity_white -------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_white",
                         priorhistory_var = "")
    
    ## analysis: sub_ethnicity_black -------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_black",
                         priorhistory_var = "")
    
    ## analysis: sub_ethnicity_mixed -------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_mixed",
                         priorhistory_var = "")
    
    ## analysis: sub_ethnicity_asian -------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_asian",
                         priorhistory_var = "")
    
    ## analysis: sub_ethnicity_other -------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = cut_points,
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_other",
                         priorhistory_var = "")
    
    ## analysis: sub_priorhistory_true -----------------------------------------
    
    # df[nrow(df)+1,] <- c(cohort = c,
    #                      exposure = exposure, 
    #                      outcome = i,
    #                      ipw = ipw, 
    #                      strata = strata,
    #                      covariate_sex = covariate_sex,
    #                      covariate_age = covariate_age,
    #                      covariate_other = gsub(";;",";",gsub(gsub("out_date","cov_bin_history",i),"","cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia")),
    #                      cox_start = cox_start,
    #                      cox_stop = cox_stop,
    #                      study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
    #                      study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
    #                      cut_points = cut_points,
    #                      controls_per_case = controls_per_case,
    #                      total_event_threshold = total_event_threshold,
    #                      episode_event_threshold = episode_event_threshold,
    #                      covariate_threshold = covariate_threshold,
    #                      age_spline = TRUE,
    #                      analysis = "sub_priorhistory_true",
    #                      priorhistory_var = gsub("out_date","cov_bin_history",i))
    
    # ## analysis: sub_priorhistory_false ----------------------------------------
    # 
    # df[nrow(df)+1,] <- c(cohort = c,
    #                      exposure = exposure, 
    #                      outcome = i,
    #                      ipw = ipw, 
    #                      strata = strata,
    #                      covariate_sex = covariate_sex,
    #                      covariate_age = covariate_age,
    #                      covariate_other = gsub(";;",";",gsub(gsub("out_date","cov_bin_history",i),"","cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia")),
    #                      cox_start = cox_start,
    #                      cox_stop = cox_stop,
    #                      study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
    #                      study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
    #                      cut_points = cut_points,
    #                      controls_per_case = controls_per_case,
    #                      total_event_threshold = total_event_threshold,
    #                      episode_event_threshold = episode_event_threshold,
    #                      covariate_threshold = covariate_threshold,
    #                      age_spline = TRUE,
    #                      analysis = "sub_priorhistory_false",
    #                      priorhistory_var = gsub("out_date","cov_bin_history",i))
    
    ## analysis: sub_priorhistory_true -----------------------------------------
    
    # df[nrow(df)+1,] <- c(cohort = c,
    #                      exposure = exposure, 
    #                      outcome = i,
    #                      ipw = ipw, 
    #                      strata = strata,
    #                      covariate_sex = covariate_sex,
    #                      covariate_age = covariate_age,
    #                      covariate_other = gsub(";;",";",gsub(gsub("out_date","cov_bin_recent",i),"","cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia")),
    #                      cox_start = cox_start,
    #                      cox_stop = cox_stop,
    #                      study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
    #                      study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
    #                      cut_points = cut_points,
    #                      controls_per_case = controls_per_case,
    #                      total_event_threshold = total_event_threshold,
    #                      episode_event_threshold = episode_event_threshold,
    #                      covariate_threshold = covariate_threshold,
    #                      age_spline = TRUE,
    #                      analysis = "sub_priorhistory_true",
    #                      priorhistory_var = gsub("out_date","cov_bin_recent",i))
    
    ## analysis: sub_priorhistory_false ----------------------------------------
    
    # df[nrow(df)+1,] <- c(cohort = c,
    #                      exposure = exposure, 
    #                      outcome = i,
    #                      ipw = ipw, 
    #                      strata = strata,
    #                      covariate_sex = covariate_sex,
    #                      covariate_age = covariate_age,
    #                      covariate_other = gsub(";;",";",gsub(gsub("out_date","cov_bin_recent",i),"","cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia")),
    #                      cox_start = cox_start,
    #                      cox_stop = cox_stop,
    #                      study_start = ifelse(i=="prevax", "2020-01-01", "2021-06-01"),
    #                      study_stop = ifelse(i=="prevax", "2021-06-18", "2021-12-14"),
    #                      cut_points = cut_points,
    #                      controls_per_case = controls_per_case,
    #                      total_event_threshold = total_event_threshold,
    #                      episode_event_threshold = episode_event_threshold,
    #                      covariate_threshold = covariate_threshold,
    #                      age_spline = TRUE,
    #                      analysis = "sub_priorhistory_false",
    #                      priorhistory_var = gsub("out_date","cov_bin_recent",i))
    
  }
  
}

# Assign unique name -----------------------------------------------------------

df$name <- paste0("cohort_",df$cohort, "-", 
                  gsub("out_date_","",df$outcome), "-", 
                  df$analysis, 
                  ifelse(df$priorhistory_var=="","", paste0("-",df$priorhistory_var)))

# Fix anxiety prior history variables ------------------------------------------

# df$priorhistory_var <- ifelse(df$priorhistory_var=="cov_bin_history_anxiety_general",
#                               "cov_bin_history_anxiety",
#                               df$priorhistory_var)
# 
# df$priorhistory_var <- ifelse(df$priorhistory_var=="cov_bin_recent_anxiety_general",
#                               "cov_bin_recent_anxiety",
#                               df$priorhistory_var)

# Check names are unique and save active analyses list -------------------------

if (length(unique(df$name))==nrow(df)) {
  saveRDS(df, file = "lib/active_analyses.rds")
} else {
  stop(paste0("ERROR: names must be unique in active analyses table"))
}