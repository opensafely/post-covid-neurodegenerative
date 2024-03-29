# Neurodegenerative diseases following SARS-CoV-2 infection: Implications of COVID-19 vaccination. A cohort study of fifteen million people

This is the code and configuration for post-covid-neurodegenerative.

You can run this project via [Gitpod](https://gitpod.io) in a web browser by clicking on this badge: [![Gitpod ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-908a85?logo=gitpod)](https://gitpod.io/#https://github.com/opensafely/post-covid-neurodegenerative).

The content has ONLY been made public to support the OpenSAFELY [open science and transparency principles](https://www.opensafely.org/about/#contributing-to-best-practice-around-open-science) and to support the sharing of re-usable code for other subsequent users. No clinical, policy or safety conclusions must be drawn from the contents of this repository.

## Repository navigation

-   If you are interested in how we defined our code lists, look in the [`codelists`](./codelists) folder.

-   Analyses scripts are in the [`analysis`](./analysis) directory:

    -   If you are interested in how we defined our variables, we use study definition scripts to define three cohorts: pre-vaccination, vaccinated and unvaccinated. Study start dates (i.e., index) and end dates differ by cohort and are all described in the protocol. Hence, we have a study definition for each; these are written in `python`. Extracted data is then combined to create our final cohorts, in the [preprocess data script](analysis/preprocess/preprocess_data.R).
    -   This directory also contains all the R scripts that process, describe, and analyse the extracted data.

-   The [`lib/`](./lib) directory contains a list of active analyses.

-   The [`project.yaml`](.project.yaml) defines run-order and dependencies for all the analysis scripts. This file should not be edited directly. To make changes to the yaml, edit and run the [`create_project.R`](./analysis/create_project.R) script which generates all the actions.

## Manuscript

This manuscript is currently being drafted.

## Code

The [`project.yaml`](./project.yaml) defines project actions, run-order and dependencies for all analysis scripts. **This file should *not* be edited directly**. To make changes to the yaml, edit and run the [`create_project.R`](./analysis/create_project.R) script instead. Project actions are then run securely using [OpenSAFELY Jobs](https://jobs.opensafely.org/investigating-events-following-sars-cov-2-infection/post-covid-neurodegenerative-v2). Any published outputs from this project can be found at this link as well.

Below is a description of each action in the [`project.yaml`](./project.yaml). Arguments are denoted by {arg} in the action name.

-   `vax_eligibility_inputs`
    -   Runs [`metadates.R`](./analysis/metadates.R) which creates metadata for aspects of the study design which are required for the `generate_study_population` actions.
    -   Creates dataframes that contain dates for each phase of vaccination and conditions for defining JCVI vacciantion groups
-   `generate_study_population_{cohort}`
    -   There are three `generate_study_population` scripts that are run to create the three study populations: prevaccinated (prevax), vaccinated (vax) and electivively unvaccinated (unvax). These are [`study_definition_prevax.py`](./analysis/study_definition_prevax.py), [`study_definition_vax.py`](./analysis/study_definition_vax.py), [`study_definition_unvax.py`](./analysis/study_definition_unvax.py) and [`study_definition_prelim.py`](./analysis/study_definition_prelim.py).
    -   These scripts are used to define JCVI groups, vaccine variables, variables used to apply eligibility criteria, outcome variables and covariate variables. Common variables used in all three scripts can be found in [`common_variables.py`](./analysis/common_variables.py).
-   `preprocess data - {cohort}`
    -   Runs [`preprocess_data.R`](./analysis/preprocess/preprocess_data.R) to apply dataframe tidying to `input_{cohort}.rds` (generated by `generate_study_population_{cohort}`
    -   Tidies vaccine variables, determines patient study index date, creates addtional variables (e.g. covid phenotype), tidies dataset and ensures all variables are in the correct format e.g. numeric, character etc.
-   `stage1_data_cleaning_{cohort}`
    -   Runs [`Stage1_data_cleaning.R`](./analysis/preprocess/Stage1_data_cleaning.R)
    -   Applies quality assurance rule and inclusion/exclusion criteria
    -   Outputted dataset is analysis ready
-   `consort_{cohort}_midpoint6`    
    -   Runs [`Stage1_data_cleaning.R`](./analysis/preprocess/Stage1_data_cleaning.R)
    -   Used to elaborate consort table, using study population size after each quality assurance, inclusion and exclusion criterion is applied.
-   `table1_{cohort}`
    -   Runs [`table1.R`](./analysis/table1.R) which calculates descriptive statistics for pre- and post-exposure events for all outcomes and subgroups.
    -   Used for Table 1 in the manuscript
-   `extendedtable1_{cohort}`    
    -   Runs [`extendedtable1.R`](./analysis/extendedtable1.R) which calculates descriptive statistics for pre- and post-exposure events for all outcomes and subgroups.
    -   Used for Extended Table 1 in the manuscript
-   `table2_{cohort}`
    -   Runs [`table2.R`](./analysis/descriptives/table2.R) which calculates pre- and post-exposure event counts and person days of follow-up for all outcomes and subgroups.
    -   Used for Table 2 in the manuscript
-   `venn - {cohort}`
    -   Runs [`venn.R`](./anlaysis/descriptives/venn.R)
    -   Creates venn diagram data for all outcomes reporting where outcomes are sourced from i.e primary care, secondary care or deaths data
-   `make_model_input-{name}`
    -   Runs [`make_model_input.R`](./analysis/model/make_model_input.R) which prepares datasets for all the outcomes and subgroups.
    -   Combines each outcome and subgroup in one formatted .rds file
-   `describe_model_input-{name}`
    -   Runs [`describe_file.R`](./analysis/describe_file.R) which calculates counts, and descriptive statistics for the outcomes and covariates used in the cox models.
    -   Combines all the information in one formatted .txt file
-   `cox_ipw-{name}`
    -   Runs `cox-ipw`, a R reusable action for the OpenSAFELY framework.
    -   Detailed descriptions of each arguments/options used to fit the cox models can be found in the [`README`](https://github.com/opensafely-actions/cox-ipw/blob/main/README.md) file.
-   `make_model_output`
    -   Runs [`make_model_output.R`](./analysis/model/make_model_output.R) which combines all the R results in one formatted .csv file.

### Creating the study population

In OpenSAFELY a study definition is a formal specification of the data that you want to extract from the OpenSAFELY database. This includes:

-   the patient population (dataset rows)
-   the variables (dataset columns)
-   the expected distributions of these variables for use in dummy data

Further details on creating the study population can be found in the [`OpenSAFELY documentation`](https://docs.opensafely.org/study-def/).

The contents of this repository MUST NOT be considered an accurate or valid representation of the study or its purpose. This repository may reflect an incomplete or incorrect analysis with no further ongoing work. The content has ONLY been made public to support the OpenSAFELY [open science and transparency principles](https://www.opensafely.org/about/#contributing-to-best-practice-around-open-science) and to support the sharing of re-usable code for other subsequent users. No clinical, policy or safety conclusions must be drawn from the contents of this repository.

## Output

Outputs follow OpenSAFELY naming conventions related to suppression rules by adding the suffix "_midpoint6". The suffix "_midpoint6_derived" means that the value(s) are derived from the midpoint6 values. Detailed information regarding naming conventions can be found [here](https://docs.opensafely.org/releasing-files/#naming-convention-for-midpoint-6-rounding).

### consort_\*.csv

| Variable           | Description                                                    |
|--------------------|----------------------------------------------------------------|
|     Description    | criterion applied to cohort                                    |
|     N_midpoint6    | number of people in the cohort after criterion applied time    |
|     removed        | number of people removed due to criterion being applied        |


### table1_\*.csv

| Variable                          | Description                                                      |
|-----------------------------------|------------------------------------------------------------------|
|     Characteristic                | patient characteristic under consideration                       |
|     Subcharacteristic             | patient sub characteristic under consideration                   |
|     N (%) midpoint6 derived       | number of people with characteristic, alongside % of total       |
|     COVID-19 diagnoses midpoint6  | number of people with characteristic and COVID-19                |

### table2_\*.csv

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

### venn_\*.csv

| Variable                          | Description                                                                 |
|-----------------------------------|-----------------------------------------------------------------------------|
|     outcome                       | outcome under consideration                                                 |
|     only_snomed_midpoint6         | outcome identified in primary care only                                     |
|     only_hes_midpoint6            | outcome identified in secondary care only                                   |
|     only_death_midpoint6          | outcome identified in death registry only                                   |
|     snomed_hes_midpoint6          | outcome identified in primary and secondary care                            |
|     snomed_death_midpoint6        | outcome identified in primary care and death registry                       |
|     hes_death_midpoint6           | outcome identified in secondary care and death registry                     |
|     snomed_hes_death_midpoint6    | outcome identified in primary care, secondary care, and death registry      |
|     total_snomed_midpoint6        | total outcomes identified in primary care                                   |
|     total_hes_midpoint6           | total outcomes identified in secondary care                                 |
|     total_death_midpoint6         | total outcomes identified in death registry                                 |
|     total_midpoint6_derived       | total outcomes identified                                                   |
|     cohort                        | cohort under consideration                                                  |

### *model_output.csv

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

### aer_input_\*.csv

| Variable                        | Description                                                                    |
|---------------------------------|--------------------------------------------------------------------------------|
|     aer_sex                     |      sex subgroup under consideration                                          |
|     aer_age                     |      age subgroup under consideration                                          |
|     analysis                    |      string to identify whether this is the ‘main’ analysis or a subgroup      |
|     cohort                      |      cohort used for the analysis                                              |
|     outcome                     |      outcome used for the analysis                                             |
|     unexposed_person_days       |      unexposed person days in the age/sex grouping                             |
|     unexposed_events_midpoint6  |      number of events in   unexposed people in the age/sex grouping            |
|     total_exposed_midpoint6     |      total number of people with the exposure in the age/sex grouping          |
|     sample_size_midpoint6       |      total number of people in the age/sex grouping                            |

## About the OpenSAFELY framework

The OpenSAFELY framework is a Trusted Research Environment (TRE) for electronic health records research in the NHS, with a focus on public accountability and research quality. Read more at [OpenSAFELY.org](https://opensafely.org).

## Licences

As standard, research projects have a MIT license.
