# Create output directory ------------------------------------------------------

fs::dir_create(here::here("lib"))

# Create empty data frame ------------------------------------------------------

df <- data.frame(active = logical(),
                 outcome = character(),
                 outcome_variable = character(),
                 covariates = character(),
                 model = character(),
                 cohort	= character(),
                 main = character(),
                 covid_history = character(),
                 covid_pheno_hospitalised = character(),
                 covid_pheno_non_hospitalised = character(),
                 agegp_18_39 = character(),
                 agegp_40_59 = character(),
                 agegp_60_79 = character(),
                 agegp_80_110 = character(),
                 sex_Male = character(),
                 sex_Female = character(),
                 ethnicity_White = character(),
                 ethnicity_Mixed = character(),
                 ethnicity_South_Asian = character(),
                 ethnicity_Black = character(),
                 ethnicity_Other = character(),
                 ethnicity_Missing = character(),
                 prior_history_TRUE = character(),
                 prior_history_FALSE = character(),
                 prior_history_var = character(), 
                 outcome_group = character(),
                 venn = character(),
                 stringsAsFactors = FALSE)

# Add neurodegenerative outcomes

outcomes <- c("Alzheimer disease",
              "Vascular dementia",
              "Other dementias",
              "Unspecified dementias",
              "Any dementia",
              "Cognitive impairment",
              "Parkinson",
              "Restless leg syndrome",
              "REM sleep disorder",
              "Motor neurone disease",
              "Multiple sclerosis",
              "Migraine")

outcome_group <- "Neurodegenerative_diseases"

outcomes_short <- c("alzheimer_disease",
                    "vascular_dementia",
                    "other_dementias",
                    "unspecified_dementias",
                    "any_dementia",
                    "cognitive_impairment",
                    "parkinson",
                    "restless_leg_syndrome",
                    "rem_sleep_disorder",
                    "motor_neurone_disease",
                    "multiple_sclerosis",
                    "migraine")

out_venn <- c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE)

for (i in 1:length(outcomes)) {
  df[nrow(df)+1,] <- c(TRUE,
                       outcomes[i],
                       outcome_group,
                       paste0("out_date_",outcomes_short[i]),
                       "cov_num_age;cov_cat_sex;cov_cat_ethnicity;cov_cat_deprivation;cov_cat_region;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_bin_hypercholesterolaemia",
                       rep("all",2),
                       rep(TRUE,16),
                       rep(FALSE,2),
                       "",
                       "neurodegenerative_diseases",
                       out_venn[i])
}

# df[6,1] <- TRUE

# Save active analyses list ----------------------------------------------------

saveRDS(df, file = "lib/active_analyses.rds")