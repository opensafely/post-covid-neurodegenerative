library(tidyverse)
library(yaml)
library(here)
library(glue)
library(readr)
library(dplyr)


###########################
# Load information to use #
###########################

## defaults ----
defaults_list <- list(
  version = "3.0",
  expectations= list(population_size=350000L)
)

active_analyses <- read_rds("lib/active_analyses.rds")
active_analyses <- active_analyses[order(active_analyses$analysis,active_analyses$cohort,active_analyses$outcome),]
cohorts <- unique(active_analyses$cohort)
#names <- unique(active_analyses$names)

# Test Stata locally
#run_stata <- c("cohort_prevax-main-vascular_dementia")

run_stata <- c(
  "cohort_prevax-main-alzheimer_disease",
  "cohort_prevax-main-any_dementia",#
  "cohort_prevax-main-motor_neurone_disease",
  "cohort_prevax-main-multiple_sclerosis",
  "cohort_prevax-main-parkinson_disease",#
  "cohort_prevax-main-rem_sleep_disorder",#
  "cohort_prevax-main-vascular_dementia",#
  "cohort_prevax-sub_age_18_39-rem_sleep_disorder",
  "cohort_prevax-sub_age_40_64-any_dementia",
  "cohort_prevax-sub_age_40_64-rem_sleep_disorder",
  "cohort_prevax-sub_age_40_64-vascular_dementia",
  "cohort_prevax-sub_age_65_84-alzheimer_disease",
  "cohort_prevax-sub_age_65_84-any_dementia",
  "cohort_prevax-sub_age_65_84-cognitive_impairment_symptoms",
  "cohort_prevax-sub_age_65_84-parkinson_disease",
  "cohort_prevax-sub_age_65_84-rem_sleep_disorder",
  "cohort_prevax-sub_age_65_84-vascular_dementia",
  "cohort_prevax-sub_age_85_110-alzheimer_disease",
  "cohort_prevax-sub_age_85_110-any_dementia",
  "cohort_prevax-sub_age_85_110-cognitive_impairment_symptoms",
  "cohort_prevax-sub_age_85_110-parkinson_disease",
  "cohort_prevax-sub_age_85_110-rem_sleep_disorder",
  "cohort_prevax-sub_age_85_110-vascular_dementia",
  "cohort_prevax-sub_bin_high_vascular_risk_false-alzheimer_disease",
  "cohort_prevax-sub_bin_high_vascular_risk_false-any_dementia",
  "cohort_prevax-sub_bin_high_vascular_risk_false-vascular_dementia",
  "cohort_prevax-sub_bin_high_vascular_risk_true-alzheimer_disease",
  "cohort_prevax-sub_bin_high_vascular_risk_true-any_dementia",
  "cohort_prevax-sub_bin_high_vascular_risk_true-vascular_dementia",
  "cohort_prevax-sub_covid_hospitalised-alzheimer_disease",
  "cohort_prevax-sub_covid_hospitalised-cognitive_impairment_symptoms",
  "cohort_prevax-sub_covid_hospitalised-migraine",
  "cohort_prevax-sub_covid_hospitalised-vascular_dementia",#
  "cohort_prevax-sub_covid_hospitalised-rem_sleep_disorder",#
  "cohort_prevax-sub_covid_hospitalised-any_dementia",#
  "cohort_prevax-sub_covid_hospitalised-multiple_sclerosis",#
  "cohort_prevax-sub_covid_hospitalised-parkinson_disease",#
  "cohort_prevax-sub_covid_nonhospitalised-alzheimer_disease",
  "cohort_prevax-sub_covid_nonhospitalised-any_dementia",
  "cohort_prevax-sub_covid_nonhospitalised-motor_neurone_disease",
  "cohort_prevax-sub_covid_nonhospitalised-parkinson_disease",
  "cohort_prevax-sub_covid_nonhospitalised-rem_sleep_disorder",
  "cohort_prevax-sub_covid_nonhospitalised-vascular_dementia",
  "cohort_prevax-sub_ethnicity_asian-alzheimer_disease",
  "cohort_prevax-sub_ethnicity_asian-any_dementia",
  "cohort_prevax-sub_ethnicity_asian-cognitive_impairment_symptoms",
  "cohort_prevax-sub_ethnicity_asian-rem_sleep_disorder",
  "cohort_prevax-sub_ethnicity_black-any_dementia",
  "cohort_prevax-sub_ethnicity_black-cognitive_impairment_symptoms",
  "cohort_prevax-sub_ethnicity_black-rem_sleep_disorder",
  "cohort_prevax-sub_ethnicity_other-cognitive_impairment_symptoms",
  "cohort_prevax-sub_ethnicity_other-rem_sleep_disorder",
  "cohort_prevax-sub_ethnicity_white-alzheimer_disease",
  "cohort_prevax-sub_ethnicity_white-any_dementia",
  "cohort_prevax-sub_ethnicity_white-motor_neurone_disease",
  "cohort_prevax-sub_ethnicity_white-multiple_sclerosis",
  "cohort_prevax-sub_ethnicity_white-parkinson_disease",
  "cohort_prevax-sub_ethnicity_white-rem_sleep_disorder",
  "cohort_prevax-sub_ethnicity_white-vascular_dementia",
  "cohort_prevax-sub_history_parkinson_false-any_dementia",
  "cohort_prevax-sub_history_parkinson_true-any_dementia",
  "cohort_prevax-sub_sex_female-alzheimer_disease",
  "cohort_prevax-sub_sex_female-any_dementia",
  "cohort_prevax-sub_sex_female-multiple_sclerosis",
  "cohort_prevax-sub_sex_female-parkinson_disease",
  "cohort_prevax-sub_sex_female-rem_sleep_disorder",
  "cohort_prevax-sub_sex_female-vascular_dementia",
  "cohort_prevax-sub_sex_male-alzheimer_disease",
  "cohort_prevax-sub_sex_male-any_dementia",
  "cohort_prevax-sub_sex_male-cognitive_impairment_symptoms",
  "cohort_prevax-sub_sex_male-multiple_sclerosis",
  "cohort_prevax-sub_sex_male-parkinson_disease",
  "cohort_prevax-sub_sex_male-rem_sleep_disorder",
  "cohort_prevax-sub_sex_male-vascular_dementia",
  "cohort_unvax-main-any_dementia",#
  "cohort_unvax-main-rem_sleep_disorder",#
  "cohort_unvax-sub_age_18_39-rem_sleep_disorder",
  "cohort_unvax-sub_age_40_64-rem_sleep_disorder",
  "cohort_unvax-sub_bin_high_vascular_risk_true-any_dementia",
  "cohort_unvax-sub_covid_hospitalised-cognitive_impairment_symptoms",
  "cohort_unvax-sub_covid_hospitalised-rem_sleep_disorder",#
  "cohort_unvax-sub_covid_hospitalised-any_dementia",#
  "cohort_unvax-sub_covid_nonhospitalised-rem_sleep_disorder",
  "cohort_unvax-sub_ethnicity_white-any_dementia",
  "cohort_unvax-sub_ethnicity_white-rem_sleep_disorder",
  "cohort_unvax-sub_history_parkinson_false-any_dementia",
  "cohort_unvax-sub_sex_female-any_dementia",
  "cohort_unvax-sub_sex_female-rem_sleep_disorder",
  "cohort_unvax-sub_sex_male-rem_sleep_disorder",
  "cohort_vax-main-any_dementia",#
  "cohort_vax-main-vascular_dementia",#
  "cohort_vax-main-rem_sleep_disorder",#
  "cohort_vax-sub_age_65_84-rem_sleep_disorder",                   
  "cohort_vax-sub_age_65_84-vascular_dementia",
  "cohort_vax-sub_age_85_110-any_dementia",
  "cohort_vax-sub_age_85_110-vascular_dementia",
  "cohort_vax-sub_bin_high_vascular_risk_true-vascular_dementia",
  "cohort_vax-sub_covid_hospitalised-alzheimer_disease",
  "cohort_vax-sub_covid_hospitalised-any_dementia",
  "cohort_vax-sub_covid_hospitalised-vascular_dementia",#
  "cohort_vax-sub_covid_hospitalised-rem_sleep_disorder",#
  "cohort_vax-sub_covid_nonhospitalised-vascular_dementia",
  "cohort_vax-sub_ethnicity_asian-rem_sleep_disorder",
  "cohort_vax-sub_ethnicity_white-vascular_dementia",
  "cohort_vax-sub_sex_male-any_dementia",
  "cohort_vax-sub_sex_male-vascular_dementia")

