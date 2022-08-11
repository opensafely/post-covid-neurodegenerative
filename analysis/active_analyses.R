# Create output directory ------------------------------------------------------

fs::dir_create(here::here("lib"))

# Create empty data frame ------------------------------------------------------

df <- data.frame(active = logical(),
                 outcome = character(),
                 outcome_group = character(),
                 outcome_variable = character(),
                 covariates = character(),
                 model = character(),
                 main = character(),
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
                 venn = character(),
                 stringsAsFactors = FALSE)

# Add neurodegenerative outcomes

outcomes <- c("Dementia - Probable Alzheimer disease",
              "Dementia - Possible Alzheimer disease",
              "Dementia - Vascular dementia",
              "Dementia - Other dementias",
              "Dementia - Any dementia",
              "Dementia - Cognitive impairment",
              "Parkinson - Parkinson disease",
              "Parkinson - Restless leg syndrome",
              "Parkinson - REM sleep disorder",
              "Other - Motor neurone disease",
              "Other - Multiple sclerosis")

outcome_group <- "neurodegenerative_diseases"

outcomes_short <- c("dementia_probable_alzheimer_disease",
                    "dementia_possible_alzheimer-disease",
                    "dementia_vascular_dementia",
                    "dementia_other_dementias",
                    "dementia_any_dementia",
                    "dementia_dognitive_impairment",
                    "parkinson_parkinson_disease",
                    "parkinson_restless_leg_syndrome",
                    "parkinson_rem_sleep_disorder",
                    "other_motor_neurone_disease",
                    "other_multiple_sclerosis")

out_venn <- c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE)

for (i in 1:length(outcomes)) {
  df[nrow(df)+1,] <- c(FALSE,
                       outcomes[i],
                       outcome_group,
                       paste0("out_date_",outcomes_short[i]),
                       "cov_num_age;cov_cat_sex;cov_cat_ethnicity;cov_cat_deprivation;cov_cat_region;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch",
                       rep("all",1),
                       rep(TRUE,3),
                       rep(FALSE,14),
                       "",
                       out_venn[i])
}

# df[6,1] <- TRUE

# Save active analyses list ----------------------------------------------------

saveRDS(df, file = "lib/active_analyses.rds")