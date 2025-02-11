from ehrql import (
    codelist_from_csv,
    create_dataset,
    days,
    case,
    when,
    minimum_of,
    maximum_of,
)
# Bring table definitions from the TPP backend 
from ehrql.tables.tpp import ( 
    patients, 
    practice_registrations, 
    addresses, 
    appointments, 
    occupation_on_covid_vaccine_record,
    vaccinations,
    sgss_covid_all_tests,
    apcs, 
    ec, 
    clinical_events, 
    medications, 
    ons_deaths,
)

# Codelists from codelists.py (which pulls all variables from the codelist folder)
from codelists import *


# Call functions from variable_helper_functions
from variable_helper_functions import (
    ever_matching_event_clinical_ctv3_before,
    first_matching_event_clinical_ctv3_between,
    first_matching_event_clinical_snomed_between,
    first_matching_med_dmd_between,
    first_matching_event_apc_between,
    first_matching_event_ec_snomed_between,
    matching_death_between,
    last_matching_event_clinical_ctv3_before,
    last_matching_event_clinical_snomed_before,
    last_matching_med_dmd_before,
    last_matching_event_apc_before,
    last_matching_event_ec_snomed_before,
    matching_death_before,
    filter_codes_by_category,
)


def generate_variables(index_date, end_date_exp, end_date_out):  

    ## Define individual temporary variables (for exposures) first before using them in the dictionary

        ### Covid
    tmp_exp_date_covid19_confirmed_sgss = (
        sgss_covid_all_tests.where(
            sgss_covid_all_tests.specimen_taken_date.is_on_or_between(index_date, end_date_exp)
        )
        .where(sgss_covid_all_tests.is_positive)
        .sort_by(sgss_covid_all_tests.specimen_taken_date)
        .first_for_patient()
        .specimen_taken_date
    )

    tmp_exp_date_covid19_confirmed_gp = (
        clinical_events.where(
            (clinical_events.ctv3_code.is_in(
                covid_primary_care_code + 
                covid_primary_care_positive_test +
                covid_primary_care_sequalae)) &
            clinical_events.date.is_on_or_between(index_date, end_date_exp)
        )
        .sort_by(clinical_events.date)
        .first_for_patient()
        .date
    )

    tmp_exp_date_covid19_confirmed_apc = (
        apcs.where(
            ((apcs.primary_diagnosis.is_in(covid_codes)) | 
             (apcs.secondary_diagnosis.is_in(covid_codes))) & 
            (apcs.admission_date.is_on_or_between(index_date, end_date_exp))
        )
        .sort_by(apcs.admission_date)
        .first_for_patient()
        .admission_date
    )

    tmp_exp_covid19_confirmed_death = matching_death_between(covid_codes, index_date, end_date_exp)

    tmp_exp_date_death = ons_deaths.date

    tmp_exp_date_covid19_confirmed_death = case(
        when(tmp_exp_covid19_confirmed_death).then(tmp_exp_date_death)
    )
    
    exp_date_covid19_confirmed=minimum_of(
        tmp_exp_date_covid19_confirmed_sgss, 
        tmp_exp_date_covid19_confirmed_gp,
        tmp_exp_date_covid19_confirmed_apc,
        tmp_exp_date_covid19_confirmed_death
    )

    ## Define individual temporary variables (subgroup variables) first before using them in the dictionary

    ## 1. Covid-19 prior to study start date (2020-01-01)

    ### SGSS

    tmp_sub_bin_priorcovid19_confirmed_sgss = (
        sgss_covid_all_tests.where(
            sgss_covid_all_tests.specimen_taken_date.is_before(index_date)
        )
        .where(sgss_covid_all_tests.is_positive)
        .exists_for_patient()
    )

    ### Primary care

    tmp_sub_bin_priorcovid19_confirmed_gp = (
        clinical_events.where(
            (clinical_events.ctv3_code.is_in(
                covid_primary_care_code + 
                covid_primary_care_positive_test + 
                covid_primary_care_sequalae)) &
            clinical_events.date.is_before(index_date)
        )
        .exists_for_patient()
    )

    ### SUS

    tmp_sub_bin_priorcovid19_confirmed_apc = (
        apcs.where(
            ((apcs.primary_diagnosis.is_in(covid_codes)) | (apcs.secondary_diagnosis.is_in(covid_codes))) & 
            (apcs.admission_date.is_before(index_date))
        )
        .exists_for_patient()
    )

    ## 2. Covid-19 severity

    ### SUS

    sub_date_covid19_hospital = (
        apcs.where(
            (apcs.primary_diagnosis.is_in(covid_codes)) & 
            (apcs.admission_date.is_on_or_after(exp_date_covid19_confirmed))
        )
        .sort_by(apcs.admission_date)
        .first_for_patient()
        .admission_date
    )
    
    ## 3. Smoking status

    tmp_most_recent_smoking_cat = (
        last_matching_event_clinical_ctv3_before(smoking_clear, index_date)
        .ctv3_code.to_category(smoking_clear)
    )

    tmp_ever_smoked = ever_matching_event_clinical_ctv3_before(
        (filter_codes_by_category(smoking_clear, include=["S", "E"])), index_date)
    
    ## 4. Consultation rate
    tmp_cov_num_consultation_rate = appointments.where(
        appointments.status.is_in([
            "Arrived",
            "In Progress",
            "Finished",
            "Visit",
            "Waiting",
            "Patient Walked Out",
            ]) & appointments.start_date.is_on_or_between(index_date - days(365), index_date)
            ).count_for_patient()    

    ## 5. Neurodegenerative Primary/Secondary/Death Codes
    
    ### Dementias

    ### Alzheimers
    tmp_out_date_dem_alz_gp = (
        first_matching_event_clinical_snomed_between(
        dem_alz_snomed, index_date, end_date_out  
        ).date
    )

    tmp_out_date_dem_alz_apc = (
        first_matching_event_apc_between(
        dem_alz_icd10, index_date, end_date_out 
        ).admission_date
    )

    tmp_out_date_dem_alz_death= case(
        when(
            matching_death_between(dem_alz_icd10, index_date, end_date_out)
            ).then(ons_deaths.date)
    )

    out_date_dem_alz=minimum_of(
        tmp_out_date_dem_alz_gp,
        tmp_out_date_dem_alz_apc,
        tmp_out_date_dem_alz_death
    )

    ### Vascular Dementia
    tmp_out_date_dem_vasc_gp = (
        first_matching_event_clinical_snomed_between(
        dem_vasc_snomed, index_date, end_date_out  
        ).date
    )

    tmp_out_date_dem_vasc_apc = (
        first_matching_event_apc_between(
        dem_vasc_icd10, index_date, end_date_out 
        ).admission_date
    )

    tmp_out_date_dem_vasc_death= case(
        when(
            matching_death_between(dem_vasc_icd10, index_date, end_date_out)
            ).then(ons_deaths.date)
    )

    out_date_dem_vasc=minimum_of(
        tmp_out_date_dem_vasc_gp,
        tmp_out_date_dem_vasc_apc,
        tmp_out_date_dem_vasc_death
    )

    ### Lewy Body
    tmp_out_date_dem_lb_gp = (
        first_matching_event_clinical_snomed_between(
        dem_lb_snomed, index_date, end_date_out  
        ).date
    )

    out_date_dem_lb=tmp_out_date_dem_lb_gp # no icd10

    ### Other Dementia 
    tmp_out_date_dem_other_gp = (
        first_matching_event_clinical_snomed_between(
        dem_other_snomed, index_date, end_date_out  
        ).date
    )

    tmp_out_date_dem_other_apc = (
        first_matching_event_apc_between(
        dem_other_icd10, index_date, end_date_out 
        ).admission_date
    )

    tmp_out_date_dem_other_death= case(
        when(
            matching_death_between(dem_other_icd10, index_date, end_date_out)
            ).then(ons_deaths.date)
    )

    out_date_dem_other=minimum_of(
        tmp_out_date_dem_other_gp,
        tmp_out_date_dem_other_apc,
        tmp_out_date_dem_other_death
    )


    ### Unspecified Dementia
    tmp_out_date_dem_unspec_gp = (
        first_matching_event_clinical_snomed_between(
        dem_unspec_snomed, index_date, end_date_out  
        ).date
    )

    tmp_out_date_dem_unspec_apc = (
        first_matching_event_apc_between(
        dem_unspec_icd10, index_date, end_date_out 
        ).admission_date
    )

    tmp_out_date_dem_unspec_death= case(
        when(
            matching_death_between(dem_unspec_icd10, index_date, end_date_out)
            ).then(ons_deaths.date)
    )

    out_date_dem_unspec=minimum_of(
        tmp_out_date_dem_unspec_gp,
        tmp_out_date_dem_unspec_apc,
        tmp_out_date_dem_unspec_death
    )
                
    ### Any Dementia
    tmp_out_date_dem_any_gp = (
        first_matching_event_clinical_snomed_between(
        dem_alz_snomed   +
        dem_vasc_snomed  +
        dem_lb_snomed    +
        dem_other_snomed +
        dem_unspec_snomed, index_date, end_date_out  
        ).date
    )

    tmp_out_date_dem_any_apc = (
        first_matching_event_apc_between(
        dem_alz_icd10   +
        dem_vasc_icd10  +
        dem_other_icd10 +
        dem_unspec_icd10, index_date, end_date_out 
        ).admission_date
    )

    tmp_out_date_dem_any_death= case(
        when(
            matching_death_between(
            dem_alz_icd10   +
            dem_vasc_icd10  +
            dem_other_icd10 +
            dem_unspec_icd10, index_date, end_date_out)
            ).then(ons_deaths.date)
    )

    out_date_dem_any=minimum_of(
        tmp_out_date_dem_any_gp,
        tmp_out_date_dem_any_apc,
        tmp_out_date_dem_any_death
    )


    ### Dementia risk conditions (Cognitive Impairment)
    tmp_out_date_cis_gp = (
        first_matching_event_clinical_snomed_between(
        cis_snomed, index_date, end_date_out  
        ).date
    )

    out_date_cis = tmp_out_date_cis_gp # no icd10


    ### Parkinson’s disease
    tmp_out_date_park_gp = (
        first_matching_event_clinical_snomed_between(
        park_snomed, index_date, end_date_out  
        ).date
    )

    tmp_out_date_park_apc = (
        first_matching_event_apc_between(
        park_icd10, index_date, end_date_out  
        ).admission_date
    )

    tmp_out_date_park_death= case(
        when(
            matching_death_between(park_icd10, index_date, end_date_out)
            ).then(ons_deaths.date)
    )

    out_date_park=minimum_of(
        tmp_out_date_park_gp,
        tmp_out_date_park_apc,
        tmp_out_date_park_death
    )

    ### Parkinson’s risk conditions (restless leg syndrome and REM sleep disorder)
    ## RLS
    tmp_out_date_rls_gp= (
        first_matching_event_clinical_snomed_between(
        rls_snomed, index_date, end_date_out 
        ).date
    )

    out_date_rls = tmp_out_date_rls_gp

    ## RSD
    tmp_out_date_rsd_gp= (
        first_matching_event_clinical_snomed_between(
        rsd_snomed, index_date, end_date_out 
        ).date
    )

    tmp_out_date_rsd_apc= (
        first_matching_event_apc_between(
        rsd_icd10, index_date, end_date_out 
        ).admission_date
    )

    tmp_out_date_rsd_death= case(
        when(
            matching_death_between(rsd_icd10, index_date, end_date_out)
            ).then(ons_deaths.date)
    )

    out_date_rsd=minimum_of(
        tmp_out_date_rsd_gp,
        tmp_out_date_rsd_apc,
        tmp_out_date_rsd_death
    )

    out_date_park_risk = minimum_of(
        out_date_rls,
        out_date_rsd
    )

    ### Other neurodegenerative conditions (MND, MS)
    ## MND
    tmp_out_date_mnd_gp= (
        first_matching_event_clinical_snomed_between(
        mnd_snomed, index_date, end_date_out 
        ).date
    )

    tmp_out_date_mnd_apc= (
        first_matching_event_apc_between(
        mnd_icd10, index_date, end_date_out 
        ).admission_date
    )

    tmp_out_date_mnd_death= case(
        when(
            matching_death_between(mnd_icd10, index_date, end_date_out)
            ).then(ons_deaths.date)
    )

    out_date_mnd=minimum_of(
        tmp_out_date_mnd_gp,
        tmp_out_date_mnd_apc,
        tmp_out_date_mnd_death
    )

    ## MS
    tmp_out_date_ms_gp= (
        first_matching_event_clinical_snomed_between(
        ms_snomed, index_date, end_date_out 
        ).date
    )


    tmp_out_date_ms_apc= (
        first_matching_event_apc_between(
        ms_icd10, index_date, end_date_out 
        ).admission_date
    )

    tmp_out_date_ms_death= case(
        when(
            matching_death_between(ms_icd10, index_date, end_date_out)
            ).then(ons_deaths.date)
    )

    out_date_ms=minimum_of(
        tmp_out_date_ms_gp,
        tmp_out_date_ms_apc,
        tmp_out_date_ms_death
    )

    out_date_neuro_other = minimum_of(
        out_date_mnd, 
        out_date_ms
    )

    ### Neurological condition (Migrane)
    tmp_out_date_migraine_gp= (
        first_matching_event_clinical_snomed_between(
        migraine_snomed, index_date, end_date_out 
        ).date
    )

    tmp_out_date_migraine_apc= (
        first_matching_event_apc_between(
        migraine_icd10, index_date, end_date_out 
        ).admission_date
    )

    tmp_out_date_migraine_death= case(
        when(
            matching_death_between(migraine_icd10, index_date, end_date_out)
            ).then(ons_deaths.date)
    )

    out_date_migraine=minimum_of(
        tmp_out_date_migraine_gp,
        tmp_out_date_migraine_apc,
        tmp_out_date_migraine_death
    )

    ## Hypertension
    cov_bin_hypertension=(
        (last_matching_event_clinical_snomed_before(
            hypertension_snomed, index_date
        ).exists_for_patient()) |
        (last_matching_event_clinical_ctv3_before(
            hypertension_ctv3, index_date
        ).exists_for_patient()) |
        (last_matching_med_dmd_before(
            hypertension_drugs_dmd, index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
            hypertension_icd10, index_date
        ).exists_for_patient()) 
    )

    ## Diabetes 
    cov_bin_diabetes=(
        (last_matching_event_clinical_snomed_before(
            diabetes_snomed, index_date
        ).exists_for_patient()) |
        (last_matching_med_dmd_before(
            diabetes_drugs_dmd, index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
            diabetes_icd10, index_date
        ).exists_for_patient()) 
    )