stata <- active_analyses[active_analyses$name %in% run_stata,]
stata$save_analysis_ready <- TRUE
stata$day0 <- grepl("1;",stata$cut_points)

#active_analyses <- active_analyses[!active_analyses$name %in% run_stata,]

# Determine which outputs are ready --------------------------------------------

# success <- readxl::read_excel("../../OneDrive - University of Bristol/Projects/post-covid-outcome-tracker.xlsx",
#                               sheet = "neuro_extf",
#                       col_types = c("text","text", "text", "text", "text", "text",
#                                     "text", "text", "text", "text", "text",
#                                     "text", "text", "text", "text", "text", "text",
#                                     "skip", "skip"))
# 
# success <- tidyr::pivot_longer(success,
#                                cols = setdiff(colnames(success),c("outcome","cohort")),
#                                names_to = "analysis")
# 
# success$name <- paste0("cohort_",success$cohort, "-",success$analysis, "-",success$outcome)
# 
# success <- success[grepl("success",success$value, ignore.case = TRUE),]

# create action functions ----

############################
## generic action function #
############################
action <- function(
    name,
    run,
    dummy_data_file=NULL,
    arguments=NULL,
    needs=NULL,
    highly_sensitive=NULL,
    moderately_sensitive=NULL
){
  
  outputs <- list(
    moderately_sensitive = moderately_sensitive,
    highly_sensitive = highly_sensitive
  )
  outputs[sapply(outputs, is.null)] <- NULL
  
  action <- list(
    run = paste(c(run, arguments), collapse=" "),
    dummy_data_file = dummy_data_file,
    needs = needs,
    outputs = outputs
  )
  action[sapply(action, is.null)] <- NULL
  
  action_list <- list(name = action)
  names(action_list) <- name
  
  action_list
}


