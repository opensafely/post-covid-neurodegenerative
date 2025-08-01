from ehrql import (
    days,
    case,
    when,
    minimum_of,
)
# Bring table definitions from the TPP backend 
from ehrql.tables.tpp import ( 
    patients, 
    practice_registrations, 
    addresses, 
    appointments, 
    occupation_on_covid_vaccine_record,
    sgss_covid_all_tests,
    apcs, 
    clinical_events, 
    ons_deaths,
)

# Codelists from codelists.py (which pulls all variables from the codelist folder)
from codelists import *


# Call functions from variable_helper_functions
from variable_helper_functions import (
    ever_matching_event_clinical_ctv3_before,
    first_matching_event_clinical_snomed_between,
    first_matching_event_apc_between,
    matching_death_between,
    last_matching_event_clinical_ctv3_before,
    last_matching_event_clinical_snomed_before,
    last_matching_med_dmd_before,
    last_matching_event_apc_before,
    filter_codes_by_category,
)


def generate_variables(index_date, end_date_exp, end_date_out):  

    ## Define individual variables first 
    ## Then define a dictionary with all exposures, outcomes, covariates, and other variables

    ## Inclusion/exclusion criteria------------------------------------------------------------------------

    ### Registered for a minimum of 6 months prior to index date
    inex_bin_6m_reg = (practice_registrations.spanning(
        index_date - days(180), index_date
        )).exists_for_patient()

    ### Alive on the index date
    inex_bin_alive = (((patients.date_of_death.is_null()) | (patients.date_of_death.is_after(index_date))) & 
    ((ons_deaths.date.is_null()) | (ons_deaths.date.is_after(index_date))))

    ## Censoring criteria----------------------------------------------------------------------------------

    ### Deregistered
    cens_date_dereg = (
        practice_registrations.where(practice_registrations.end_date.is_not_null())
        .where(practice_registrations.end_date.is_on_or_after(index_date))
        .sort_by(practice_registrations.end_date)
        .first_for_patient()
        .end_date
    )

    ## Exposures-------------------------------------------------------------------------------------------

    ### COVID-19
    tmp_exp_date_covid_sgss = (
        sgss_covid_all_tests.where(
            sgss_covid_all_tests.specimen_taken_date.is_on_or_between(index_date, end_date_exp)
        )
        .where(sgss_covid_all_tests.is_positive)
        .sort_by(sgss_covid_all_tests.specimen_taken_date)
        .first_for_patient()
        .specimen_taken_date
    )
    tmp_exp_date_covid_gp = (
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
    tmp_exp_date_covid_apc = (
        apcs.where(
            ((apcs.primary_diagnosis.is_in(covid_codes)) | 
             (apcs.secondary_diagnosis.is_in(covid_codes))) & 
            (apcs.admission_date.is_on_or_between(index_date, end_date_exp))
        )
        .sort_by(apcs.admission_date)
        .first_for_patient()
        .admission_date
    )
    tmp_exp_covid_death = matching_death_between(covid_codes, index_date, end_date_exp)
    tmp_exp_date_death = ons_deaths.date
    tmp_exp_date_covid_death = case(
        when(tmp_exp_covid_death).then(tmp_exp_date_death)
    )
    
    exp_date_covid = minimum_of(
        tmp_exp_date_covid_sgss, 
        tmp_exp_date_covid_gp,
        tmp_exp_date_covid_apc,
        tmp_exp_date_covid_death
    )

    ## Quality assurance-----------------------------------------------------------------------------------

    ### Prostate cancer
    qa_bin_prostate_cancer = (
        (last_matching_event_clinical_snomed_before(
            prostate_cancer_snomed, index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
            prostate_cancer_icd10, index_date
        ).exists_for_patient())
    )

    ### Pregnancy
    qa_bin_pregnancy = last_matching_event_clinical_snomed_before(
        pregnancy_snomed, index_date
    ).exists_for_patient()

    ### Year of birth
    qa_num_birth_year = patients.date_of_birth.year

    ## COCP or heart medication
    qa_bin_hrtcocp = last_matching_med_dmd_before(
        cocp_dmd + hrt_dmd, index_date
    ).exists_for_patient()

    ## Outcomes - Neurodegenerative Primary/Secondary/Death Codes -----------------------------------------
    
    ### Dementias

    ### Dementia risk conditions (Cognitive Impairment)
    tmp_out_date_cis_gp = (
        first_matching_event_clinical_snomed_between(
        cis_snomed, index_date, end_date_out  
        ).date
    )

    out_date_cis = tmp_out_date_cis_gp # no icd10

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

    ## MS and MND
    tmp_out_date_neuro_other_gp = minimum_of(
        tmp_out_date_mnd_gp, 
        tmp_out_date_ms_gp
    )
    tmp_out_date_neuro_other_apc = minimum_of(
        tmp_out_date_mnd_apc, 
        tmp_out_date_ms_apc
    )
    
    tmp_out_date_neuro_other_death = minimum_of(
        tmp_out_date_mnd_death, 
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

    ## Combined RLS and RSD

    tmp_out_date_parkrisk_gp = minimum_of(
        tmp_out_date_rls_gp,
        tmp_out_date_rsd_gp
    )

    out_date_parkrisk = minimum_of(
        out_date_rls,
        out_date_rsd
    )

    ## Strata----------------------------------------------------------------------------------------------

    ### Region
    strat_cat_region = practice_registrations.for_patient_on(index_date).practice_nuts1_region_name

    ## Core covariates-------------------------------------------------------------------------------------

    ### Age
    cov_num_age = patients.age_on(index_date)

    ### Sex
    cov_cat_sex = patients.sex

    ### Ethnicity
    tmp_cov_cat_ethnicity = (
        clinical_events.where(clinical_events.snomedct_code.is_in(ethnicity_snomed))
        .where(clinical_events.date.is_on_or_before(index_date))
        .sort_by(clinical_events.date)
        .last_for_patient()
        .snomedct_code
    )

    cov_cat_ethnicity = tmp_cov_cat_ethnicity.to_category(
        ethnicity_snomed
    )

    ### Deprivation
    cov_cat_imd = case(
        when((addresses.for_patient_on(index_date).imd_rounded >= 0) & 
                (addresses.for_patient_on(index_date).imd_rounded < int(32844 * 1 / 5))).then("1 (most deprived)"),
        when(addresses.for_patient_on(index_date).imd_rounded < int(32844 * 2 / 5)).then("2"),
        when(addresses.for_patient_on(index_date).imd_rounded < int(32844 * 3 / 5)).then("3"),
        when(addresses.for_patient_on(index_date).imd_rounded < int(32844 * 4 / 5)).then("4"),
        when(addresses.for_patient_on(index_date).imd_rounded < int(32844 * 5 / 5)).then("5 (least deprived)"),
        otherwise="unknown",
    )

    ### Smoking status
    tmp_most_recent_smoking_cat = (
        last_matching_event_clinical_ctv3_before(smoking_clear, index_date)
        .ctv3_code.to_category(smoking_clear)
    )
    tmp_ever_smoked = ever_matching_event_clinical_ctv3_before(
        (filter_codes_by_category(smoking_clear, include=["S", "E"])), index_date
        ).exists_for_patient()

    cov_cat_smoking = case(
        when(tmp_most_recent_smoking_cat == "S").then("S"),
        when((tmp_most_recent_smoking_cat == "E") | ((tmp_most_recent_smoking_cat == "N") & (tmp_ever_smoked == True))).then("E"),
        when((tmp_most_recent_smoking_cat == "N") & (tmp_ever_smoked == False)).then("N"),
        otherwise="M"
    )

    ### Care home status
    cov_bin_carehome = (
        addresses.for_patient_on(index_date).care_home_is_potential_match |
        addresses.for_patient_on(index_date).care_home_requires_nursing |
        addresses.for_patient_on(index_date).care_home_does_not_require_nursing
    )

    ### Consultation rate in 2019
    tmp_cov_num_consrate2019 = appointments.where(
        appointments.status.is_in([
            "Arrived",
            "In Progress",
            "Finished",
            "Visit",
            "Waiting",
            "Patient Walked Out",
            ]) & appointments.start_date.is_on_or_between("2019-01-01", "2019-12-31")
            ).count_for_patient()    

    cov_num_consrate2019 = case(
        when(tmp_cov_num_consrate2019 <= 365).then(tmp_cov_num_consrate2019),
        otherwise=365,
    )

    ### Healthcare worker
    cov_bin_hcworker = occupation_on_covid_vaccine_record.where(
        (occupation_on_covid_vaccine_record.is_healthcare_worker == True)
    ).exists_for_patient()

    ### Dementia (A core protocol covariate, but not used in this protocol)
    # cov_bin_dementia = (
    #     (last_matching_event_clinical_snomed_before(
    #         dementia_snomed + dementia_vascular_snomed, index_date
    #     ).exists_for_patient()) |
    #     (last_matching_event_apc_before(
    #         dementia_icd10 + dementia_vascular_icd10, index_date
    #     ).exists_for_patient())
    # )

    ### Liver disease
    cov_bin_liver_disease = (
        (last_matching_event_clinical_snomed_before(
            liver_disease_snomed, index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
            liver_disease_icd10, index_date
        ).exists_for_patient())
    )

    ### Chronic kidney disease (CKD)
    cov_bin_ckd = (
        (last_matching_event_clinical_snomed_before(
            ckd_snomed, index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
            ckd_icd10, index_date
        ).exists_for_patient())
    )

    ### Cancer
    cov_bin_cancer = (
        (last_matching_event_clinical_snomed_before(
            cancer_snomed, index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
            cancer_icd10, index_date
        ).exists_for_patient())
    )

    ### Hypertension (Also used for high vascular risk covariate)
    cov_bin_hypertension = (
        (last_matching_event_clinical_snomed_before(
            hypertension_snomed, index_date
        ).exists_for_patient()) |
        (last_matching_med_dmd_before(
            hypertension_drugs_dmd, index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
            hypertension_icd10, index_date
        ).exists_for_patient())
    )

    ### Diabetes (Also used for high vascular risk covariate)
    cov_bin_diabetes = (
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

    ### Obesity 
    cov_bin_obesity = (
        (last_matching_event_clinical_snomed_before(
            bmi_obesity_snomed, index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
            bmi_obesity_icd10, index_date
        ).exists_for_patient())
    )

    ### COPD
    cov_bin_copd = (
        (last_matching_event_clinical_ctv3_before(
            copd_ctv3, index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
            copd_icd10, index_date
        ).exists_for_patient())
    )

    ### Acute myocardial infarction (AMI)
    cov_bin_ami = (
        (last_matching_event_clinical_snomed_before(
            ami_snomed, index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
            ami_icd10 + ami_prior_icd10, index_date
        ).exists_for_patient())
    )

    ### Depression
    cov_bin_depression = (
        (last_matching_event_clinical_snomed_before(
            depression_snomed, index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
            depression_icd10, index_date
        ).exists_for_patient())
    )

    ### Ischaemic stroke
    cov_bin_stroke_isch = (
        (last_matching_event_clinical_snomed_before(
            stroke_isch_snomed, index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
            stroke_isch_icd10, index_date
        ).exists_for_patient())
    )

    ## Project specific covariates-------------------------------------------------------------------------

    ## History of Cognitive Impairment symptoms
    cov_bin_cis= (
        last_matching_event_clinical_snomed_before(
        cis_snomed, index_date
        ).exists_for_patient()       
    )

    ## History of Any Dementia
    cov_bin_dem_any= (
        (last_matching_event_clinical_snomed_before(
        dem_alz_snomed   +
        dem_lb_snomed    +
        dem_vasc_snomed  +
        dem_other_snomed +
        dem_unspec_snomed, index_date
        ).exists_for_patient()) |
        ((last_matching_event_apc_before(
        dem_alz_icd10    +
        dem_vasc_icd10   +
        dem_other_icd10  +
        dem_unspec_icd10, index_date
        )).exists_for_patient())       
    )

    ## High Vascular Risk
    cov_bin_highvascrisk=(
        cov_bin_hypertension | cov_bin_diabetes
    )

    ## History of Migrane
    cov_bin_migraine= (
        last_matching_event_clinical_snomed_before(
        migraine_snomed, index_date
        )
    .exists_for_patient() |
        (last_matching_event_apc_before(
        migraine_icd10, index_date
        ).exists_for_patient()) 
    )

    ##  History of Motor Neurone Disease
    cov_bin_mnd= (
        last_matching_event_clinical_snomed_before(
        mnd_snomed, index_date
        ).exists_for_patient()   |
        (last_matching_event_apc_before(
        mnd_icd10, index_date
        ).exists_for_patient()) 
    )

    ## History of Multiple Sclerosis
    cov_bin_ms= (
        last_matching_event_clinical_snomed_before(
        ms_snomed, index_date
        ).exists_for_patient() |
        (last_matching_event_apc_before(
        ms_icd10, index_date
        ).exists_for_patient()) 
    )

    ## History of Parkinsons
    cov_bin_park= (
        (last_matching_event_clinical_snomed_before(
        park_snomed, index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
        park_icd10, index_date
        ).exists_for_patient()) 
    )

    ## History of Parkinson's Risk (REM Sleep Disorder/Restless Leg syndrome)
    cov_bin_parkrisk= (
        (last_matching_event_clinical_snomed_before(
        rls_snomed, index_date
        ).exists_for_patient()) |
        (last_matching_event_clinical_snomed_before(
        rsd_snomed,  index_date
        ).exists_for_patient()) |
        (last_matching_event_apc_before(
        rsd_icd10,  index_date
        ).exists_for_patient()) 
    )

    ## Subgroups-------------------------------------------------------------------------------------------

    ### History of COVID-19
    tmp_sub_bin_covidhistory_sgss = (
        sgss_covid_all_tests.where(
            sgss_covid_all_tests.specimen_taken_date.is_before(index_date)
        )
        .where(sgss_covid_all_tests.is_positive)
        .exists_for_patient()
    )
    tmp_sub_bin_covidhistory_gp = (
        clinical_events.where(
            (clinical_events.ctv3_code.is_in(
                covid_primary_care_code + 
                covid_primary_care_positive_test + 
                covid_primary_care_sequalae)) &
            clinical_events.date.is_before(index_date)
        )
        .exists_for_patient()
    )
    tmp_sub_bin_covidhistory_apc = (
        apcs.where(
            ((apcs.primary_diagnosis.is_in(covid_codes)) | (apcs.secondary_diagnosis.is_in(covid_codes))) & 
            (apcs.admission_date.is_before(index_date))
        )
        .exists_for_patient()
    )

    sub_bin_covidhistory = (
        tmp_sub_bin_covidhistory_sgss |
        tmp_sub_bin_covidhistory_gp |
        tmp_sub_bin_covidhistory_apc
    )

    ### COVID-19 severity
    tmp_sub_date_covidhospital = (
        apcs.where(
            (apcs.primary_diagnosis.is_in(covid_codes)) & 
            (apcs.admission_date.is_on_or_after(exp_date_covid))
        )
        .sort_by(apcs.admission_date)
        .first_for_patient()
        .admission_date
    )

    sub_cat_covidhospital = case(
        when(
            (exp_date_covid.is_not_null()) &
            (tmp_sub_date_covidhospital.is_not_null()) &
            ((tmp_sub_date_covidhospital - exp_date_covid).days >= 0) &
            ((tmp_sub_date_covidhospital - exp_date_covid).days < 29)
            ).then("hospitalised"),
        when(exp_date_covid.is_not_null()).then("non_hospitalised"),
        when(exp_date_covid.is_null()).then("no_infection")
    )
    

# Start of Dictionary-----------------------------------------------------------------------------------------

    ## Combine the variables into the final dictionary
    dynamic_variables = dict(

        # Inclusion/exclusion criteria--------------------------------------------------------------------------------
        inex_bin_6m_reg = inex_bin_6m_reg,
        inex_bin_alive  = inex_bin_alive,

        # Censoring criteria------------------------------------------------------------------------------------------
        cens_date_dereg = cens_date_dereg,

        # Exposures---------------------------------------------------------------------------------------------------
        exp_date_covid = exp_date_covid,

        # Quality assurance-------------------------------------------------------------------------------------------
        qa_bin_prostate_cancer = qa_bin_prostate_cancer,
        qa_bin_pregnancy       = qa_bin_pregnancy,
        qa_num_birth_year      = qa_num_birth_year,
        qa_bin_hrtcocp         = qa_bin_hrtcocp,

        # Outcomes----------------------------------------------------------------------------------------------------

        ### ---First recording of the outcome in during the study period
        out_date_cis         = out_date_cis,        # Cognitive Impairment Symptoms
        out_date_dem_alz     = out_date_dem_alz,    # Alzheimer's Disease
        out_date_dem_vasc    = out_date_dem_vasc,   # Vascular Dementia
        out_date_dem_lb      = out_date_dem_lb,     # Lewy Body Dementia
        out_date_dem_other   = out_date_dem_other,  # Other Dementia
        out_date_dem_unspec  = out_date_dem_unspec, # Unspecified Dementia
        out_date_dem_any     = out_date_dem_any,    # Any Dementia
        out_date_migraine    = out_date_migraine,
        out_date_mnd         = out_date_mnd,        # Motor Neurone Disease
        out_date_ms          = out_date_ms,         # Multiple Sclerosis
        out_date_neuro_other = out_date_neuro_other,# MS or MND
        out_date_park        = out_date_park,       # Parkinson's Disease
        out_date_parkrisk    = out_date_parkrisk,   # combo of RSD and RLS 
        out_date_rls         = out_date_rls,        # Restless Leg Syndrome
        out_date_rsd         = out_date_rsd,        # REM Sleep Disorder

        ## Tmp GP
        tmp_out_date_cis_gp         = tmp_out_date_cis_gp,        # Cognitive Impairment Symptoms
        tmp_out_date_dem_alz_gp     = tmp_out_date_dem_alz_gp,    # Alzheimer's Disease
        tmp_out_date_dem_vasc_gp    = tmp_out_date_dem_vasc_gp,   # Vascular Dementia
        tmp_out_date_dem_lb_gp      = tmp_out_date_dem_lb_gp,     # Lewy Body Dementia
        tmp_out_date_dem_other_gp   = tmp_out_date_dem_other_gp,  # Other Dementia
        tmp_out_date_dem_unspec_gp  = tmp_out_date_dem_unspec_gp, # Unspecified Dementia
        tmp_out_date_dem_any_gp     = tmp_out_date_dem_any_gp,    # Any Dementia
        tmp_out_date_migraine_gp    = tmp_out_date_migraine_gp,
        tmp_out_date_mnd_gp         = tmp_out_date_mnd_gp,        # Motor Neurone Disease
        tmp_out_date_ms_gp          = tmp_out_date_ms_gp,         # Multiple Sclerosis
        tmp_out_date_neuro_other_gp = tmp_out_date_neuro_other_gp,# MS or MND
        tmp_out_date_park_gp        = tmp_out_date_park_gp,       # Parkinson's Disease
        tmp_out_date_parkrisk_gp    = tmp_out_date_parkrisk_gp,   # combo of RSD and RLS
        tmp_out_date_rls_gp         = tmp_out_date_rls_gp,        # Restless Leg Syndrome
        tmp_out_date_rsd_gp         = tmp_out_date_rsd_gp,        # REM Sleep Disorder

        ## Tmp APC
        # CIS gap
        tmp_out_date_dem_alz_apc     = tmp_out_date_dem_alz_apc,    # Alzheimer's Disease
        tmp_out_date_dem_vasc_apc    = tmp_out_date_dem_vasc_apc,   # Vascular Dementia
        # Lewy Body Gap
        tmp_out_date_dem_other_apc   = tmp_out_date_dem_other_apc,  # Other Dementia
        tmp_out_date_dem_unspec_apc  = tmp_out_date_dem_unspec_apc, # Unspecified Dementia
        tmp_out_date_dem_any_apc     = tmp_out_date_dem_any_apc,    # Any Dementia
        tmp_out_date_migraine_apc    = tmp_out_date_migraine_apc,
        tmp_out_date_mnd_apc         = tmp_out_date_mnd_apc,        # Motor Neurone Disease
        tmp_out_date_ms_apc          = tmp_out_date_ms_apc,         # Multiple Sclerosis
        tmp_out_date_neuro_other_apc = tmp_out_date_neuro_other_apc,# MS or MND
        tmp_out_date_park_apc        = tmp_out_date_park_apc,       # Parkinson's Disease
        tmp_out_date_parkrisk_apc   = tmp_out_date_rsd_apc,        # combo of RSD and RLS (but only RSD here)
        # RLD gap
        tmp_out_date_rsd_apc         = tmp_out_date_rsd_apc,        # REM Sleep Disorder


        ## Tmp Death
        # CIS gap       
        tmp_out_date_dem_alz_death     = tmp_out_date_dem_alz_death,    # Alzheimer's Disease
        tmp_out_date_dem_vasc_death    = tmp_out_date_dem_vasc_death,   # Vascular Dementia
        # Lewy Body Gap
        tmp_out_date_dem_other_death   = tmp_out_date_dem_other_death,  # Other Dementia
        tmp_out_date_dem_unspec_death  = tmp_out_date_dem_unspec_death, # Unspecified Dementia
        tmp_out_date_dem_any_death     = tmp_out_date_dem_any_death,    # Any Dementia
        tmp_out_date_migraine_death    = tmp_out_date_migraine_death,
        tmp_out_date_mnd_death         = tmp_out_date_mnd_death,         # Motor Neurone Disease
        tmp_out_date_ms_death          = tmp_out_date_ms_death,          # Multiple Sclerosis
        tmp_out_date_neuro_other_death = tmp_out_date_neuro_other_death, # MS or MND
        tmp_out_date_park_death        = tmp_out_date_park_death,        # Parkinson's Disease
        tmp_out_date_parkrisk_death   = tmp_out_date_rsd_death,         # combo of RSD and RLS (but only RSD here)
        # RLD gap
        tmp_out_date_rsd_death         = tmp_out_date_rsd_death,         # REM Sleep Disorder

        ### Strata----------------------------------------------------------------------------------------------------
        strat_cat_region = strat_cat_region,

        ### Core covariates-------------------------------------------------------------------------------------------
        cov_num_age           = cov_num_age,
        cov_cat_sex           = cov_cat_sex,

        cov_bin_ami           = cov_bin_ami,
        cov_bin_cancer        = cov_bin_cancer,
        cov_bin_carehome      = cov_bin_carehome,
        cov_bin_ckd           = cov_bin_ckd,
        cov_num_consrate2019  = cov_num_consrate2019,
        cov_bin_copd          = cov_bin_copd,
        # cov_bin_dementia = cov_bin_dementia,
        cov_bin_depression    = cov_bin_depression,
        cov_bin_diabetes      = cov_bin_diabetes,
        cov_cat_ethnicity     = cov_cat_ethnicity,
        cov_bin_hcworker      = cov_bin_hcworker,
        cov_bin_hypertension  = cov_bin_hypertension,
        cov_cat_imd           = cov_cat_imd,
        cov_bin_liver_disease = cov_bin_liver_disease,
        cov_bin_obesity       = cov_bin_obesity,
        cov_cat_smoking       = cov_cat_smoking,
        cov_bin_stroke_isch   = cov_bin_stroke_isch,

        ### Project specific covariates----------------------------------------------------------------------------------
        cov_bin_cis            = cov_bin_cis,
        cov_bin_dem_any        = cov_bin_dem_any,
        cov_bin_highvascrisk = cov_bin_highvascrisk,
        cov_bin_mnd            = cov_bin_mnd,
        cov_bin_ms             = cov_bin_ms,
        cov_bin_migraine       = cov_bin_migraine,
        cov_bin_park           = cov_bin_park,
        cov_bin_parkrisk      = cov_bin_parkrisk,
        
        ### Subgroups-----------------------------------------------------------------------------------------------------
        sub_bin_covidhistory  = sub_bin_covidhistory,
        sub_cat_covidhospital = sub_cat_covidhospital
    ) 
    
    return dynamic_variables