# Start of Dictionary-----------------------------------------------------------------------------------------

    ## Combine the variables into the final dictionary
    dynamic_variables = dict(

# Exposures---------------------------------------------------------------------------------------------------

        ### Exposures----Covid-19

        tmp_exp_date_covid19_confirmed_sgss  = tmp_exp_date_covid19_confirmed_sgss,
        tmp_exp_date_covid19_confirmed_gp    = tmp_exp_date_covid19_confirmed_gp,
        tmp_exp_date_covid19_confirmed_apc   = tmp_exp_date_covid19_confirmed_apc,
        tmp_exp_date_death                   = tmp_exp_date_death,
        tmp_exp_covid19_confirmed_death      = tmp_exp_covid19_confirmed_death,
        tmp_exp_date_covid19_confirmed_death = tmp_exp_date_covid19_confirmed_death,       
        exp_date_covid19_confirmed           = exp_date_covid19_confirmed,

# Outcomes---------------------------------------------------------------------------------------------------

        ### ---First recording of the outcome in during the study period

        out_date_dem_alz     = out_date_dem_alz,    # Alzheimer's Disease
        out_date_dem_vasc    = out_date_dem_vasc,   # Vascular Dementia
        out_date_dem_lb      = out_date_dem_lb,     # Lewy Body Dementia
        out_date_dem_other   = out_date_dem_other,  # Other Dementia
        out_date_dem_unspec  = out_date_dem_unspec, # Unspecified Dementia
        out_date_dem_any     = out_date_dem_any,    # Any Dementia
        out_date_cis         = out_date_cis,        # Cognitive Impairment Symptoms
        out_date_park        = out_date_park,       # Parkinson's Disease
        out_date_rls         = out_date_rls,        # Restless Leg Syndrome
        out_date_rsd         = out_date_rsd,        # REM Sleep Disorder
        out_date_park_risk   = out_date_park_risk,  # combo of RSM and RLS (not fully sure if needed)
        out_date_mnd         = out_date_mnd,        # Motor Neurone Disease
        out_date_ms          = out_date_ms,         # Multiple Sclerosis
        out_date_neuro_other = out_date_neuro_other,# MS or MND
        out_date_migraine    = out_date_migraine,





# DEFINE EXISTING NEURODEGENERATIVE CONDITION COHORT --------------------------------------------------------------

        ## History of Cognitive Impairment symptoms
        cov_bin_cis= (
            last_matching_event_clinical_snomed_before(
            cis_snomed, index_date
            ).exists_for_patient()       
        ),

        ## History of Parkinsons
        cov_bin_park= (
            (last_matching_event_clinical_snomed_before(
            park_snomed, index_date
            ).exists_for_patient()) |
            (last_matching_event_apc_before(
            park_icd10, index_date
            ).exists_for_patient()) 
        ),

        ## History of Parkinson's Risk (REM Sleep Disorder/Restless Leg syndrome)
        cov_bin_park_risk= (
            (last_matching_event_clinical_snomed_before(
            rls_snomed, index_date
            ).exists_for_patient()) |
            (last_matching_event_clinical_snomed_before(
            rsd_snomed,  index_date
            ).exists_for_patient()) |
            (last_matching_event_apc_before(
            rsd_icd10,  index_date
            ).exists_for_patient()) 
        ),

        ## History of Any Dementia
        cov_bin_dem_any= (
            (last_matching_event_clinical_snomed_before(
            dem_alz_snomed+
            dem_lb_snomed+
            dem_vasc_snomed+
            dem_other_snomed+
            dem_unspec_snomed, index_date
            ).exists_for_patient()) |
            ((last_matching_event_apc_before(
            dem_alz_icd10+
            dem_vasc_icd10+
            dem_other_icd10+
            dem_unspec_icd10, index_date
            )).exists_for_patient())       
        ),

        ##  History of Motor Neurone Disease
        cov_bin_mnd= (
            last_matching_event_clinical_snomed_before(
            mnd_snomed, index_date
            ).exists_for_patient()   |
            (last_matching_event_apc_before(
            mnd_icd10, index_date
            ).exists_for_patient()) 
        ),

        ## History of Multiple Sclerosis
        cov_bin_ms= (
            last_matching_event_clinical_snomed_before(
            ms_snomed, index_date
            ).exists_for_patient() |
            (last_matching_event_apc_before(
            ms_icd10, index_date
            ).exists_for_patient()) 
        ),

        ## History of Migrane
        cov_bin_migraine= (
            last_matching_event_clinical_snomed_before(
            migraine_snomed, index_date
            )
        .exists_for_patient() |
            (last_matching_event_apc_before(
            migraine_icd10, index_date
            ).exists_for_patient()) 
        ),

        ## High Vascular Risk
        cov_bin_high_vask_risk=(
            cov_bin_hypertension | cov_bin_diabetes
        ),

# Covariates-------------------------------------------------------------------------------------------------  

        ## Age
        cov_date_of_birth=patients.date_of_birth,
        cov_num_age=patients.age_on(index_date),

        ## Sex
        cov_cat_sex=patients.sex,

        ## Ethnicity
        cov_cat_ethnicity=(
            clinical_events.where(
                clinical_events.ctv3_code.is_in(opensafely_ethnicity_codes_6)
            )
            .sort_by(clinical_events.date)
            .last_for_patient()
            .ctv3_code.to_category(opensafely_ethnicity_codes_6)
        ),

        ## Deprivation (IMD, 5 categories)
        cov_cat_imd=case(
            when((addresses.for_patient_on(index_date).imd_rounded >= 0) & 
                 (addresses.for_patient_on(index_date).imd_rounded < int(32844 * 1 / 5))).then("1 (most deprived)"),
            when( addresses.for_patient_on(index_date).imd_rounded < int(32844 * 2 / 5 )).then("2"),
            when( addresses.for_patient_on(index_date).imd_rounded < int(32844 * 3 / 5 )).then("3"),
            when( addresses.for_patient_on(index_date).imd_rounded < int(32844 * 4 / 5 )).then("4"),
            when( addresses.for_patient_on(index_date).imd_rounded < int(32844 * 5 / 5 )).then("5 (least deprived)"),
            otherwise="unknown",
        ),

        ## Region
        cov_cat_region=practice_registrations.for_patient_on(index_date).practice_nuts1_region_name,

        ## Consultation rate (these codes can run locally but fail in GitHub action test, details see https://docs.opensafely.org/ehrql/reference/schemas/tpp/#appointments)
        cov_num_consultation_rate=case(
            when(tmp_cov_num_consultation_rate <= 365).then(tmp_cov_num_consultation_rate),
            otherwise=365,
        ),

        ## Smoking status
        cov_cat_smoking_status= case(
            when( tmp_most_recent_smoking_cat == "S").then("S"),
            when((tmp_most_recent_smoking_cat == "E") | ((tmp_most_recent_smoking_cat == "N") & (tmp_ever_smoked == True))).then("E"),
            when((tmp_most_recent_smoking_cat == "N") & (tmp_ever_smoked == False)).then("N"),
            otherwise="M"
        ),

        ## Combined oral contraceptive pill
        cov_bin_cocp=last_matching_med_dmd_before(
            cocp_dmd, index_date
        ).exists_for_patient(),

        cov_bin_hrt=last_matching_med_dmd_before(
            hrt_dmd, index_date
        ).exists_for_patient(),

        ## Obesity 
        cov_bin_obesity=(
            (last_matching_event_clinical_snomed_before(
                bmi_obesity_snomed, index_date
            ).exists_for_patient()) |
            (last_matching_event_apc_before(
                bmi_obesity_icd10, index_date
            ).exists_for_patient()) 
        ),

        ## Carer
        cov_bin_carer=clinical_events.where(
            (clinical_events.snomedct_code.is_in(carer_primis)) &
            (clinical_events.date.is_before(index_date))
        ).exists_for_patient(),

        ## Healthcare worker
        cov_bin_healthcare_worker=occupation_on_covid_vaccine_record.where(
            (occupation_on_covid_vaccine_record.is_healthcare_worker == True)
        ).exists_for_patient(),

        ## Care home status
        cov_bin_carehome_status=(
            addresses.for_patient_on(index_date).care_home_is_potential_match |
            addresses.for_patient_on(index_date).care_home_requires_nursing |
            addresses.for_patient_on(index_date).care_home_does_not_require_nursing
        ),

        ## Acute myocardial infarction
        cov_bin_ami=(
            (last_matching_event_clinical_snomed_before(
                ami_snomed, index_date
            ).exists_for_patient()) |
            (last_matching_event_apc_before(
                ami_icd10 + ami_prior_icd10, index_date
            ).exists_for_patient()) 
        ),

        ## Liver disease
        cov_bin_liver_disease=(
            (last_matching_event_clinical_snomed_before(
                liver_disease_snomed, index_date
            ).exists_for_patient()) |
            (last_matching_event_apc_before(
                liver_disease_icd10, index_date
            ).exists_for_patient()) 
        ),

        ## Chronic kidney disease
        cov_bin_ckd=(
            (last_matching_event_clinical_snomed_before(
                ckd_snomed, index_date
            ).exists_for_patient()) |
            (last_matching_event_apc_before(
                ckd_icd10, index_date
            ).exists_for_patient()) 
        ),

        ## Cancer
        cov_bin_cancer=(
            (last_matching_event_clinical_snomed_before(
                cancer_snomed, index_date
            ).exists_for_patient()) |
            (last_matching_event_apc_before(
                cancer_icd10, index_date
            ).exists_for_patient()) 
        ),

        ## COPD 
        cov_bin_copd=(
            (last_matching_event_clinical_ctv3_before(
                copd_ctv3, index_date
            ).exists_for_patient()) |
            (last_matching_event_apc_before(
                copd_icd10, index_date
            ).exists_for_patient())
        ),

        ## Depression 
        cov_bin_depression=(
            (last_matching_event_clinical_snomed_before(
                depression_snomed, index_date
            ).exists_for_patient()) |
            (last_matching_event_apc_before(
                depression_icd10, index_date
            ).exists_for_patient()) 
        ),

        ## Diabetes
        cov_bin_diabetes = cov_bin_diabetes,

        ## Hypertension
        cov_bin_hypertension = cov_bin_hypertension,

        ## Ischaemic stroke
        cov_bin_stroke_isch= (
            (last_matching_event_clinical_snomed_before(
                stroke_isch_snomed, index_date
            ).exists_for_patient()) |
            (last_matching_event_apc_before(
                stroke_isch_icd10, index_date
            ).exists_for_patient()) 
        ),

# Others
    ## History of Covid-19 Combined

        tmp_sub_bin_priorcovid19_confirmed_sgss = tmp_sub_bin_priorcovid19_confirmed_sgss,
        tmp_sub_bin_priorcovid19_confirmed_gp   = tmp_sub_bin_priorcovid19_confirmed_gp,
        tmp_sub_bin_priorcovid19_confirmed_apc  = tmp_sub_bin_priorcovid19_confirmed_apc,
        sub_bin_covid19_confirmed_history=(
            tmp_sub_bin_priorcovid19_confirmed_sgss |
            tmp_sub_bin_priorcovid19_confirmed_gp   |
            tmp_sub_bin_priorcovid19_confirmed_apc 
        ),

    ## Covid_19 severity 
    
        # case(*when_thens, otherwise=None) the conditions are evaluated in order https://docs.opensafely.org/ehrql/reference/language/#case
        sub_cat_covid19_hospital = case(
            when(
                (exp_date_covid19_confirmed.is_not_null()) &
                (sub_date_covid19_hospital.is_not_null()) &
                ((sub_date_covid19_hospital - exp_date_covid19_confirmed).days >= 0) &
                ((sub_date_covid19_hospital - exp_date_covid19_confirmed).days < 29)
                ).then("hospitalised"),
            when(exp_date_covid19_confirmed.is_not_null()).then("non_hospitalised"),
            when(exp_date_covid19_confirmed.is_null()).then("no_infection")
        ),

    # Inclusion/exclusion variables ----------------------------------------------------------------------------------------------------

    ## Registered for a minimum of 6 months prior to the study start date # line 98: https://github.com/opensafely/comparative-booster-spring2023/blob/main/analysis/dataset_definition.py 

        inex_bin_6m_reg = (practice_registrations.spanning(
            index_date - days(180), index_date
            )).exists_for_patient(),

    ## Alive on the study start date

        inex_bin_alive = (((patients.date_of_death.is_null()) | (patients.date_of_death.is_after(index_date))) & 
        ((ons_deaths.date.is_null()) | (ons_deaths.date.is_after(index_date)))),

    # Deregistration variables (define it here rather than variables_dates.py, as this variable depends on the index dates ----------------

    ## First deregistration_date on/after index date (deregistered from all supported practices)

        cens_date_dereg= (
            practice_registrations.where(practice_registrations.end_date.is_not_null())
            .where(practice_registrations.end_date.is_on_or_after(index_date))
            .sort_by(practice_registrations.end_date)
            .first_for_patient()
            .end_date
        ),

    # Quality assurance variables---------------------------------------------------------------------------------------------------------- 

        ## Prostate cancer
        qa_bin_prostate_cancer=(
            (last_matching_event_clinical_snomed_before(
                prostate_cancer_snomed, index_date
            ).exists_for_patient()) |
            (last_matching_event_apc_before(
                prostate_cancer_icd10, index_date
            ).exists_for_patient()) 
        ),

        ## Pregnancy
        qa_bin_pregnancy=last_matching_event_clinical_snomed_before(
            pregnancy_snomed, index_date
        ).exists_for_patient(),

        ## Year of birth
        qa_num_birth_year=patients.date_of_birth.year,

        ## COCP or hrt medication
        qa_bin_hrtcocp=last_matching_med_dmd_before(
            cocp_dmd + hrt_dmd, index_date
        ).exists_for_patient(),
    )
    
    return dynamic_variables
