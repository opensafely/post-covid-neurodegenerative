from os import system
from cohortextractor import codelist_from_csv, combine_codelists, codelist

#Covid
covid_codes = codelist_from_csv(
    "codelists/user-RochelleKnight-confirmed-hospitalised-covid-19.csv",
    system="icd10",
    column="code",
)

covid_primary_care_positive_test = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-positive-test.csv",
    system="ctv3",
    column="CTV3ID",
)

covid_primary_care_code = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-clinical-code.csv",
    system="ctv3",
    column="CTV3ID",
)

covid_primary_care_sequalae = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-sequelae.csv",
    system="ctv3",
    column="CTV3ID",
)
#Ethnicity
opensafely_ethnicity_codes_6 = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)

primis_covid19_vacc_update_ethnicity = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-eth2001.csv",
    system="snomed",
    column="code",
    category_column="grouping_6_id",
)
#Smoking
smoking_clear = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)

smoking_unclear = codelist_from_csv(
    "codelists/opensafely-smoking-unclear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)

# AMI
ami_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-ami_snomed.csv",
    system="snomed",
    column="code",
)
ami_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-ami_icd10.csv",
    system="icd10",
    column="code",
)
ami_prior_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-ami_prior_icd10.csv",
    system="icd10",
    column="code",
)
artery_dissect_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-artery_dissect_icd10.csv",
    system="icd10",
    column="code",
)

# Cancer
cancer_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-cancer_snomed.csv",
    system="snomed",
    column="code",
)
cancer_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-cancer_icd10.csv",
    system="icd10",
    column="code",
)

# Cardiomyopathy
cardiomyopathy_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-cardiomyopathy_snomed.csv",
    system="snomed",
    column="code",
)
cardiomyopathy_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-cardiomyopathy_icd10.csv",
    system="icd10",
    column="code",
)

# COPD
copd_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-copd_snomed.csv",
    system="snomed",
    column="code",
)
copd_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-copd_icd10.csv",
    system="icd10",
    column="code",
)

# Dementia
dementia_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-dementia_snomed.csv",
    system="snomed",
    column="code",
)
dementia_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-dementia_icd10.csv",
    system="icd10",
    column="code",
)

#Disseminated intravascular coagulation
dic_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-dic_icd10.csv",
    system="icd10",
    column="code",
)

# Pulmonary embolism
pe_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-pe_icd10.csv",
    system="icd10",
    column="code",
)
pe_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-pe_snomed.csv",
    system="snomed",
    column="code",
)

# Deep vein thrombosis
dvt_dvt_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-dvt_dvt_icd10.csv",
    system="icd10",
    column="code",
)
dvt_icvt_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-dvt_icvt_icd10.csv",
    system="icd10",
    column="code",
)
dvt_icvt_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-dvt_icvt_snomed.csv",
    system="snomed",
    column="code",
)
dvt_pregnancy_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-dvt_pregnancy_icd10.csv",
    system="icd10",
    column="code",
)
other_dvt_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-other_dvt_icd10.csv",
    system="icd10",
    column="code",
)
# DVT
dvt_dvt_snomed_clinical = codelist_from_csv(
    "codelists/user-tomsrenin-dvt_main.csv",
    system="snomed",
    column="code",
)
# ICVT
dvt_icvt_snomed_clinical = codelist_from_csv(
    "codelists/user-tomsrenin-dvt_icvt.csv",
    system="snomed",
    column="code",
)
# DVT in pregnancy
dvt_pregnancy_snomed_clinical = codelist_from_csv(
    "codelists/user-tomsrenin-dvt-preg.csv",
    system="snomed",
    column="code",
)
# Other DVT
other_dvt_snomed_clinical = codelist_from_csv(
    "codelists/user-tomsrenin-dvt-other.csv",
    system="snomed",
    column="code",
)