## create comment function ----
comment <- function(...){
  list_comments <- list(...)
  comments <- map(list_comments, ~paste0("## ", ., " ##"))
  comments
}


## create function to convert comment "actions" in a yaml string into proper comments
convert_comment_actions <-function(yaml.txt){
  yaml.txt %>%
    str_replace_all("\\\n(\\s*)\\'\\'\\:(\\s*)\\'", "\n\\1")  %>%
    #str_replace_all("\\\n(\\s*)\\'", "\n\\1") %>%
    str_replace_all("([^\\'])\\\n(\\s*)\\#\\#", "\\1\n\n\\2\\#\\#") %>%
    str_replace_all("\\#\\#\\'\\\n", "\n")
}

################################################################################
# Create function to generate study population ---------------------------------
################################################################################

generate_study_population <- function(cohort){
  splice(
    comment(glue("Generate study population - {cohort}")),
    action(
      name = glue("generate_study_population_{cohort}"),
      run = glue("cohortextractor:latest generate_cohort --study-definition study_definition_{cohort} --output-format csv.gz"),
      needs = list("vax_eligibility_inputs","generate_index_dates"),
      highly_sensitive = list(
        cohort = glue("output/input_{cohort}.csv.gz")
      )
    )
  )
}

################################################################################
# Create function to preprocess data -------------------------------------------
################################################################################

preprocess_data <- function(cohort){
  splice(
    comment(glue("Preprocess data - {cohort}")),
    action(
      name = glue("preprocess_data_{cohort}"),
      run = glue("r:latest analysis/preprocess/preprocess_data.R"),
      arguments = c(cohort),
      needs = list("generate_index_dates",glue("generate_study_population_{cohort}")),
      moderately_sensitive = list(
        describe = glue("output/not-for-review/describe_input_{cohort}_stage0.txt"),
        describe_venn = glue("output/not-for-review/describe_venn_{cohort}.txt")
      ),
      highly_sensitive = list(
        cohort = glue("output/input_{cohort}.rds"),
        venn = glue("output/venn_{cohort}.rds")
      )
    )
  )
}

################################################################################
# Create function for data cleaning --------------------------------------------
################################################################################

stage1_data_cleaning <- function(cohort){
  splice(
    comment(glue("Stage 1 - data cleaning - {cohort}")),
    action(
      name = glue("stage1_data_cleaning_{cohort}"),
      run = glue("r:latest analysis/preprocess/Stage1_data_cleaning.R"),
      arguments = c(cohort),
      needs = list("vax_eligibility_inputs",glue("preprocess_data_{cohort}")),
      moderately_sensitive = list(
        consort = glue("output/consort_{cohort}.csv"),
        consort_midpoint6 = glue("output/consort_{cohort}_midpoint6.csv")
      ),
      highly_sensitive = list(
        cohort = glue("output/input_{cohort}_stage1.rds")
      )
    ),
    action(
      name = glue("describe_stage1_data_cleaning_{cohort}"),
      run = glue("r:latest analysis/model/describe_file.R input_{cohort}_stage1 rds"),
      needs = list(glue("stage1_data_cleaning_{cohort}")),
      moderately_sensitive = list(
        describe_model_input = glue("output/describe-input_{cohort}_stage1.txt")
      )
    )
  )
}

