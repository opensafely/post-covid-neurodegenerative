# post-covid-neurodegenerative

[View on OpenSAFELY](https://jobs.opensafely.org/repo/https%253A%252F%252Fgithub.com%252Fopensafely%252Fpost-covid-neurodegenerative/)

Details of the purpose and any published outputs from this project can be found at the link above.

The contents of this repository MUST NOT be considered an accurate or valid representation of the study or its purpose. 
This repository may reflect an incomplete or incorrect analysis with no further ongoing work.
The content has ONLY been made public to support the OpenSAFELY [open science and transparency principles](https://www.opensafely.org/about/#contributing-to-best-practice-around-open-science) and to support the sharing of re-usable code for other subsequent users.
No clinical, policy or safety conclusions must be drawn from the contents of this repository.

## Repository navigation

-   Detailed protocols are in the [`protocol`](./protocol/) folder:

    - [`post-covid-events-neurodegenerative`](protocol/post-covid-events-neurodegenerative.pdf) contains the outcome-specific elements necessary to implement [`post-covid-events-ehrql`](protocol/post-covid-events-ehrql.pdf)

-   If you are interested in how we defined our code lists, look at [`codelists/codelists.txt`](./codelists/codelists.txt) for the full list, or any of the *.csv files in the [`codelists`](./codelists) folder

-   The following scripts are in the [`analysis`](./analysis) directory:

    -   [`utility.R`](./analysis/utility.R) contains some generic functions which are used throughout the pipeline e.g. a rounding function, a display function, a type conversion function
    -   [`study_dates.R`](./analysis/study_dates.R) creates [`output/study_dates.json`](./output/study_dates.json) which stores the date-specific metadata (e.g. the start dates of the phases of the study, vaccine dates)

    -   Dataset definition scripts are in the [`dataset_definition`](./analysis/dataset_definition/) directory:
        -   [`variable_helper_functions.R`](./analysis/dataset_definition/variable_helper_functions.py) defines ehrQL functions that generate variables
        -   [`codelists.py`](./analysis/dataset_definition/codelists.py) creates codelist variables that can be accessed by [`variables_cohorts.R`](./analysis/variables_cohorts.py)
        -   [`variables_cohorts.R`](./analysis/dataset_definition/variables_cohorts.py) uses the helper functions to create a dictionary of variables for cohort definitions
        -   [`variables_dates.R`](./analysis/dataset_definition/variables_dates.py) creates a dictionary of variables for calculating study start dates and end dates
        -   [`dataset_definition_dates.R`](./analysis/dataset_definition/dataset_definition_dates.py) generates a dataset with all required dates for each cohort (e.g., index and end dates), which are further described in the protocol. This script imports all variables generated from [`variables_dates`](./analysis/dataset_definition/variables_dates.py).
        -   [`dataset_definition_cohorts.R`](./analysis/dataset_definition/dataset_definition_cohorts.py) defines a function that generates cohorts. This script imports all variables generated from [`variables_cohorts.R`](./analysis/dataset_definition/variables_cohorts.py) using the patient's index date, the cohort start date and the cohort end date. 
        -   [`dataset_definition_prevax.R`](./analysis/dataset_definition/dataset_definition_prevax.py), [`dataset_definition_vax.R`](./analysis/dataset_definition/dataset_definition_vax.py), and [`dataset_definition_unvax.R`](./analysis/dataset_definition/dataset_definition_unvax.py) use [`dataset_definition_cohorts`](./analysis/dataset_definition/dataset_definition_cohorts.py) to generate the pre-vaccination, vaccinated, and unvaccinated cohorts respectively 

    -   Dataset cleaning scripts are in the [`dataset_clean`](./analysis/dataset_clean/) directory:
        -   This directory also contains all the R scripts that process, describe, and analyse the extracted data.
        -   [`dataset_clean.R`](./analysis/dataset_clean/dataset_clean.R) is the core script which executes all the other scripts in this folder
        -   [`fn-preprocess.R`](./analysis/dataset_clean/fn-preprocess.R) is the function carrying out initial preprocessing, formatting columns correctly
        -   [`fn-modify_dummy.R`](./analysis/dataset_clean/fn-modify_dummy.R) is called from within fn-preprocess.R, and alters the proportions of dummy variables to better suit analyses
        -   [`fn-inex.R`](./analysis/dataset_clean/fn-inex.R) is the inclusion/exclusion function
        -   [`fn-qa.R`](./analysis/dataset_clean/fn-qa.R) is the quality assurance function
        -   [`fn-ref.R`](./analysis/dataset_clean/fn-ref.R) is the function that sets the reference levels for factors 
    
    -   Table 1 scripts are in the [`table1`](./analysis/table1/) directory:
        -   This directory contains a single script:  [`table1.R`](./analysis/table1/table1.R). This script works with the output of [`dataset_clean`](./analysis/dataset_clean/) to describe the patient characteristics, displaying the proportion of study population in each variable category

    -   Modelling scripts are in the [`model`](./analysis/model/) directory:
        -   [`make_model_input.R`](./analysis/model/make_model_input.R) works with the output of [`dataset_clean`](./analysis/dataset_clean/) to prepare suitable data subsets for Cox analysis. Combines each outcome and subgroup in one formatted .rds file
        -   [`fn-prepare_model_input.R`](./analysis/model/fn-prepare_model_input.R) is a companion function to [`make_model_input.R`](./analysis/model/make_model_input.R) which handles the interaction with [`active_analyses.rds`](lib/active_analyses.rds)
        -   [`fn-check_vitals.R`](./analysis/model/fn-check_vitals.R) is a companion function that checks the input dataset for [`make_model_input.R`](./analysis/model/make_model_input.R) is formatted correctly
        -   [`cox-ipw`](https://github.com/opensafely-actions/cox-ipw/) is a reusable action which uses the output of [`make_model_input.R`](./analysis/model/make_model_input.R) to fit a Cox model to the data. (NB: It is not a file in the server)
        -   [`cox_model.do`](./analysis/model/cox_model.do) is a Stata script used to rerun Cox models in Stata when they fail to converge in R (i.e.,  [`cox-ipw`](https://github.com/opensafely-actions/cox-ipw/)), specified by the user in [`create_project_actions.R`](./analysis/create_project_actions.R)

    -   Extra files that suppport the Cox regression command in Stata for [`cox_model.do`](./analysis/model/cox_model.do) are in the [`extra_ados`](./analysis/extra_ados/) directory
    
    -   Table 2 scripts are in the [`table2`](./analysis/table2/) directory:
        -   This directory contains a single script:  [`table2.R`](./analysis/table2/table2.R). This script works with the output of [`dataset_clean`](./analysis/dataset_clean/) to calculate pre- and post-exposure event counts and person days of follow-up for all outcomes and subgroups
    
    -   Venn scripts are in the [`venn`](./analysis/venn/) directory:
        -   This directory contains a single script:  [`venn.R`](./analysis/venn/venn.R). This script works with the output of [`dataset_clean`](./analysis/dataset_clean/) to create venn diagram data for all outcomes reporting where outcomes are sourced from i.e. primary care, secondary care or deaths data

    -   Output scripts are in the [`make_output`](./analysis/make_output/) directory:
        -   [`make_model_output.R`](./analysis/make_output/make_model_output.R) combines all the Cox results in one formatted .csv file per subgroup
        -   [`make_other_output.R`](./analysis/model/make_other_output.R) combines cohort-specific outputs (e.g. the table1 outputs) into 1 .csv file
        -   [`make_aer_input.R`](./analysis/make_output/make_aer_input.R) generates summary statistics by age and sex required for AER (Absolute Excess Risk) estimation for each outcome (using the model input files for the main analysis generated from [`make_model_input`](analysis/model/make_model_input.R))

    These scripts are in the [`analysis`](./analysis) directory, but are not accessed when the repository is run on a job server
        
    -   [`create_project_actions.R`](./analysis/create_project_actions.R) is the function which creates the [`project.yaml`](./project.yaml), the list of actions which can be run in OpenSAFELY (NB: this is not accessed during the core pipeline run)

    -   Active analyses scripts are in the [`active_analyses`](./analysis/active_analyses/) directory (NB: these are not accessed during the core pipeline run):
        -   [`active_analyses.R`](./analysis/active_analyses/active_analyses.R) creates [`lib/active_analyses`](./lib/active_analyses.rds), the list of analyses to be run
        -   [`fn-add_analysis.R`](./analysis/active_analyses/fn-add_analysis.R) a companion function to [`active_analyses.R`](./analysis/active_analyses/active_analyses.R) to cleanly add new rows to the analyses file

        
-   Other useful files include the following:        

    -   The [`lib/active_analyses.rds`](lib/active_analyses.rds) contains a list of active analyses. To edit this file, alter either [`active_analyses.R`](./analysis/active_analyses/active_analyses.R) or [`fn-add_analysis.R`](./analysis/active_analyses/fn-add_analysis.R)

    -   The [`project.yaml`](./project.yaml) defines run-order and dependencies for all the analysis scripts. This file should not be edited directly. To make changes to the yaml, edit and run the [`create_project_actions.R`](analysis/create_project_actions.R) script which generates all the actions

-   Combined model and descriptive outputs, including figures and tables are in the [`output/make_output`](./output/make_output) directory (which will be created once the pipeline runs)

## Running the pipeline after alterations

When running, you should first check if [`active_analyses`](lib/active_analyses.rds) exists (and is up to date)

  - If not, create [`output/study_dates.json`](./output/study_dates.json) by running the `study_dates` action (e.g. with `opensafely run study_dates`)

  - Then, run [`active_analyses.R`](./analysis/active_analyses/active_analyses.R) locally to create/update [`active_analyses`](lib/active_analyses.rds)

If necessary, run [`create_project_actions.R`](./analysis/create_project_actions.R) to recreate the [`project.yaml`](./project.yaml)

Afterwards, proceed to run the scripts as normal (on the OpenSAFELY server, or locally with `opensafely run run_all -f` using dummy data)

## Outcomes

11 outcomes are investigated, using the following shorthand in the code:
  -  dem_alz - Alzheimer's Disease
  -  dem_vasc - Vascular Dementia
  -  dem_lb - Lewy Body Dementia
  -  dem_any - Any Dementia
  -  cis - Cognitive Impairment Symptoms
  -  park - Parkinson's Disease
  -  rls - Restless Leg Syndrome
  -  rsd - REM Sleep Disorder
  -  mnd - Motor Neurone Disease
  -  ms - Multiple Sclerosis
  -  migraine - Migraine (no shorthand)

Detailed information about the outcomes can be found in the [`project-specific protocol`](protocol/post-covid-events-neurodegenerative.pdf).

## Outputs

Outputs follow OpenSAFELY naming conventions related to suppression rules by adding the suffix "_midpoint6". Detailed information regarding naming conventions can be found [here](https://docs.opensafely.org/releasing-files/#naming-convention-for-midpoint-6-rounding).

### output/table1/table1_\*.csv

| Variable                            | Description                                                      |
|-------------------------------------|------------------------------------------------------------------|
|     Characteristic                  | patient characteristic under consideration                       |
|     Subcharacteristic               | patient sub characteristic under consideration                   |
|     N \[midpoint6 derived\]         | number of people with characteristic                             |
|     (%) \[midpoint6 derived\]       | % of total people with characteristic                            |
|     COVID-19 \[diagnoses midpoint6\]| number of people with characteristic and COVID-19                |

### output/table2/table2_\*.csv

| Variable                             | Description                                                             |
|--------------------------------------|-------------------------------------------------------------------------|
|     name                             | unique identifier for analysis                                          |
|     cohort                           | cohort used for the analysis                                            |
|     exposure                         | exposure used for the analysis                                          |
|     outcome                          | outcome used for the analysis                                           |
|     analysis                         | string to identify whether this is the ‘main’ analysis or a subgroup    |
|     unexposed_person_days            | number of person days before or without exposure in the analysis        |
|     unexposed_events_midpoint6       | number of unexposed people with the outcome in the analysis             |   
|     exposed_person_days              | number of person days after exposure in the analysis                    |
|     exposed_events_midpoint6         | number of exposed people with the outcome in the analysis               |  
|     total_person_days                | number of person days in the analysis                                   |
|     total_events_midpoint6_derived   | number of people with the outcome in the analysis                       |
|     day0_events_midpoint6            | number of people with the exposure and outcome on the same day          |
|     total_exposed_midpoint6          | number of people with the exposure in the analysis                      |
|     sample_size_midpoint6            | number of people in the analysis                                        |

### output/make_output/model_output-*.csv

| Variable                   | Description                                                                   |
|----------------------------|-------------------------------------------------------------------------------|
|     name                   | unique identifier for analysis                                                |
|     cohort                 | cohort used for the analysis                                                  |
|     outcome                | outcome used for the analysis                                                 |
|     analysis               | string to identify whether this is the ‘main’ analysis or a subgroup          |
|     error                  | captured error message if analysis did not run                                |
|     model                  | string to identify whether the model adjustment                               |
|     term                   | string to identify the term in the analysis                                   |
|     lnhr                   | log hazard ratio for the analysis                                             |
|     se_lnhr                | standard error for the log hazard ratio for the analysis                      |
|     hr                     | hazard ratio for the analysis                                                 |
|     conf_low               | lower confidence limit for the analysis                                       |
|     conf_high              | higher confidence limit for the analysis                                      |
|     N_total_midpoint6      | total number of people in the analysis                                        |
|     N_exposed_midpoint6    | total number of people with the exposure in the analysis                      |
|     N_events_midpoint6     | total number of people with the outcome following exposure in the analysis    |
|     person_time_total      | total person time included in the analysis                                    |
|     outcome_time_median    | median time to outcome following exposure                                     |
|     strata_warning         | string to identify strata variables that may cause model faults               |
|     surv_formula           | survival formula for the analysis                                             |
|     source                 | language used for cox calculation                                             |

### output/make_output/table1|table2|venn\*_output_midpoint6.csv

These outputs will have similar outputs to the table1|table2|venn outputs, but combined across cohorts.
They may contain additional columns indicating the cohort and subgroup of the analysis. 

### output/make_output/flow_output_midpoint6.csv

A concatenation of the flow descriptors generated by [`fn-inex`](./analysis/dataset_clean/fn-inex.R) and [`fn-qa`](./analysis/dataset_clean/fn-qa.R), the inclusion/exclusion function and the quality assurance function.

| Variable                   | Description                                                                   |
|----------------------------|-------------------------------------------------------------------------------|
|     Description            | the inclusion/exclusion/quality criteria applied (Input: start of new cohort) |
|     N_midpoint6            | the total number of people remaining in the dataset                           |
|     removed_derived        | the total number of people removed from this criteria                         |
|     flow                   | an incremental counter of criteria applied so far in this dataset             |
|     cohort                 | cohort used for the analysis                                                  |

### output/make_output/aer_input-\*.csv

| Variable                     | Description                                                                    |
|------------------------------|--------------------------------------------------------------------------------|
|     aer_sex                  |      sex subgroup under consideration                                          |
|     aer_age                  |      age subgroup under consideration                                          |
|     analysis                 |      string to identify whether this is the ‘main’ analysis or a subgroup      |
|     cohort                   |      cohort used for the analysis                                              |
|     outcome                  |      outcome used for the analysis                                             |
|     unexposed_person_days    |      unexposed person days in the age/sex   grouping                           |
|     unexposed_events         |      number of events in   unexposed people in the age/sex grouping            |
|     total_exposed            |      total number of   people with the exposure in the age/sex grouping        |
|     sample_size              |      total number of   people in the age/sex grouping                          |

# About the OpenSAFELY framework

The OpenSAFELY framework is a Trusted Research Environment (TRE) for electronic health records research in the NHS, with a focus on public accountability and research quality.

Read more at [OpenSAFELY.org](https://opensafely.org).

# Licences
As standard, research projects have a MIT license. 