# Portal vein thrombosis
portal_vein_thrombosis_snomed_clinical = codelist_from_csv(
    "codelists/user-tomsrenin-pvt.csv",
    system="snomed",
    column="code",
)
portal_vein_thrombosis_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-portal_vein_thrombosis_icd10.csv",
    system="icd10",
    column="code",
)

icvt_pregnancy_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-icvt_pregnancy_icd10.csv",
    system="icd10",
    column="code",
)

# Other arterial embolism
other_arterial_embolism_snomed_clinical = codelist_from_csv(
    "codelists/user-tomsrenin-other_art_embol.csv",
    system="snomed",
    column="code",
)

stroke_isch_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-stroke_isch_snomed.csv",
    system="snomed",
    column="code",
)

other_arterial_embolism_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-other_arterial_embolism_icd10.csv",
    system="icd10",
    column="code",
)

stroke_isch_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-stroke_isch_icd10.csv",
    system="icd10",
    column="code",
)

# All DVT in SNOMED
all_dvt_codes_snomed_clinical = combine_codelists(
    dvt_dvt_snomed_clinical, 
    dvt_pregnancy_snomed_clinical
)

# All DVT in ICD10
all_dvt_codes_icd10 = combine_codelists(
    dvt_dvt_icd10, 
    dvt_pregnancy_icd10
)

# All VTE in SNOMED
all_vte_codes_snomed_clinical = combine_codelists(
    portal_vein_thrombosis_snomed_clinical, 
    dvt_dvt_snomed_clinical, 
    dvt_icvt_snomed_clinical, 
    dvt_pregnancy_snomed_clinical, 
    other_dvt_snomed_clinical, 
    pe_snomed_clinical
)

# All VTE in ICD10
all_vte_codes_icd10 = combine_codelists(
    portal_vein_thrombosis_icd10, 
    dvt_dvt_icd10, 
    dvt_icvt_icd10, 
    dvt_pregnancy_icd10, 
    other_dvt_icd10, 
    icvt_pregnancy_icd10, 
    pe_icd10
)

# All ATE in SNOMED
all_ate_codes_snomed_clinical = combine_codelists(
    ami_snomed_clinical, 
    other_arterial_embolism_snomed_clinical, 
    stroke_isch_snomed_clinical
)

# All ATE in ICD10
all_ate_codes_icd10 = combine_codelists(
    ami_icd10, 
    other_arterial_embolism_icd10, 
    stroke_isch_icd10
)

# Intracranial venous thrombosis
icvt_pregnancy_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-icvt_pregnancy_icd10.csv",
    system="icd10",
    column="code",
)

# Vein thrombosis
portal_vein_thrombosis_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-portal_vein_thrombosis_icd10.csv",
    system="icd10",
    column="code",
)
vt_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-vt_icd10.csv",
    system="icd10",
    column="code",
)
thrombophilia_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-thrombophilia_icd10.csv",
    system="icd10",
    column="code",
)
thrombophilia_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-thrombophilia_snomed.csv",
    system="snomed",
    column="code",
)
tcp_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-tcp_snomed.csv",
    system="snomed",
    column="code",
)
ttp_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-ttp_icd10.csv",
    system="icd10",
    column="code",
)
thrombocytopenia_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-thrombocytopenia_icd10.csv",
    system="icd10",
    column="code",
)
# Portal vein thrombosis
portal_vein_thrombosis_snomed_clinical = codelist_from_csv(
    "codelists/user-tomsrenin-pvt.csv",
    system="snomed",
    column="code",
)

# Dementia vascular 
dementia_vascular_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-dementia_vascular_snomed.csv",
    system="snomed",
    column="code",
)

dementia_vascular_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-dementia_vascular_icd10.csv",
    system="icd10",
    column="code",
)

# Liver disease
liver_disease_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-liver_disease_snomed.csv",
    system="snomed",
    column="code",
)
liver_disease_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-liver_disease_icd10.csv",
    system="icd10",
    column="code",
)

# Antiplatelet 
antiplatelet_dmd = codelist_from_csv(
    "codelists/user-elsie_horne-antiplatelet_dmd.csv",
    system="snomed",
    column="dmd_id",
)

