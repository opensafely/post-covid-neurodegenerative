# Import libraries ----
print("Import libraries")

library('tidyverse')
library('here')

# Create output/dataset_definition directory ----
print("Create output/dataset_definition directory")

fs::dir_create(here::here("output/dataset_definition"))

# create study_dates ----
print("Create study_labels")

study_labels <-
  list(
    c("prevax", "Pre-vaccine availability (Jan 1 2020 - Jun 18 2021)", "", ""),
    c("vax", "Vaccinated (Jun 1 2021 - March April 2024)", "", ""),
    c("unvax", "Unvaccinated (Jun 1 2021 - April 30 2024)", "", ""),
    c("main", "All COVID-19", "main", "1"),
    c("sub_age_18_39", "Age group: 18-39", "age", "1"),
    c("sub_age_40_64", "Age group: 40-64", "age", "2"),
    c("sub_age_65_84", "Age group: 65-84", "age", "3"),
    c("sub_age_85_110", "Age group: 85-110", "age", "4"),
    c("sub_covid_hospitalised", "Hospitalised COVID-19", "main", "2"),
    c("sub_covid_nonhospitalised", "Non-hospitalised COVID-19", "main", "3"),
    c("sub_ethnicity_asian", "Ethnicity: South Asian", "ethnicity", "2"),
    c("sub_ethnicity_black", "Ethnicity: Black", "ethnicity", "3"),
    c("sub_ethnicity_mixed", "Ethnicity: Mixed", "ethnicity", "4"),
    c("sub_ethnicity_other", "Ethnicity: Other", "ethnicity", "5"),
    c("sub_ethnicity_white", "Ethnicity: White", "ethnicity", "1"),
    c("sub_sex_female", "Sex: Female", "sex", "1"),
    c("sub_sex_male", "Sex: Male", "sex", "2"),
    c("sub_covid_history", "History of COVID-19", "history_exposure", "1"),
    c("cov_bin_ami", "Acute myocardial infarction", "", ""),
    c("cov_bin_cancer", "Cancer", "", ""),
    c("cov_bin_carehome", "Care Home Resident", "", ""),
    c("cov_bin_ckd", "Chronic kidney disease ", "", ""),
    c("cov_cat_consrate2019", "GP consultations in 2019", "", ""),
    c("cov_bin_copd", "Chronic obstructive pulmonary disease ", "", ""),
    c("cov_bin_depression", "Depression", "", ""),
    c("cov_bin_diabetes", "Diabetes", "", ""),
    c("cov_bin_hcworker", "Healthcare worker", "", ""),
    c("cov_bin_hypertension", "Hypertension", "", ""),
    c("cov_bin_liver_disease", "Liver disease", "", ""),
    c("cov_bin_obesity", "Obesity", "", ""),
    c("cov_bin_stroke_isch", "Ischaemic stoke", "", ""),
    c("cov_bin_cis", "History of Cognitive Impairment Symptoms", "", ""),
    c("cov_bin_dem_any", "History of Dementia (Any)", "", ""),
    c("cov_bin_high_vasc_risk", "History of High Vascular Risk", "", ""),
    c("cov_bin_mnd", "History of Motor Neurone Disease", "", ""),
    c("cov_bin_ms", "History of Multiple Sclerosis", "", ""),
    c("cov_bin_migraine", "History of Migraine", "", ""),
    c("cov_bin_park", "History of Parkinson's", "", ""),
    c("cov_bin_park_risk", "History of Parkinson's Risk Factors", "", ""),
    c("All", "All", "", ""),
    c("main", "All COVID-19", "day0_main", "1"),
    c("sub_history_none", "No prior history of event", "day0_history_outcome", "1"),
    c("sub_history_notrecent", "\"Prior history of event, more than six months ago\"", "day0_history_outcome", "3"),
    c("sub_history_recent", "\"Prior history of event, within six months\"", "day0_history_outcome", "2"),
    c("sub_sex_female", "Sex: Female", "day0_sex", "1"),
    c("sub_sex_male", "Sex: Male", "day0_sex", "2"),
    c("sub_covid_history", "History of COVID-19", "day0_history_exposure", "1"),
    c("cov_cat_age_group", "\"Age, years\"", "", ""),
    c("cov_cat_sex", "Sex", "", ""),
    c("cov_cat_ethnicity", "Ethnicity", "", ""),
    c("cov_cat_imd", "Index of multiple deprivation quintile", "", ""),
    c("cov_cat_smoking", "Smoking status", "", ""),
    c("strat_cat_region", "Region", "", "")
  )


df_study_labels <- t(data.frame(study_labels))

colnames(df_study_labels) <-   c("term", "label", "analysis_group", "ref")

# Save study_dates ----
print("Save study_labels")

write.csv(df_study_labels, "output/study_labels.csv", row.names = FALSE, quote=F)

