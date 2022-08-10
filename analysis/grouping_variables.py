
from datetime import date

from cohortextractor import (
    patients, 
)

# import codelists.py script
from codelists import *

# import json module
import json

import pandas as pd

### import groups and dates
# jcvi_groups
jcvi_groups = pd.read_csv(
    filepath_or_buffer='output/vax_jcvi_groups.csv',
    dtype=str
)
dict_jcvi = {jcvi_groups['group'][i]: jcvi_groups['definition'][i] for i in jcvi_groups.index}
ratio_jcvi = {jcvi_groups['group'][i]: 1/len(jcvi_groups.index) for i in jcvi_groups.index}

# elig_dates
elig_dates = pd.read_csv(
    filepath_or_buffer='output/vax_eligible_dates.csv',
    dtype=str
)
dict_elig = { elig_dates['date'][i] : elig_dates['description'][i] for i in elig_dates.index }
ratio_elig = { elig_dates['date'][i] : 1/len(elig_dates.index) for i in elig_dates.index }

#study_dates
with open("output/study_dates.json") as f:
  study_dates = json.load(f)

# define variables explicitly
ref_age_1=study_dates["ref_age_1"] # reference date for calculating age for phase 1 groups
ref_age_2=study_dates["ref_age_2"] # reference date for calculating age for phase 2 groups
ref_cev=study_dates["ref_cev"] # reference date for calculating clinically extremely vulnerable group
ref_ar=study_dates["ref_ar"] #reference date for caluclating at risk group
start_date=study_dates["start_date"] # start of phase 1
end_date=study_dates["end_date"] # end of followup
pandemic_start=study_dates["pandemic_start"]

## function to add days to a string date
from datetime import datetime, timedelta
def days(datestring, days):
  
  dt = datetime.strptime(datestring, "%Y-%m-%d").date()
  dt_add = dt + timedelta(days)
  datestring_add = datetime.strftime(dt_add, "%Y-%m-%d")

  return datestring_add

# Notes:
# for inequalities in the study definition, an extra expression is added to align with the comparison definitions in https://github.com/opensafely/covid19-vaccine-coverage-tpp-emis/blob/master/analysis/comparisons.py
# variables that define JCVI group membership MUST NOT be dependent on elig_date (index_date), this is for selecting the population based on registration dates and for deriving descriptive covariates
# JCVI groups are derived using ref_age_1, ref_age_2, ref_cev and ref_ar