# Lipid Lowering
lipid_lowering_dmd = codelist_from_csv(
    "codelists/user-elsie_horne-lipid_lowering_dmd.csv",
    system="snomed",
    column="dmd_id",
)

# Anticoagulant
anticoagulant_dmd = codelist_from_csv(
    "codelists/user-elsie_horne-anticoagulant_dmd.csv",
    system="snomed",
    column="dmd_id",
)

# COCP
cocp_dmd = codelist_from_csv(
    "codelists/user-elsie_horne-cocp_dmd.csv",
    system="snomed",
    column="dmd_id",
)

# HRT
hrt_dmd = codelist_from_csv(
    "codelists/user-elsie_horne-hrt_dmd.csv",
    system="snomed",
    column="dmd_id",
)

# Arterial Embolism
other_arterial_embolism_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-other_arterial_embolism_icd10.csv",
    system="icd10",
    column="code",
)
# Other arterial embolism
other_arterial_embolism_snomed_clinical = codelist_from_csv(
    "codelists/user-tomsrenin-other_art_embol.csv",
    system="snomed",
    column="code",
)

# Mesenteric Thrombus
mesenteric_thrombus_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-mesenteric_thrombus_icd10.csv",
    system="icd10",
    column="code",
)

# Arrhytmia
life_arrhythmia_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-life_arrhythmia_icd10.csv",
    system="icd10",
    column="code",
)

# Pericarditis
pericarditis_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-pericarditis_icd10.csv",
    system="icd10",
    column="code",
)

# Myocarditis
myocarditis_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-myocarditis_icd10.csv",
    system="icd10",
    column="code",
)

# HYpertension
hypertension_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-hypertension_icd10.csv",
    system="icd10",
    column="code",
)
hypertension_drugs_dmd = codelist_from_csv(
    "codelists/user-elsie_horne-hypertension_drugs_dmd.csv",
    system="snomed",
    column="dmd_id",
)
hypertension_snomed_clinical = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-hyp_cod.csv",
    system="snomed",
    column="code",
)

# TIA
tia_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-tia_snomed.csv",
    system="snomed",
    column="code",
)
tia_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-tia_icd10.csv",
    system="icd10",
    column="code",
)

# Angina
angina_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-angina_snomed.csv",
    system="snomed",
    column="code",
)
angina_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-angina_icd10.csv",
    system="icd10",
    column="code",
)

# Prostate
prostate_cancer_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-prostate_cancer_icd10.csv",
    system="icd10",
    column="code",
)
prostate_cancer_snomed_clinical = codelist_from_csv(
    "codelists/user-RochelleKnight-prostate_cancer_snomed.csv",
    system="snomed",
    column="code",
)

# Pregnancy
pregnancy_snomed_clinical = codelist_from_csv(
    "codelists/user-RochelleKnight-pregnancy_and_birth_snomed.csv",
    system="snomed",
    column="code",
)

# Heart Failure
hf_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-hf_snomed.csv",
    system="snomed",
    column="code",
)
hf_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-hf_icd10.csv",
    system="icd10",
    column="code",
)

# Stroke 
stroke_isch_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-stroke_isch_icd10.csv",
    system="icd10",
    column="code",
)
stroke_isch_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-stroke_isch_snomed.csv",
    system="snomed",
    column="code",
)
stroke_sah_hs_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-stroke_sah_hs_icd10.csv",
    system="icd10",
    column="code",
)
stroke_sah_hs_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-stroke_sah_hs_snomed.csv",
    system="snomed",
    column="code",
)

# BMI
bmi_obesity_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-bmi_obesity_snomed.csv",
    system="snomed",
    column="code",
)

bmi_obesity_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-bmi_obesity_icd10.csv",
    system="icd10",
    column="code",
)

bmi_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-bmi.csv",
    system="snomed",
    column="code",
)

# Total Cholesterol
cholesterol_snomed = codelist_from_csv(
    "codelists/opensafely-cholesterol-tests-numerical-value.csv",
    system="snomed",
    column="code",
)

