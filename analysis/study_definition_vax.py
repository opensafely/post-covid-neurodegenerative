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
  
    study_dates
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
) = generate_common_variables(index_date_variable="index_date_vax", end_date_variable="end_date_vax")


study = StudyDefinition(

    # Read in index date for study from the output of prelim.R file 
    index_date_vax = patients.with_value_from_file(
        f_path = 'output/index_dates.csv', 
        returning = 'index_vax', 
        returning_type = 'date', 
        date_format = 'YYYY-MM-DD',     
    ),

    end_date_vax = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
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
   
    # # Define the study population 
    # # NB: not all inclusions and exclusions are written into study definition
    population = patients.satisfying(
        """
            NOT has_died
            AND
            registered        
            AND
            has_follow_up_previous_6months
            """,
        
        has_died = patients.died_from_any_cause(
        on_or_before = "index_date_vax",
        returning="binary_flag",
        ),
        
        registered = patients.satisfying(
        "registered_at_start",
        registered_at_start = patients.registered_as_of("index_date_vax"),
        ),
        
        has_follow_up_previous_6months = patients.registered_with_one_practice_between(
        start_date = "index_date_vax - 6 months",
        end_date = "index_date_vax",
        return_expectations = {"incidence": 0.95},
        ),
    ),
    
    # Define sex 
    cov_cat_sex = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'cov_cat_sex',
        returning_type = 'str',  
        ),
    # Death date
    death_date = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'death_date',
        returning_type = 'date', 

    ),
    # eligibility date
    vax_date_eligible = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'vax_date_eligible',
        returning_type = 'date',
    ),

    # Bring COVID-19 Vaccinations vars from index_dates file

    ## Any covid vaccination, identified by target disease
    vax_date_covid_1 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'vax_date_covid_1',
        returning_type = 'date'          
    ),
    vax_date_covid_2 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'vax_date_covid_2',
        returning_type = 'date'   
    ),
    vax_date_covid_3 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'vax_date_covid_3',
        returning_type = 'date'
    ),

    ## Pfizer BioNTech
    ## NB: may be patient's first COVID vaccine dose or their second if mixed types are given
        
    vax_date_Pfizer_1 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'vax_date_Pfizer_1',
        returning_type = 'date'
    ), 
    vax_date_Pfizer_2 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'vax_date_Pfizer_2',
        returning_type = 'date'
    ),
    vax_date_Pfizer_3 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'vax_date_Pfizer_3',
        returning_type = 'date'
    ),
    
    ## Oxford AZ 
    ## NB: may be patient's first COVID vaccine dose or their second if mixed types are given
    vax_date_AstraZeneca_1 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'vax_date_AstraZeneca_1',
        returning_type = 'date'
    ),
    vax_date_AstraZeneca_2 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'vax_date_AstraZeneca_2',
        returning_type = 'date'
    ),
    vax_date_AstraZeneca_3 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'vax_date_AstraZeneca_3',
        returning_type = 'date'
    ),
    
    ## Moderna
    ## NB: may be patient's first COVID vaccine dose or their second if mixed types are given
    vax_date_Moderna_1 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'vax_date_Moderna_1',
        returning_type = 'date'
    ),            
    vax_date_Moderna_2 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'vax_date_Moderna_2',
        returning_type = 'date'
    ),
    vax_date_Moderna_3 = patients.with_value_from_file(
        f_path = 'output/index_dates.csv',
        returning = 'vax_date_Moderna_3',
        returning_type = 'date'
    ),
    # Define common variables (e.g., exposures, outcomes, covariates) that require dynamic dates

        **dynamic_variables
)