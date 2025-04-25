# Setup
from ehrql import codelist_from_csv


###########################
#       Exposure(s)       #
###########################

# Covid
covid_codes = codelist_from_csv(
  "codelists/user-RochelleKnight-confirmed-hospitalised-covid-19.csv",
  column = "code"
)
covid_primary_care_positive_test = codelist_from_csv(
  "codelists/opensafely-covid-identification-in-primary-care-probable-covid-positive-test.csv",
  column = "CTV3ID"
)
covid_primary_care_code = codelist_from_csv(
  "codelists/opensafely-covid-identification-in-primary-care-probable-covid-clinical-code.csv",
  column = "CTV3ID"
)
covid_primary_care_sequalae = codelist_from_csv(
  "codelists/opensafely-covid-identification-in-primary-care-probable-covid-sequelae.csv",
  column = "CTV3ID"
)

###########################
#   Common covariate(s)   #
###########################

# Ethnicity
ethnicity_snomed = codelist_from_csv(
  "codelists/opensafely-ethnicity-snomed-0removed.csv",
  column = "code",
  category_column = "Grouping_6"
)
# primis_covid19_vacc_update_ethnicity = codelist_from_csv(
#     "codelists/primis-covid19-vacc-uptake-eth2001.csv",
#     column="code",
#     category_column="grouping_6_id"
# )

# Smoking
smoking_clear = codelist_from_csv(
  "codelists/opensafely-smoking-clear.csv",
  column = "CTV3Code",
  category_column = "Category"
)
smoking_unclear = codelist_from_csv(
  "codelists/opensafely-smoking-unclear.csv",
  column = "CTV3Code",
  category_column = "Category"
)
ever_current_smoke = codelist_from_csv(
  "codelists/bristol-smoke-and-eversmoke.csv",
  column = "code"
)

# BMI
bmi_obesity_snomed = codelist_from_csv(
  "codelists/user-elsie_horne-bmi_obesity_snomed.csv",
  column = "code"
)
bmi_obesity_icd10 = codelist_from_csv(
  "codelists/user-elsie_horne-bmi_obesity_icd10.csv",
  column = "code"
)
bmi_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-bmi.csv",
  column = "code"
)

# Carer codes
# carer_primis = codelist_from_csv(
#     "codelists/primis-covid19-vacc-uptake-carer.csv",
#     column="code"
# )

# No longer a carer codes
# notcarer_primis = codelist_from_csv(
#     "codelists/primis-covid19-vacc-uptake-notcarer.csv",
#     column="code"
# )

# Wider Learning Disability
learndis_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-learndis.csv",
  column = "code"
)

# Employed by Care Home codes
# carehome_primis = codelist_from_csv(
#     "codelists/primis-covid19-vacc-uptake-carehome.csv",
#     column="code"
# )

# Employed by nursing home codes
# nursehome_primis = codelist_from_csv(
#     "codelists/primis-covid19-vacc-uptake-nursehome.csv",
#     column="code"
# )

# Employed by domiciliary care provider codes
# domcare_primis = codelist_from_csv(
#     "codelists/primis-covid19-vacc-uptake-domcare.csv",
#     column="code"
# )

# Patients in long-stay nursing and residential care
longres_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-longres.csv",
  column = "code"
)

# High Risk from COVID-19 code
shield_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-shield.csv",
  column = "code"
)

# Lower Risk from COVID-19 codes
nonshield_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-nonshield.csv",
  column = "code"
)

# For JCVI groups

## Pregnancy codes
preg_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-preg.csv",
  column = "code"
)

## Pregnancy or Delivery codes
pregdel_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-pregdel.csv",
  column = "code"
)

## All BMI coded terms
bmi_stage_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-bmi_stage.csv",
  column = "code"
)

## Severe Obesity code recorded
sev_obesity_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-sev_obesity.csv",
  column = "code"
)

## Asthma Diagnosis code
ast_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-ast.csv",
  column = "code"
)

## Asthma Admission codes
astadm_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-astadm.csv",
  column = "code"
)

## Asthma systemic steroid prescription codes
astrx_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-astrx.csv",
  column = "code"
)

## Chronic Respiratory Disease
resp_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-resp_cov.csv",
  column = "code"
)

## Chronic Neurological Disease including Significant Learning Disorder
cns_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-cns_cov.csv",
  column = "code"
)

## Asplenia or Dysfunction of the Spleen codes
spln_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-spln_cov.csv",
  column = "code"
)