# HDL Cholesterol
hdl_cholesterol_snomed = codelist_from_csv(
    "codelists/bristol-hdl-cholesterol.csv",
    system="snomed",
    column="code",
)
# Carer codes
carer_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-carer.csv",
    system="snomed",
    column="code",
)

# No longer a carer codes
notcarer_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-notcarer.csv",
    system="snomed",
    column="code",
)
# Wider Learning Disability
learndis_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-learndis.csv",
    system="snomed",
    column="code",
)
# Employed by Care Home codes
carehome_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-carehome.csv",
    system="snomed",
    column="code",
)

# Employed by nursing home codes
nursehome_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-nursehome.csv",
    system="snomed",
    column="code",
)

# Employed by domiciliary care provider codes
domcare_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-domcare.csv",
    system="snomed",
    column="code",
)

# Patients in long-stay nursing and residential care
longres_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-longres.csv",
    system="snomed",
    column="code",
)
# High Risk from COVID-19 code
shield_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-shield.csv",
    system="snomed",
    column="code",
)

# Lower Risk from COVID-19 codes
nonshield_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-nonshield.csv",
    system="snomed",
    column="code",
)

#For JCVI groups
# Pregnancy codes 
preg_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-preg.csv",
    system="snomed",
    column="code",
)

# Pregnancy or Delivery codes
pregdel_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-pregdel.csv",
    system="snomed",
    column="code",
)
# All BMI coded terms
bmi_stage_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-bmi_stage.csv",
    system="snomed",
    column="code",
)
# Severe Obesity code recorded
sev_obesity_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-sev_obesity.csv",
    system="snomed",
    column="code",
)
# Asthma Diagnosis code
ast_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-ast.csv",
    system="snomed",
    column="code",
)

# Asthma Admission codes
astadm_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-astadm.csv",
    system="snomed",
    column="code",
)

# Asthma systemic steroid prescription codes
astrx_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-astrx.csv",
    system="snomed",
    column="code",
)
# Chronic Respiratory Disease
resp_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-resp_cov.csv",
    system="snomed",
    column="code",
)
# Chronic Neurological Disease including Significant Learning Disorder
cns_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-cns_cov.csv",
    system="snomed",
    column="code",
)

# Asplenia or Dysfunction of the Spleen codes
spln_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-spln_cov.csv",
    system="snomed",
    column="code",
)
# Diabetes diagnosis codes
diab_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-diab.csv",
    system="snomed",
    column="code",
)
# Diabetes resolved codes
dmres_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-dmres.csv",
    system="snomed",
    column="code",
)
# Severe Mental Illness codes
sev_mental_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-sev_mental.csv",
    system="snomed",
    column="code",
)

# Remission codes relating to Severe Mental Illness
smhres_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-smhres.csv",
    system="snomed",
    column="code",
)

# Chronic heart disease codes
chd_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-chd_cov.csv",
    system="snomed",
    column="code",
)

# Chronic Kidney disease
ckd_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-ckd_snomed.csv",
    system="snomed",
    column="code",
)

ckd_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-ckd_icd10.csv",
    system="icd10",
    column="code",
)

# Chronic kidney disease diagnostic codes
ckd_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-ckd_cov.csv",
    system="snomed",
    column="code",
)

# Chronic kidney disease codes - all stages
ckd15_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-ckd15.csv",
    system="snomed",
    column="code",
)

# Chronic kidney disease codes-stages 3 - 5
ckd35_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-ckd35.csv",
    system="snomed",
    column="code",
)

# Chronic Liver disease codes
cld_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-cld.csv",
    system="snomed",
    column="code",
)
# Immunosuppression diagnosis codes
immdx_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-immdx_cov.csv",
    system="snomed",
    column="code",
)

# Immunosuppression medication codes
immrx_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-immrx.csv",
    system="snomed",
    column="code",
)