# Create function for table1 --------------------------------------------

table1 <- function(cohort){
  splice(
    comment(glue("Table 1 - {cohort}")),
    action(
      name = glue("table1_{cohort}"),
      run = "r:latest analysis/descriptives/table1.R",
      arguments = c(cohort),
      needs = list(glue("stage1_data_cleaning_{cohort}")),
      moderately_sensitive = list(
        table1 = glue("output/table1_{cohort}.csv"),
        table1_midpoint6 = glue("output/table1_{cohort}_midpoint6.csv")
      )
    )
  )
}

# #################################################
# ## Function for typical actions to analyse data #
# #################################################

# Updated to a typical action running Cox models for one outcome
apply_model_function <- function(name, cohort, analysis, ipw, strata,
                                 covariate_sex, covariate_age, covariate_other,
                                 cox_start, cox_stop, study_start, study_stop,
                                 cut_points, controls_per_case,
                                 total_event_threshold, episode_event_threshold,
                                 covariate_threshold, age_spline){

  splice(
    action(
      name = glue("make_model_input-{name}"),
      run = glue("r:latest analysis/model/make_model_input.R {name}"),
      needs = list("stage1_data_cleaning_prevax", "stage1_data_cleaning_vax", "stage1_data_cleaning_unvax"),
      highly_sensitive = list(
        model_input = glue("output/model_input-{name}.rds")
      )
    ),

    action(
      name = glue("describe_model_input-{name}"),
      run = glue("r:latest analysis/model/describe_file.R model_input-{name} rds"),
      needs = list(glue("make_model_input-{name}")),
      moderately_sensitive = list(
        describe_model_input = glue("output/describe-model_input-{name}.txt")
      )
    ),

    #comment(glue("Cox model for {outcome} - {cohort}")),
    action(
      name = glue("cox_ipw-{name}"),
      run = glue("cox-ipw:v0.0.31 --df_input=model_input-{name}.rds --ipw={ipw} --exposure=exp_date --outcome=out_date --strata={strata} --covariate_sex={covariate_sex} --covariate_age={covariate_age} --covariate_other={covariate_other} --cox_start={cox_start} --cox_stop={cox_stop} --study_start={study_start} --study_stop={study_stop} --cut_points={cut_points} --controls_per_case={controls_per_case} --total_event_threshold={total_event_threshold} --episode_event_threshold={episode_event_threshold} --covariate_threshold={covariate_threshold} --age_spline={age_spline} --df_output=model_output-{name}.csv"),
      needs = list(glue("make_model_input-{name}")),
      moderately_sensitive = list(
        model_output = glue("output/model_output-{name}.csv"))
    )
  )
}

################################################################################
# Save analyses ready for running stata and run stata --------------------------
################################################################################

apply_stata_model_function <- function(name, cohort, analysis, ipw, strata, 
                                       covariate_sex, covariate_age, covariate_other, 
                                       cox_start, cox_stop, study_start, study_stop,
                                       cut_points, controls_per_case,
                                       total_event_threshold, episode_event_threshold,
                                       covariate_threshold, age_spline, day0){
  splice(
    action(
      name = glue("ready-{name}"),
      run = glue("cox-ipw:v0.0.30 --df_input=model_input-{name}.rds --ipw={ipw} --exposure=exp_date --outcome=out_date --strata={strata} --covariate_sex={covariate_sex} --covariate_age={covariate_age} --covariate_other={covariate_other} --cox_start={cox_start} --cox_stop={cox_stop} --study_start={study_start} --study_stop={study_stop} --cut_points={cut_points} --controls_per_case={controls_per_case} --total_event_threshold={total_event_threshold} --episode_event_threshold={episode_event_threshold} --covariate_threshold={covariate_threshold} --age_spline={age_spline} --save_analysis_ready=TRUE --run_analysis=FALSE --df_output=model_output-{name}.csv"),
      needs = list(glue("make_model_input-{name}")),
      highly_sensitive = list(
        analysis_ready = glue("output/ready-{name}.csv.gz"))
    ),
    action(
      name = glue("stata_cox_ipw-{name}"),
      run = glue("stata-mp:latest analysis/stata/cox_model.do"),
      arguments = c(name, day0),
      needs = list(glue("ready-{name}")),
      moderately_sensitive = list(
        medianfup = glue("output/ready-{name}_median_fup.csv"),
        stata_output = glue("output/ready-{name}_cox_model.txt")
      )
    )
  )
}