## Diabetes diagnosis codes
diab_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-diab.csv",
  column = "code"
)

## Diabetes resolved codes
dmres_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-dmres.csv",
  column = "code"
)

## Severe Mental Illness codes
sev_mental_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-sev_mental.csv",
  column = "code"
)

## Remission codes relating to Severe Mental Illness
smhres_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-smhres.csv",
  column = "code"
)

## Chronic heart disease codes
chd_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-chd_cov.csv",
  column = "code"
)

## Chronic kidney disease diagnostic codes
ckd_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-ckd_cov.csv",
  column = "code"
)

## Chronic kidney disease codes - all stages
ckd15_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-ckd15.csv",
  column = "code"
)

## Chronic kidney disease codes-stages 3 - 5
ckd35_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-ckd35.csv",
  column = "code"
)

## Chronic Liver disease codes
cld_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-cld.csv",
  column = "code"
)

## Immunosuppression diagnosis codes
immdx_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-immdx_cov.csv",
  column = "code"
)

## Immunosuppression medication codes
immrx_primis = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-immrx.csv",
  column = "code"
)

# Stroke Ischaemic (Ischaemic Stroke)
stroke_isch_snomed = codelist_from_csv(
  "codelists/user-elsie_horne-stroke_isch_snomed.csv",
  column = "code"
)
stroke_isch_icd10 = codelist_from_csv(
  "codelists/user-RochelleKnight-stroke_isch_icd10.csv",
  column = "code"
)

# Liver disease
liver_disease_snomed = codelist_from_csv(
  "codelists/user-elsie_horne-liver_disease_snomed.csv",
  column = "code"
)
liver_disease_icd10 = codelist_from_csv(
  "codelists/user-elsie_horne-liver_disease_icd10.csv",
  column = "code"
)

# COPD
copd_ctv3 = codelist_from_csv(
  "codelists/opensafely-current-copd.csv",
  column = "CTV3ID"
)
copd_icd10 = codelist_from_csv(
  "codelists/user-elsie_horne-copd_icd10.csv",
  column = "code"
)

# Chronic Kidney Disease (CKD)
ckd_snomed = codelist_from_csv(
  "codelists/user-elsie_horne-ckd_snomed.csv",
  column = "code"
)
ckd_icd10 = codelist_from_csv(
  "codelists/user-elsie_horne-ckd_icd10.csv",
  column = "code"
)

# Cancer
cancer_snomed = codelist_from_csv(
  "codelists/user-elsie_horne-cancer_snomed.csv",
  column = "code"
)
cancer_icd10 = codelist_from_csv(
  "codelists/user-elsie_horne-cancer_icd10.csv",
  column = "code"
)

# Hypertension
hypertension_icd10 = codelist_from_csv(
  "codelists/user-elsie_horne-hypertension_icd10.csv",
  column = "code"
)
hypertension_drugs_dmd = codelist_from_csv(
  "codelists/user-elsie_horne-hypertension_drugs_dmd.csv",
  column = "dmd_id"
)
hypertension_snomed = codelist_from_csv(
  "codelists/nhsd-primary-care-domain-refsets-hyp_cod.csv",
  column = "code"
)

# Diabetes
diabetes_icd10 = codelist_from_csv(
  "codelists/user-elsie_horne-diabetes_icd10.csv",
  column = "code"
)
diabetes_drugs_dmd = codelist_from_csv(
  "codelists/user-elsie_horne-diabetes_drugs_dmd.csv",
  column = "dmd_id"
)
diabetes_snomed = codelist_from_csv(
  "codelists/user-elsie_horne-diabetes_snomed.csv",
  column = "code"
)

# Depression
depression_snomed = codelist_from_csv(
  "codelists/user-hjforbes-depression-symptoms-and-diagnoses.csv",
  column = "code"
)
depression_icd10 = codelist_from_csv(
  "codelists/user-kurttaylor-depression_icd10.csv",
  column = "code"
)

# AMI (Acute Myocardial Infarction)
ami_snomed = codelist_from_csv(
  "codelists/user-elsie_horne-ami_snomed.csv",
  column = "code"
)
ami_icd10 = codelist_from_csv(
  "codelists/user-RochelleKnight-ami_icd10.csv",
  column = "code"
)
ami_prior_icd10 = codelist_from_csv(
  "codelists/user-elsie_horne-ami_prior_icd10.csv",
  column = "code"
)