# Diabetes
# Type 1 diabetes
diabetes_type1_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-type-1-diabetes.csv",
    system="ctv3",
    column="code",
)
# Type 1 diabetes secondary care
diabetes_type1_icd10 = codelist_from_csv(
    "codelists/opensafely-type-1-diabetes-secondary-care.csv",
    system="icd10",
    column="icd10_code",
)
# Type 2 diabetes
diabetes_type2_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-type-2-diabetes.csv",
    system="ctv3",
    column="code",
)
# Type 2 diabetes secondary care
diabetes_type2_icd10 = codelist_from_csv(
    "codelists/user-r_denholm-type-2-diabetes-secondary-care-bristol.csv",
    system="icd10",
    column="code",
)
# Non-diagnostic diabetes codes
diabetes_diagnostic_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-nondiagnostic-diabetes-codes.csv",
    system="ctv3",
    column="code",
)
# Other or non-specific diabetes
diabetes_other_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-other-or-nonspecific-diabetes.csv",
    system="ctv3",
    column="code",
)
# Gestational diabetes
diabetes_gestational_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-gestational-diabetes.csv",
    system="ctv3",
    column="code",
)
# Insulin medication 
insulin_snomed_clinical = codelist_from_csv(
     "codelists/opensafely-insulin-medication.csv",
     system="snomed",
     column="id",
)
# Antidiabetic drugs
antidiabetic_drugs_snomed_clinical = codelist_from_csv(
     "codelists/opensafely-antidiabetic-drugs.csv",
     system="snomed",
     column="id",
)
# Antidiabetic drugs - non metformin
non_metformin_dmd = codelist_from_csv(
    "codelists/user-r_denholm-non-metformin-antidiabetic-drugs_bristol.csv", 
    system="snomed", 
    column="id",
)
# Prediabetes
prediabetes_snomed = codelist_from_csv(
    "codelists/opensafely-prediabetes-snomed.csv",
    system="snomed",
    column="code",
)

##Quality assurance codes 

prostate_cancer_snomed_clinical = codelist_from_csv(
    "codelists/user-RochelleKnight-prostate_cancer_snomed.csv",
    system="snomed",
    column="code",
)
prostate_cancer_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-prostate_cancer_icd10.csv",
    system="icd10",
    column="code",
)
pregnancy_snomed_clinical = codelist_from_csv(
    "codelists/user-RochelleKnight-pregnancy_and_birth_snomed.csv",
    system="snomed",
    column="code",
)

###########################
# Neurodegenerative codes #
###########################

# Dementia
# Alzheimer's disease
alzheimer_snomed = codelist_from_csv(
    "codelists/bristol-alzheimers-disease-snomed-ct.csv",
    system = "snomed",
    column = "code",
)
alzheimer_icd10 = codelist_from_csv(
    "codelists/bristol-alzheimers-disease.csv",
    system = "icd10",
    column = "code",
)

# Vascular dementia
vascular_dementia_snomed = codelist_from_csv(
    "codelists/bristol-vascular-dementia-snomed-ct.csv",
    system = "snomed",
    column = "code",
)
vascular_dementia_icd10 = codelist_from_csv(
    "codelists/bristol-vascular-dementia.csv",
    system = "icd10",
    column = "code",
)

# Other dementias
other_dementias_snomed = codelist_from_csv(
    "codelists/bristol-other-dementias-snomed-ct.csv",
    system = "snomed",
    column = "code",
)
other_dementias_icd10 = codelist_from_csv(
    "codelists/bristol-other-dementias.csv",
    system = "icd10",
    column = "code",
)

# Unspecified dementias
unspecified_dementias_snomed = codelist_from_csv(
    "codelists/bristol-unspecified-dementia-snomed-ct.csv",
    system = "snomed",
    column = "code",
)
unspecified_dementias_icd10 = codelist_from_csv(
    "codelists/bristol-unspecified-dementia.csv",
    system = "icd10",
    column = "code",
)