################################################################################
# Create function to make Table 2 ----------------------------------------------
################################################################################

table2 <- function(cohort){
  
  table2_names <- gsub("out_date_","",unique(active_analyses[active_analyses$cohort=={cohort},]$name))
  
  splice(
    comment(glue("Table 2 - {cohort}")),
    action(
      name = glue("table2_{cohort}"),
      run = "r:latest analysis/descriptives/table2.R",
      arguments = c(cohort),
      needs = c(as.list(paste0("make_model_input-",table2_names))),
      moderately_sensitive = list(
        table2 = glue("output/table2_{cohort}.csv"),
        table2_midpoint6 = glue("output/table2_{cohort}_midpoint6.csv")
      )
    )
  )
}

################################################################################
# Create function to make Venn data --------------------------------------------
################################################################################

venn <- function(cohort){
  
  venn_outcomes <- gsub("out_date_","",unique(active_analyses[active_analyses$cohort=={cohort},]$outcome))
  
  splice(
    comment(glue("Venn - {cohort}")),
    action(
      name = glue("venn_{cohort}"),
      run = "r:latest analysis/descriptives/venn.R",
      arguments = c(cohort),
      needs = c(as.list(glue("preprocess_data_{cohort}")),
                as.list(paste0(glue("make_model_input-cohort_{cohort}-main-"),venn_outcomes))),
      moderately_sensitive = list(
        table2 = glue("output/venn_{cohort}.csv"),
        table2_midpoint6 = glue("output/venn_{cohort}_midpoint6.csv")
      )
    )
  )
}

##########################################################
## Define and combine all actions into a list of actions #
##########################################################