#Quality assurance codes
prostate_cancer_snomed = codelist_from_csv(
  "codelists/user-RochelleKnight-prostate_cancer_snomed.csv",
  column = "code"
)
prostate_cancer_icd10 = codelist_from_csv(
  "codelists/user-RochelleKnight-prostate_cancer_icd10.csv",
  column = "code"
)
pregnancy_snomed = codelist_from_csv(
  "codelists/user-RochelleKnight-pregnancy_and_birth_snomed.csv",
  column = "code"
)
cocp_dmd = codelist_from_csv(
  "codelists/user-elsie_horne-cocp_dmd.csv",
  column = "dmd_id"
)
hrt_dmd = codelist_from_csv(
  "codelists/user-elsie_horne-hrt_dmd.csv",
  column = "dmd_id"
)

###########################
# Neurodegenerative codes #
###########################

# Dementia (Dem)

# Alzheimer's disease
dem_alz_snomed = codelist_from_csv(
  "codelists/bristol-alzheimers-disease-snomed-ct-v13.csv",
  column = "code",
)
dem_alz_icd10 = codelist_from_csv(
  "codelists/bristol-alzheimers-disease-icd10-v13.csv",
  column = "code",
)

# Vascular dementia
dem_vasc_snomed = codelist_from_csv(
  "codelists/bristol-vascular-dementia-snomed-ct-v13.csv",
  column = "code",
)
dem_vasc_icd10 = codelist_from_csv(
  "codelists/bristol-vascular-dementia-icd10-v13.csv",
  column = "code",
)

# Lewy body disease
dem_lb_snomed = codelist_from_csv(
  "codelists/bristol-lewy-body-dementia-snomed-v1.csv",
  column = "code"
)

# Other dementias
dem_other_snomed = codelist_from_csv(
  "codelists/bristol-other-dementias-snomed-ct-v13.csv",
  column = "code",
)
dem_other_icd10 = codelist_from_csv(
  "codelists/bristol-other-dementias-icd10-v13.csv",
  column = "code",
)

# Unspecified dementias
dem_unspec_snomed = codelist_from_csv(
  "codelists/bristol-unspecified-dementia-snomed-ct-v13.csv",
  column = "code",
)
dem_unspec_icd10 = codelist_from_csv(
  "codelists/bristol-unspecified-dementia-icd10-v13.csv",
  column = "code",
)

# Cognitive Impairment - Symptoms (CIS)
cis_snomed = codelist_from_csv(
  "codelists/opensafely-symptoms-cognitive-impairment.csv",
  column = "code",
)

# Parkinson's disease (Park)
park_snomed = codelist_from_csv(
  "codelists/bristol-parkinsons-disease-snomed-ct-v13.csv",
  column = "code",
)
park_icd10 = codelist_from_csv(
  "codelists/bristol-parkinsons-disease-icd10-v13.csv",
  column = "code",
)

# Restless Leg Syndrome (RLS)
rls_snomed = codelist_from_csv(
  "codelists/bristol-restless-leg-syndrome-snomed-ct-v13.csv",
  column = "code",
)

# REM sleep disorder (RSD)
rsd_snomed = codelist_from_csv(
  "codelists/bristol-rem-sleep-disorder-snomed-ct-v13.csv",
  column = "code",
)
rsd_icd10 = codelist_from_csv(
  "codelists/bristol-rem-sleep-disorder-icd10-v13.csv",
  column = "code",
)

# Migraine
migraine_snomed = codelist_from_csv(
  "codelists/bristol-migraine-snomed-ct-v13.csv",
  column = "code",
)
migraine_icd10 = codelist_from_csv(
  "codelists/bristol-migraine-icd10-v13.csv",
  column = "code",
)

# Motor Neurone Disease (MND)
mnd_snomed = codelist_from_csv(
  "codelists/bristol-motor-neurone-disease-snomed-ct-v13.csv",
  column = "code",
)
mnd_icd10 = codelist_from_csv(
  "codelists/bristol-motor-neurone-disease-icd10-v13.csv",
  column = "code",
)

# Multiple Sclerosis (MS)
ms_snomed = codelist_from_csv(
  "codelists/bristol-multiple-sclerosis-snomed-ct-v13.csv",
  column = "code",
)
ms_icd10 = codelist_from_csv(
  "codelists/bristol-multiple-sclerosis-icd10-v13.csv",
  column = "code",
)
