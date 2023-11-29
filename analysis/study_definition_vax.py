## Set seed
import numpy as np
np.random.seed(123456)

# Cohort extractor
from tracemalloc import start
from cohortextractor import (
  StudyDefinition,
  patients,
  date_expressions,
  codelist_from_csv,
  codelist,
  filter_codes_by_category,
  combine_codelists,
)

#study dates

## Variables for deriving JCVI groups
from grouping_variables import (
  
    study_dates,
    jcvi_variables,
)

## Codelists from codelist.py (which pulls them from the codelist folder)
from codelists import *

## Datetime functions
from datetime import date

## Study definition helper
import study_definition_helper_functions as helpers

## Import common variables function
from common_variables import generate_common_variables
(
    dynamic_variables
) = generate_common_variables(index_date_variable="index_date_cohort", exposure_end_date_variable="end_date_exposure", outcome_end_date_variable = "end_date_outcome")


study = StudyDefinition(

    # Read in index date for study from the output of prelim.R file 
    index_date_cohort = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz', 
        returning = 'index_vax', 
        returning_type = 'date', 
        date_format = 'YYYY-MM-DD',     
    ),

    # end_date_vax = patients.with_value_from_file(
    #     f_path = 'output/index_dates.csv.gz',
    #     returning = 'end_vax',
    #     returning_type = 'date', 
    #     date_format = 'YYYY-MM-DD',
    # ),
    end_date_outcome = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'end_vax',
        returning_type = 'date',
        date_format = 'YYYY-MM-DD',
    ),
    end_date_exposure = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz', 
        returning = 'end_vax', 
        returning_type = 'date', 
        date_format = 'YYYY-MM-DD',     
    ),

    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": study_dates["earliest_expec"], "latest": "today"},
        "rate": "uniform",
        "incidence": 0.5,
    },
   
    # Define the study population 
    # NB: all inclusions and exclusions are performed in stage 1
    population = patients.all(),
   
    # Define sex 
    cov_cat_sex = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'cov_cat_sex',
        returning_type = 'str',  
        ),

    # eligibility date
    # vax_date_eligible = patients.with_value_from_file(
    #     f_path = 'output/index_dates.csv',
    #     returning = 'vax_date_eligible',
    #     returning_type = 'date',
    # ),

# Bring COVID-19 Vaccinations vars from index_dates file

    ## Any covid vaccination, identified by target disease
    vax_date_covid_1 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'vax_date_covid_1',
        returning_type = 'date'          
    ),
    vax_date_covid_2 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'vax_date_covid_2',
        returning_type = 'date'   
    ),
    vax_date_covid_3 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'vax_date_covid_3',
        returning_type = 'date'
    ),

    ## Pfizer BioNTech
    ## NB: may be patient's first COVID vaccine dose or their second if mixed types are given
        
    vax_date_Pfizer_1 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'vax_date_Pfizer_1',
        returning_type = 'date'
    ), 
    vax_date_Pfizer_2 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'vax_date_Pfizer_2',
        returning_type = 'date'
    ),
    vax_date_Pfizer_3 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'vax_date_Pfizer_3',
        returning_type = 'date'
    ),
    
    ## Oxford AZ 
    ## NB: may be patient's first COVID vaccine dose or their second if mixed types are given
    vax_date_AstraZeneca_1 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'vax_date_AstraZeneca_1',
        returning_type = 'date'
    ),
    vax_date_AstraZeneca_2 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'vax_date_AstraZeneca_2',
        returning_type = 'date'
    ),
    vax_date_AstraZeneca_3 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'vax_date_AstraZeneca_3',
        returning_type = 'date'
    ),
    
    ## Moderna
    ## NB: may be patient's first COVID vaccine dose or their second if mixed types are given
    vax_date_Moderna_1 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'vax_date_Moderna_1',
        returning_type = 'date'
    ),            
    vax_date_Moderna_2 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'vax_date_Moderna_2',
        returning_type = 'date'
    ),
    vax_date_Moderna_3 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv.gz',
        returning = 'vax_date_Moderna_3',
        returning_type = 'date'
    ),

    # Define vaccine eligibility variables

        **jcvi_variables, 
    # Define common variables (e.g., exposures, outcomes, covariates) that require dynamic dates

        **dynamic_variables
)