actions_list <- splice(
  
  ## Post YAML disclaimer ------------------------------------------------------
  
  comment("# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #",
          "DO NOT EDIT project.yaml DIRECTLY",
          "This file is created by create_project_actions.R",
          "Edit and run create_project_actions.R to update the project.yaml",
          "# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #"
  ),
  
  #comment("Generate vaccination eligibility information"),
  action(
    name = glue("vax_eligibility_inputs"),
    run = "r:latest analysis/metadates.R",
    highly_sensitive = list(
      study_dates_json = glue("output/study_dates.json"),
      vax_jcvi_groups= glue("output/vax_jcvi_groups.csv.gz"),
      vax_eligible_dates= ("output/vax_eligible_dates.csv.gz")
    )
  ),
  
  #comment("Generate prelim study_definition),
  action(
    name = "generate_study_population_prelim",
    run = "cohortextractor:latest generate_cohort --study-definition study_definition_prelim --output-format csv.gz",
    needs = list("vax_eligibility_inputs"),
    highly_sensitive = list(
      cohort = glue("output/input_prelim.csv.gz")
    )
  ),
  
  ## Generate dates for all study cohorts --------------------------------------
  
  #comment("Generate dates for all study cohorts"), 
  action(
    name = "generate_index_dates",
    run = "r:latest analysis/prelim.R",
    needs = list("vax_eligibility_inputs","generate_study_population_prelim"),
    highly_sensitive = list(
      index_dates = glue("output/index_dates.csv.gz")
    )
  ),
  
  ## Generate study population -------------------------------------------------
  
  splice(
    unlist(lapply(cohorts, 
                  function(x) generate_study_population(cohort = x)), 
           recursive = FALSE
    )
  ),
  
  ## Preprocess data -----------------------------------------------------------
  
  splice(
    unlist(lapply(cohorts, 
                  function(x) preprocess_data(cohort = x)), 
           recursive = FALSE
    )
  ),
  
  #Count outcomes and binary covars
  action(
    name = "count_study_def_variables",
    run = "r:latest analysis/descriptives/intitial_input_counts.R",
    needs = list("generate_study_population_prevax","generate_study_population_unvax","generate_study_population_vax","preprocess_data_prevax","preprocess_data_unvax","preprocess_data_vax"),
    moderately_sensitive=list(
      counts = glue("output/study_counts_prepro.txt"),
      vax_summary = glue("output/describe_prepro_vax.txt"),
      prevax_summary = glue("output/describe_prepro_prevax.txt"),
      unvax_summary = glue("output/describe_prepro_unvax.txt")
      
    )
  ),
  
  #Count stage1 outcomes and binary covars
  action(
    name = "count_stage1_variables",
    run = "r:latest analysis/descriptives/second_input_counts.R",
    needs = list("stage1_data_cleaning_prevax","stage1_data_cleaning_unvax","stage1_data_cleaning_vax"),
    moderately_sensitive=list(
      counts = glue("output/study_counts_stage1clean.txt"),
      vax_summary = glue("output/describe_stage1clean_vax.txt"),
      prevax_summary = glue("output/describe_stage1clean_prevax.txt"),
      unvax_summary = glue("output/describe_stage1clean_unvax.txt")
      
    )
  ),
  
  ## Stage 1 - data cleaning -----------------------------------------------------------
  
  splice(
    unlist(lapply(cohorts, 
                  function(x) stage1_data_cleaning(cohort = x)), 
           recursive = FALSE
    )
  ),
  
  ## consort output ------------------------------------------------------------
  
  action(
    name = "make_consort_output",
    run = "r:latest analysis/model/make_other_output.R consort prevax;vax;unvax",
    needs = list("stage1_data_cleaning_prevax",
                 "stage1_data_cleaning_vax",
                 "stage1_data_cleaning_unvax"),
    moderately_sensitive = list(
      consort_output_midpoint6 = glue("output/consort_output_midpoint6.csv")
    )
  ),
  
  ## table 1 output ------------------------------------------------------------
  
  action(
    name = "make_table1_output",
    run = "r:latest analysis/model/make_other_output.R table1 prevax;vax;unvax",
    needs = list("table1_prevax",
                 "table1_vax",
                 "table1_unvax"),
    moderately_sensitive = list(
      table1_output_midpoint6 = glue("output/table1_output_midpoint6.csv")
    )
  ),
  
  ## table 2 output ------------------------------------------------------------
  
  action(
    name = "make_table2_output",
    run = "r:latest analysis/model/make_other_output.R table2 prevax;vax;unvax",
    needs = list("table2_prevax",
                 "table2_vax",
                 "table2_unvax"),
    moderately_sensitive = list(
      table2_output_midpoint6 = glue("output/table2_output_midpoint6.csv")
    )
  ),
  
  ## venn output ------------------------------------------------------------
  
  action(
    name = "make_venn_output",
    run = "r:latest analysis/model/make_other_output.R venn prevax;vax;unvax",
    needs = list("venn_prevax",
                 "venn_vax",
                 "venn_unvax"),
    moderately_sensitive = list(
      venn_output_midpoint6 = glue("output/venn_output_midpoint6.csv")
    )
  ),
  
  ## Table 1 -------------------------------------------------------------------
  
  splice(
    unlist(lapply(unique(active_analyses$cohort), 
                  function(x) table1(cohort = x)), 
           recursive = FALSE
    )
  ),
  
  ## Run models ----------------------------------------------------------------
  comment("Stage 5 - Run models"),

  splice(
    # over outcomes
    unlist(lapply(1:nrow(active_analyses),
                  function(x) apply_model_function(name = active_analyses$name[x],
                                                   cohort = active_analyses$cohort[x],
                                                   analysis = active_analyses$analysis[x],
                                                   ipw = active_analyses$ipw[x],
                                                   strata = active_analyses$strata[x],
                                                   covariate_sex = active_analyses$covariate_sex[x],
                                                   covariate_age = active_analyses$covariate_age[x],
                                                   covariate_other = active_analyses$covariate_other[x],
                                                   cox_start = active_analyses$cox_start[x],
                                                   cox_stop = active_analyses$cox_stop[x],
                                                   study_start = active_analyses$study_start[x],
                                                   study_stop = active_analyses$study_stop[x],
                                                   cut_points = active_analyses$cut_points[x],
                                                   controls_per_case = active_analyses$controls_per_case[x],
                                                   total_event_threshold = active_analyses$total_event_threshold[x],
                                                   episode_event_threshold = active_analyses$episode_event_threshold[x],
                                                   covariate_threshold = active_analyses$covariate_threshold[x],
                                                   age_spline = active_analyses$age_spline[x])), recursive = FALSE
    )
  ),
  
  ## Run models with Stata -----------------------------------------------------
  
  comment("Run models with stata"),
  
  splice(
    unlist(lapply(1:nrow(stata), 
                  function(x) apply_stata_model_function(name = stata$name[x],
                                                         cohort = stata$cohort[x],
                                                         analysis = stata$analysis[x],
                                                         ipw = stata$ipw[x],
                                                         strata = stata$strata[x],
                                                         covariate_sex = stata$covariate_sex[x],
                                                         covariate_age = stata$covariate_age[x],
                                                         covariate_other = stata$covariate_other[x],
                                                         cox_start = stata$cox_start[x],
                                                         cox_stop = stata$cox_stop[x],
                                                         study_start = stata$study_start[x],
                                                         study_stop = stata$study_stop[x],
                                                         cut_points = stata$cut_points[x],
                                                         controls_per_case = stata$controls_per_case[x],
                                                         total_event_threshold = stata$total_event_threshold[x],
                                                         episode_event_threshold = stata$episode_event_threshold[x],
                                                         covariate_threshold = stata$covariate_threshold[x],
                                                         age_spline = stata$age_spline[x],
                                                         day0 = stata$day0[x])), recursive = FALSE
    )
  ),

  ## Table 2 -------------------------------------------------------------------
  
  splice(
    unlist(lapply(unique(active_analyses$cohort), 
                  function(x) table2(cohort = x)), 
           recursive = FALSE
    )
  ),
  
  ## Venn data -----------------------------------------------------------------
  
  splice(
    unlist(lapply(unique(active_analyses$cohort),
                  function(x) venn(cohort = x)),
           recursive = FALSE
    )
  ),
  
  ## Model output --------------------------------------------------------------
  
  # comment("Stage 6 - make model output"),

  action(
    name = "make_model_output",
    run = "r:latest analysis/model/make_model_output.R",
    needs = as.list(c(paste0("cox_ipw-",setdiff(active_analyses$name,stata$name)),
                      paste0("stata_cox_ipw-",stata$name))),
    moderately_sensitive = list(
      model_output = glue("output/model_output.csv"),
      model_output_midpoint6 = glue("output/model_output_midpoint6.csv")
    )
  ),
  
  # Test locally
  # comment ("Stata models"), Stata Analyses
  
  action(
    name = "make_stata_model_output",
    run = "r:latest analysis/stata/make_stata_model_output.R",
    needs = as.list(paste0("stata_cox_ipw-",stata$name)),
    moderately_sensitive = list(
      stata_model_output = glue("output/stata_model_output.csv"),
      stata_model_output_midpoint6 = glue("output/stata_model_output_midpoint6.csv")
    )
  ),
  
  # comment("Calculate median (IQR) for age"),
  
  action(
    name = "median_iqr_age",
    run = "r:latest analysis/median_iqr_age.R",
    needs = list("stage1_data_cleaning_prevax",
                 "stage1_data_cleaning_vax",
                 "stage1_data_cleaning_unvax"),
    moderately_sensitive = list(
      model_output = glue("output/median_iqr_age.csv")
    )
  ),
  
  ## AER table -----------------------------------------------------------------
  
  comment("Make absolute excess risk (AER) input"),

  action(
    name = "make_aer_input",
    run = "r:latest analysis/model/make_aer_input.R",
    needs = as.list(paste0("make_model_input-",active_analyses[grepl("-main-",active_analyses$name),]$name)),
    moderately_sensitive = list(
      aer_input = glue("output/aer_input-main.csv"),
      aer_input_midpoint6 = glue("output/aer_input-main-midpoint6.csv")
    )
  )
)

## combine everything ----
project_list <- splice(
  defaults_list,
  list(actions = actions_list)
)

#####################################################################################
## convert list to yaml, reformat comments and white space, and output a .yaml file #
#####################################################################################
as.yaml(project_list, indent=2) %>%
  # convert comment actions to comments
  convert_comment_actions() %>%
  # add one blank line before level 1 and level 2 keys
  str_replace_all("\\\n(\\w)", "\n\n\\1") %>%
  str_replace_all("\\\n\\s\\s(\\w)", "\n\n  \\1") %>%
  writeLines("project.yaml")
  print("YAML file printed!")
  
# Return number of actions -----------------------------------------------------
  
print(paste0("YAML created with ",length(actions_list)," actions."))