jcvi_variables = dict(
  # age on phase 1 reference date
    vax_jcvi_age_1=patients.age_as_of(
        ref_age_1,
        return_expectations={
            "int": {"distribution": "population_ages"},
            "rate": "universal",
        },
    ),

    # age on phase 2 reference date
    vax_jcvi_age_2=patients.age_as_of(
        ref_age_2,
        return_expectations={
            "int": {"distribution": "population_ages"},
            "rate": "universal",
        },
    ),

    # patient sex
    # sex=patients.sex(
    #     return_expectations={
    #     "rate": "universal",
    #     "category": {"ratios": {"M": 0.49, "F": 0.51}},
    #     "incidence": 0.99,
    #     }
    # ),

    vax_cat_jcvi_group=patients.categorised_as(
        dict_jcvi,
        return_expectations={
            "rate": "universal",
            "incidence": 1,
            "category": { 
                "ratios": ratio_jcvi 
                }
        },

    ### NEED TO DISCUSS CONDITIONS FOR PREGNANCY (FEMALE AND <50)
    ### WAS ADDED INITIALLY TO AVOID CODING ERRORS, BUT NOT VERY INCLUSIVE SO CONSIDER REVISING
    #### Pregnancy or Delivery codes recorded (for deriving JCVI group)
    # # date of last pregnancy code in 36 weeks before ref_cev
    preg_group=patients.satisfying(
        """
        (preg_36wks_date AND cov_cat_sex = 'F' AND vax_jcvi_age_1 < 50) AND
        (pregdel_pre_date <= preg_36wks_date OR NOT pregdel_pre_date)
        """,
        preg_36wks_date=patients.with_these_clinical_events(
            preg_primis,
            returning="date",
            find_last_match_in_period=True,
            between=[days(ref_cev, -252), days(ref_cev, -1)],
            date_format="YYYY-MM-DD",
        ),
        # date of last delivery code recorded in 36 weeks before elig_date
        pregdel_pre_date=patients.with_these_clinical_events(
            pregdel_primis,
            returning="date",
            find_last_match_in_period=True,
            between=[days(ref_cev, -252), days(ref_cev, -1)],
            date_format="YYYY-MM-DD",
        ),
    ),

    #### clinically extremely vulnerable group variables
    cev_group=patients.satisfying(
        "severely_clinically_vulnerable AND NOT less_vulnerable",

        # SHIELDED GROUP - first flag all patients with "high risk" codes
        severely_clinically_vulnerable=patients.with_these_clinical_events(
            shield_primis,
            returning="binary_flag",
            on_or_before=days(ref_cev, -1),
            find_last_match_in_period=True,
        ),

        # find date at which the high risk code was added
        severely_clinically_vulnerable_date=patients.date_of(
            "severely_clinically_vulnerable",
            date_format="YYYY-MM-DD",
        ),

        # NOT SHIELDED GROUP (medium and low risk) - only flag if later than 'shielded'
        less_vulnerable=patients.with_these_clinical_events(
            nonshield_primis,
            between=["severely_clinically_vulnerable_date + 1 day", days(ref_cev, -1)],
        ),
        return_expectations={"incidence": 0.01},
    ),

    #### at-risk group variables
    # Asthma Diagnosis code
    astdx=patients.with_these_clinical_events(
        ast_primis,
        returning="binary_flag",
        on_or_before=days(ref_ar, -1),
        return_expectations={"incidence": 0.05},
    ),
            
    # asthma
    asthma_group=patients.satisfying(
        """
        astadm OR
        (astdx AND astrxm1 AND astrxm2 AND astrxm3)
        """,
        # day before date at which at risk group became eligible
        # Asthma Admission codes
        astadm=patients.with_these_clinical_events(
            astadm_primis,
            returning="binary_flag",
            on_or_before=days(ref_ar, -1),
        ),
        # Asthma systemic steroid prescription code in month 1
        astrxm1=patients.with_these_medications(
            astrx_primis,
            returning="binary_flag",
            between=[days(ref_ar, -31), days(ref_ar, -1)],
        ),
        # Asthma systemic steroid prescription code in month 2
        astrxm2=patients.with_these_medications(
            astrx_primis,
            returning="binary_flag",
            between=[days(ref_ar, -61), days(ref_ar, -32)],
        ),
        # Asthma systemic steroid prescription code in month 3
        astrxm3=patients.with_these_medications(
            astrx_primis,
            returning="binary_flag",
            between=[days(ref_ar, -91), days(ref_ar, -62)],
        ),
        return_expectations={"incidence": 0.01},
    ),

    # Chronic Respiratory Disease other than asthma
    resp_group=patients.with_these_clinical_events(
        resp_primis,
        returning="binary_flag",
        on_or_before=days(ref_ar, -1),
        return_expectations={"incidence": 0.02},
    ),

    # Chronic Neurological Disease including Significant Learning Disorder
    cns_group=patients.with_these_clinical_events(
        cns_primis,
        returning="binary_flag",
        on_or_before=days(ref_ar, -1),
        return_expectations={"incidence": 0.01},
    ),

    # diabetes
    diab_group=patients.satisfying(
        """
        (NOT dmres_date AND diab_date) OR
        (dmres_date < diab_date)
        """,
        diab_date=patients.with_these_clinical_events(
            diab_primis,
            returning="date",
            find_last_match_in_period=True,
            on_or_before=days(ref_ar, -1),
            date_format="YYYY-MM-DD",
        ),
        dmres_date=patients.with_these_clinical_events(
            dmres_primis,
            returning="date",
            find_last_match_in_period=True,
            on_or_before=days(ref_ar, -1),
            date_format="YYYY-MM-DD",
        ),
        return_expectations={"incidence": 0.01},
    ),

    # severe mental illness codes
    sevment_group=patients.satisfying(
        """
        (NOT smhres_date AND sev_mental_date) OR
        smhres_date < sev_mental_date
        """,
        # Severe Mental Illness codes
        sev_mental_date=patients.with_these_clinical_events(
            sev_mental_primis,
            returning="date",
            find_last_match_in_period=True,
            on_or_before=days(ref_ar, -1),
            date_format="YYYY-MM-DD",
        ),
        # Remission codes relating to Severe Mental Illness
        smhres_date=patients.with_these_clinical_events(
            smhres_primis,
            returning="date",
            find_last_match_in_period=True,
            on_or_before=days(ref_ar, -1),
            date_format="YYYY-MM-DD",
        ),
        return_expectations={"incidence": 0.01},
    ),

    # Chronic heart disease codes
    chd_group=patients.with_these_clinical_events(
        chd_primis,
        returning="binary_flag",
        on_or_before=days(ref_ar, -1),
        return_expectations={"incidence": 0.01},
    ),

    # Chronic kidney disease diagnostic codes
    ckd_group=patients.satisfying(
        """
            ckd OR
            (ckd15_date AND 
            (ckd35_date >= ckd15_date) OR (ckd35_date AND NOT ckd15_date))
        """,
        # Chronic kidney disease codes - all stages
        ckd15_date=patients.with_these_clinical_events(
            ckd15_primis,
            returning="date",
            find_last_match_in_period=True,
            on_or_before=days(ref_ar, -1),
            date_format="YYYY-MM-DD",
        ),
        # Chronic kidney disease codes-stages 3 - 5
        ckd35_date=patients.with_these_clinical_events(
            ckd35_primis,
            returning="date",
            find_last_match_in_period=True,
            on_or_before=days(ref_ar, -1),
            date_format="YYYY-MM-DD",
        ),
        # Chronic kidney disease diagnostic codes
        ckd=patients.with_these_clinical_events(
            ckd_primis,
            returning="binary_flag",
            on_or_before=days(ref_ar, -1),
        ),
        return_expectations={"incidence": 0.01},
    ),

    # Chronic Liver disease codes
    cld_group=patients.with_these_clinical_events(
        cld_primis,
        returning="binary_flag",
        on_or_before=days(ref_ar, -1),
        return_expectations={"incidence": 0.01},
    ),

    # immunosuppressed
    immuno_group=patients.satisfying(
        "immrx OR immdx", 
        # immunosuppression diagnosis codes
        immdx=patients.with_these_clinical_events(
            immdx_primis,
            returning="binary_flag",
            on_or_before=days(ref_ar, -1),
        ),
        # Immunosuppression medication codes
        immrx=patients.with_these_medications(
            immrx_primis,
            returning="binary_flag",
            between=[days(ref_ar, -6*30), days(ref_ar, -1)],
        ),
        return_expectations={"incidence": 0.01},
    ),

    # Asplenia or Dysfunction of the Spleen codes
    spln_group=patients.with_these_clinical_events(
        spln_primis,
        returning="binary_flag",
        on_or_before=days(ref_ar, -1),
        return_expectations={"incidence": 0.01},
    ),

    # Wider Learning Disability
    learndis_group=patients.with_these_clinical_events(
        learndis_primis,
        returning="binary_flag",
        on_or_before=days(ref_ar, -1),
        return_expectations={"incidence": 0.01},
    ),

    # severe obesity
    sevobese_group=patients.satisfying(
        """
        (sev_obesity_date AND NOT bmi_date) OR
        (sev_obesity_date > bmi_date) OR
        bmi_value_temp >= 40
        """,
        bmi_stage_date=patients.with_these_clinical_events(
            bmi_stage_primis,
            returning="date",
            find_last_match_in_period=True,
            on_or_before=days(ref_ar, -1),
            date_format="YYYY-MM-DD",
        ),
        sev_obesity_date=patients.with_these_clinical_events(
            sev_obesity_primis,
            returning="date",
            find_last_match_in_period=True,
            ignore_missing_values=True,
            between= ["bmi_stage_date", days(ref_ar, -1)],
            date_format="YYYY-MM-DD",
        ),
        bmi_date=patients.with_these_clinical_events(
            bmi_primis,
            returning="date",
            ignore_missing_values=True,
            find_last_match_in_period=True,
            on_or_before=days(ref_ar, -1),
            date_format="YYYY-MM-DD",
        ),
        bmi_value_temp=patients.with_these_clinical_events(
            bmi_primis,
            returning="numeric_value",
            ignore_missing_values=True,
            find_last_match_in_period=True,
            on_or_before=days(ref_ar, -1),
            return_expectations={
                "float": {"distribution": "normal", "mean": 25, "stddev": 5},
            },
        ),
        return_expectations={"incidence": 0.01},
    ),

    # at risk group
    atrisk_group=patients.satisfying(
             """
             immuno_group OR
             ckd_group OR
             resp_group OR
             diab_group OR
             cld_group OR
             cns_group OR
             chd_group OR
             spln_group OR
             learndis_group OR
             sevment_group OR
             sevobese_group 
            """,
            return_expectations = {
            "incidence": 0.01,
            },
    ),

    # Patients in long-stay nursing and residential care
    longres_group=patients.with_these_clinical_events(
        longres_primis,
        returning="binary_flag",
        on_or_before=days(start_date, -1),
        return_expectations={"incidence": 0.01},
    ),
    ),

    # vaccine eligibility dates
    vax_date_eligible=patients.categorised_as(
       dict_elig,
        return_expectations={
            "category": {"ratios": 
            ratio_elig
            },
            "incidence": 1,
        },
    ),

)
