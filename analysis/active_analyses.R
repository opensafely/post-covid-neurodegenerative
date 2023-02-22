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
cox_stop <- "end_date"
#controls_per_case <- 20L
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
  
  #ipw <- ifelse(c=="unvax", FALSE, TRUE)
  
  for (i in c(outcomes_runmain, outcomes_runall)) {
    
    ## analysis: main ----------------------------------------------------------
    
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
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
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
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
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
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
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
                           covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                           cox_start = cox_start,
                           cox_stop = cox_stop,
                           study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                           study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                           cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                           #controls_per_case = controls_per_case,
                           total_event_threshold = total_event_threshold,
                           episode_event_threshold = episode_event_threshold,
                           covariate_threshold = covariate_threshold,
                           age_spline = TRUE,
                           analysis = "sub_covid_history")
      
    }
    
  }
  
  for (i in outcomes_runall) {
    
    ## analysis: sub_sex_female ------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = "NULL",
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
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
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_sex_male")
    
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
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = FALSE,
                         analysis = "sub_age_18_39")
    
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
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = FALSE,
                         analysis = "sub_age_40_59")
    
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
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = FALSE,
                         analysis = "sub_age_60_79")
    
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
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = FALSE,
                         analysis = "sub_age_80_110")
    
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
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
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
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
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
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
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
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
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
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_all_stroke;cov_bin_hypercholesterolaemia",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax", "2020-01-01", "2021-06-01"),
                         study_stop = ifelse(c=="prevax", "2021-06-18", "2021-12-14"),
                         cut_points = ifelse(c=="prevax", "28;197;535", "28;197"),
                         #controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_other")
    
  }
  
}

# Assign unique name -----------------------------------------------------------

df$name <- paste0("cohort_",df$cohort, "-", 
                  df$analysis, "-", 
                  gsub("out_date_","",df$outcome))

# Fix anxiety prior history variables ------------------------------------------

# Check names are unique and save active analyses list -------------------------

if (length(unique(df$name))==nrow(df)) {
  saveRDS(df, file = "lib/active_analyses.rds", compress = "gzip")
} else {
  stop(paste0("ERROR: names must be unique in active analyses table"))
}