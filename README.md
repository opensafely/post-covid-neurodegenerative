# post-covid-neurodegenerative

[View on OpenSAFELY](https://jobs.opensafely.org/repo/https%253A%252F%252Fgithub.com%252Fopensafely%252Fpost-covid-neurodegenerative/)

Details of the purpose and any published outputs from this project can be found at the link above.

The contents of this repository MUST NOT be considered an accurate or valid representation of the study or its purpose. 
This repository may reflect an incomplete or incorrect analysis with no further ongoing work.
The content has ONLY been made public to support the OpenSAFELY [open science and transparency principles](https://www.opensafely.org/about/#contributing-to-best-practice-around-open-science) and to support the sharing of re-usable code for other subsequent users.
No clinical, policy or safety conclusions must be drawn from the contents of this repository.

## Repository navigation

-   Detailed protocols are in the [`protocol`](./protocol/) folder.

    - [`post-covid-events-respiratory`](protocol/post-covid-events-respiratory.pdf) contains the outcome-specific elements necessary to implement [`post-covid-events-ehrql`](protocol/post-covid-events-ehrql.pdf).

-   If you are interested in how we defined our code lists, look in the [`codelists`](./codelists) folder.

-   Analyses scripts are in the [`analysis`](./analysis) directory:

    -   Dataset definition scripts are in the [`dataset_definition`](./analysis/dataset_definition/) directory:

        -   If you are interested in how we defined our variables, we use the variable script [`variable_helper_fuctions`](analysis/dataset_definition/variable_helper_functions.py) to define functions that generate variables. We then apply these functions in [`variables_cohorts`](analysis/variables_cohorts.py) to create a dictionary of variables for cohort definitions, and in [`variables_dates`](analysis/dataset_definition/variables_dates.py) to create a dictionary of variables for calculating study start dates and end dates.
        -   If you are interested in how we defined study dates (e.g., index and end dates), these vary by cohort and are described in the protocol. We use the script [`dataset_definition_dates`](analysis/dataset_definition/dataset_definition_dates.py) to generate a dataset with all required dates for each cohort. This script imported all variables generated from [`variables_dates`](analysis/dataset_definition/variables_dates.py).
        -   If you are interested in how we defined our cohorts, we use the dataset definition script [`dataset_definition_cohorts`](analysis/dataset_definition/dataset_definition_cohorts.py) to define a function that generates cohorts. This script imports all variables generated from [`variables_cohorts`](analysis/dataset_definition/variables_cohorts.py) using the patient's index date, the cohort start date and the cohort end date. This approach is used to generate three cohorts: pre-vaccination, vaccinated, and unvaccinated—found in [`dataset_definition_prevax`](analysis/dataset_definition/dataset_definition_prevax.py), [`dataset_definition_vax`](analysis/dataset_definition/dataset_definition_vax.py), and [`dataset_definition_unvax`](analysis/dataset_definition/dataset_definition_unvax.py), respectively. For each cohort, the extracted data is initially processed in the preprocess data script [`preprocess data script`](analysis/preprocess/preprocess_data.R), which generates a flag variable for pre-existing respiratory conditions and restricts the data to relevant variables.

    -   Dataset cleaning scripts are in the [`dataset_clean`](./analysis/dataset_clean/) directory:
        -   This directory also contains all the R scripts that process, describe, and analyse the extracted data.
        -   [`dataset_clean`](analysis/dataset_clean/dataset_clean.R) is the core script which executes all the other scripts in this folder
        -   [`fn-preprocess`](analysis/dataset_clean/fn-preprocess.R) is the function carrying out initial preprocessing, formatting columns correctly
        -   [`fn-modify_dummy`](analysis/dataset_clean/fn-modify_dummy.R) is called from within fn-preprocess.R, and alters the proportions of dummy variables to better suit analyses
        -   [`fn-inex`](analysis/dataset_clean/fn-inex.R) is the inclusion/exclusion function
        -   [`fn-qa`](analysis/dataset_clean/fn-qa.R) is the quality assurance function
        -   [`fn-ref`](analysis/dataset_clean/fn-ref.R) is the function that sets the reference levels for factors 
    
    -   Table 1 scripts are in the [`table1`](./analysis/table1/) directory:
        -   This directory contains a single script:  [`table1.R`](analysis/table1/table1.R). This script works with the output of [`dataset_clean`](./analysis/dataset_clean/) to describe the patient characteristics.

    -   Modelling scripts are in the [`model`](./analysis/model/) directory:
        -   [`make_model_input.R`](analysis/model/make_model_input.R) works with the output of [`dataset_clean`](./analysis/dataset_clean/) to prepare suitable data subsets for Cox analysis. Combines each outcome and subgroup in one formatted .rds file.
        -   [`fn-prepare_model_input.R`](analysis/model/fn-prepare_model_input.R) is a companion function to `make_model_input.R` which handles the interaction with `active_analyses.rds`.
        -   [`cox-ipw`](https://github.com/opensafely-actions/cox-ipw/) is a reusable action which uses the output of `make_model_input.R` to fit a Cox model to the data.
        -   [`make_model_output.R`](analysis/model/make_model_output.R) combines all the Cox results in one formatted .csv file.

    -   Absolute excess risk (AER) input scripts are in the [`aer`](./analysis/aer/) directory:
        - This directory contains a single script: [`make_aer_input.R`](analysis/aer/make_aer_input.R). This script generates summary statistics by age and sex required for AER estimation for each outcome (using the model input files for the main analysis generated from [`make_model_input`](analysis/model/make_model_input.R)).

-   The [`active_analyses`](lib/active_analyses.rds) contains a list of active analyses.

-   The [`project.yaml`](./project.yaml) defines run-order and dependencies for all the analysis scripts. This file should not be edited directly. To make changes to the yaml, edit and run the [`create_project_actions.R`](analysis/create_project_actions.R) script which generates all the actions.

-   Descriptive and Model outputs, including figures and tables are in the [`released_outputs`](./release_outputs) directory.
  
## Output

### aer_input-\*.csv

| Variable                     | Description                                                                    |
|------------------------------|--------------------------------------------------------------------------------|
|     aer_sex                  |      sex subgroup under consideration                                          |
|     aer_age                  |      age subgroup under consideration                                          |
|     analysis                 |      string to identify whether this is the   ‘main’ analysis or a subgroup    |
|     cohort                   |      cohort used for the analysis                                              |
|     outcome                  |      outcome used for the analysis                                             |
|     unexposed_person_days    |      unexposed person days in the age/sex   grouping                           |
|     unexposed_events         |      number of events in   unexposed people in the age/sex grouping            |
|     total_exposed            |      total number of   people with the exposure in the age/sex grouping        |
|     sample_size              |      total number of   people in the age/sex grouping                          |

## Outputs

Outputs follow OpenSAFELY naming conventions related to suppression rules by adding the suffix "_midpoint6". The suffix "_midpoint6_derived" means that the value(s) are derived from the midpoint6 values. Detailed information regarding naming conventions can be found [here](https://docs.opensafely.org/releasing-files/#naming-convention-for-midpoint-6-rounding).

### output/table1/table1_\*.csv

| Variable                          | Description                                                      |
|-----------------------------------|------------------------------------------------------------------|
|     Characteristic                | patient characteristic under consideration                       |
|     Subcharacteristic             | patient sub characteristic under consideration                   |
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

### output/make_output/model_output.csv

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

# About the OpenSAFELY framework

The OpenSAFELY framework is a Trusted Research Environment (TRE) for electronic health records research in the NHS, with a focus on public accountability and research quality.

Read more at [OpenSAFELY.org](https://opensafely.org).

# Licences
As standard, research projects have a MIT license. 
