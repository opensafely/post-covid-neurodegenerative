from ehrql import (
    case,
    when,
    minimum_of
)
# Bring table definitions from the TPP backend 
from ehrql.tables.tpp import ( 
    ons_deaths
)

# Codelists from codelists.py (which pulls all variables from the codelist folder)
from codelists_rsd import *


# Call functions from variable_helper_functions
from variable_rsd_helper_functions import (
    first_matching_event_clinical_snomed_between,
    first_matching_event_clinical_ctv3_between,
    first_matching_event_apc_between,
    matching_death_between
)


def generate_rsd(index_date, end_date_exp, end_date_out):  

# Defining just the rsd variables

    ## RSD GP1
    tmp_out_date_rsd_gp= (
        first_matching_event_clinical_snomed_between(
        rsd_snomed, index_date, end_date_out 
        ).date
    )

    ## RSD GP2
    tmp_out_date_rsd_gp_new= (
        first_matching_event_clinical_snomed_between(
        rsd_snomed_new, index_date, end_date_out 
        ).date
    )
    
    ## RSD CTV3
    tmp_out_date_rsd_ctv3 = (
        first_matching_event_clinical_ctv3_between(
            rsd_ctv3, index_date, end_date_out
        ).date
    )

    ## RSD APC
    tmp_out_date_rsd_apc= (
        first_matching_event_apc_between(
        rsd_icd10, index_date, end_date_out 
        ).admission_date
    )

    ## RSD Death
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


# Start of Dictionary-----------------------------------------------------------------------------------------

    ## Combine the variables into the final dictionary
    dynamic_variables = dict(

        # Outcomes----------------------------------------------------------------------------------------------------

        ### ---First recording of the outcome in during the study period
        out_date_rsd         = out_date_rsd,        # REM Sleep Disorder

        ## Tmp GP
        tmp_out_date_rsd_gp           = tmp_out_date_rsd_gp,              # REM Sleep Disorder
        tmp_out_date_rsd_gp_new       = tmp_out_date_rsd_gp_new,          # REM Sleep Disorder
        
        ## Tmp CTV3
        tmp_out_date_rsd_ctv3         = tmp_out_date_rsd_ctv3,            # REM Sleep Disorder

        ## Tmp APC
        tmp_out_date_rsd_apc          = tmp_out_date_rsd_apc,            # REM Sleep Disorder

        ## Tmp Death
        tmp_out_date_rsd_death        = tmp_out_date_rsd_death,        # REM Sleep Disorder
    ) 
    
    return dynamic_variables