# Cognitive impairment
cognitive_impairment_snomed = codelist_from_csv(
    "codelists/bristol-cognitive-impairment-disorder-snomed-ct.csv",
    system = "snomed",
    column = "code",
)
cognitive_impairment_icd10 = codelist_from_csv(
    "codelists/bristol-cognitive-impairment-disorder.csv",
     system = "icd10",
     column = "code",
)

# Parkinson diseases
# Parkinson
parkinson_snomed = codelist_from_csv(
    "codelists/bristol-parkinsons-disease-snomed.csv",
    system = "snomed",
    column = "code",
)
parkinson_icd10 = codelist_from_csv(
    "codelists/bristol-parkinsons-disease.csv",
     system = "icd10",
     column = "code",
)

# Restless leg syndrome
restless_leg_syndrome_snomed = codelist_from_csv(
    "codelists/bristol-restless-leg-syndrome-snomed-ct.csv",
    system = "snomed",
    column = "code",
)
# restless_leg_syndrome__icd10 = codelist_from_csv(
#     "codelists/",
#      system = "icd10",
#      column = "code",
# )

# REM sleep disorder
rem_sleep_disorder_snomed = codelist_from_csv(
    "codelists/bristol-rem-sleep-disorder-snomedct.csv",
    system = "snomed",
    column = "code",
)
rem_sleep_disorder_icd10 = codelist_from_csv(
    "codelists/bristol-rem-sleep-disorder.csv",
     system = "icd10",
     column = "code",
)

# Migraine
migraine_snomed = codelist_from_csv(
    "codelists/bristol-migraine-snomed-ct.csv",
    system = "snomed",
    column = "code",
)
migraine_icd10 = codelist_from_csv(
    "codelists/bristol-migraine.csv",
     system = "icd10",
     column = "code",
)

# Motor neurone disease
motor_neurone_disease_snomed = codelist_from_csv(
    "codelists/bristol-motor-neurone-disease-snomed-ct.csv",
    system = "snomed",
    column = "code",
)
# motor_neurone_disease_icd10 = codelist_from_csv(
#     "codelists/",
#      system = "icd10",
#      column = "code",
# )

# Multiple sclerosis
multiple_sclerosis_snomed = codelist_from_csv(
    "codelists/bristol-multiple-sclerosis-snomed-ct.csv",
    system = "snomed",
    column = "code",
)
multiple_sclerosis_icd10 = codelist_from_csv(
    "codelists/bristol-multiple-sclerosis.csv",
     system = "icd10",
     column = "code",
)

# # Parkinson prescription
# # Antipsychotics
# parkinson_antipsychotics_prescription_bnf = codelist_from_csv(
#     "local_codelists/",
#     system = "snomed",
#     colum = "dmd_id",
# )
# # Dopaminergic drugs
# parkinson_antipsychotics_prescription_bnf = codelist_from_csv(
#     "local_codelists/",
#     system = "snomed",
#     colum = "dmd_id",
# )
# # Antimuscarinic drugs
# parkinson_antipsychotics_prescription_bnf = codelist_from_csv(
#     "local_codelists/",
#     system = "snomed",
#     colum = "dmd_id",
# )
# # Essential tremor, chorea, tics, and related disorders drugs
# parkinson_antipsychotics_prescription_bnf = codelist_from_csv(
#     "local_codelists/",
#     system = "snomed",
#     colum = "dmd_id",
# )

# Migraine prescriptions
# migraine_prescription_bnf = codelist_from_csv(
#     "local_codelists/",
#     system = "snomed",
#     colum = "dmd_id",
# )

########################################
# Neurodegenerative codes (covariates) #
########################################

# Hypercholesterolaemia (HCh)
hypercholesterolaemia_snomed = codelist_from_csv(
    "codelists/bristol-hypercholesterolaemia-snomedct.csv",
    system = "snomed",
    column = "code"
)

hypercholesterolaemia_icd10 = codelist_from_csv(
    "codelists/bristol-hypercholesterolaemia.csv",
    system = "snomed",
    column = "code"
)
