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
  expectations= list(population_size=200000L)
)

active_analyses <- read_rds("lib/active_analyses.rds")
cohort_to_run <- unique(active_analyses$cohort)

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


# #################################################
# ## Function for typical actions to analyse data #
# #################################################

# # Updated to a typical action running Cox models for one outcome
# apply_model_function <- function(outcome, cohort){
#   splice(
#     comment(glue("Cox model for {outcome} - {cohort}")),
#     action(
#       name = glue("Analysis_cox_{outcome}_{cohort}"),
#       run = "r:latest analysis/model/01_cox_pipeline.R",
#       arguments = c(outcome,cohort),
#       needs = list("stage1_data_cleaning_both", glue("stage1_end_date_table_{cohort}"),"select_covariates_for_hosp_covid"),
#       moderately_sensitive = list(
#         analyses_not_run = glue("output/review/model/analyses_not_run_{outcome}_{cohort}.csv"),
#         compiled_hrs_csv = glue("output/review/model/suppressed_compiled_HR_results_{outcome}_{cohort}.csv"),
#         compiled_hrs_csv_to_release = glue("output/review/model/suppressed_compiled_HR_results_{outcome}_{cohort}_to_release.csv"),
#         compiled_event_counts_csv = glue("output/review/model/suppressed_compiled_event_counts_{outcome}_{cohort}.csv")
#       )
#     )
#   )
# }

table2 <- function(cohort){
  splice(
    comment(glue("Stage 4 - Table 2 - {cohort} cohort")),
    action(
      name = glue("stage4_table_2_{cohort}"),
      run = "r:latest analysis/descriptives/table_2.R",
      arguments = c(cohort),
      needs = list("stage1_data_cleaning_all"),
      moderately_sensitive = list(
        input_table_2 = glue("output/review/descriptives/table2_{cohort}.csv")
      )
    )
  )
}

##########################################################
## Define and combine all actions into a list of actions #
##########################################################
actions_list <- splice(
  
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
      vax_jcvi_groups= glue("output/vax_jcvi_groups.csv"),
      vax_eligible_dates= ("output/vax_eligible_dates.csv")
    )
  ),
  #comment("Generate dummy data for study_definition - population_prelim"),
  action(
    name = "generate_study_population_prelim",
    run = "cohortextractor:latest generate_cohort --study-definition study_definition_prelim --output-format feather",
    needs = list("vax_eligibility_inputs"),
    highly_sensitive = list(
      cohort = glue("output/input_prelim.feather")
    )
  ),
  #comment("Generate dates for all study cohorts"), 
  action(
    name = "generate_index_dates",
    run = "r:latest analysis/prelim.R",
    needs = list("vax_eligibility_inputs","generate_study_population_prelim"),
    highly_sensitive = list(
      index_dates = glue("output/index_dates.csv")
    )
  ),
  
  #comment("Generate dummy data for study_definition - prevax"),
  action(
    name = "generate_study_population_prevax",
    run = "cohortextractor:latest generate_cohort --study-definition study_definition_prevax --output-format feather",
    needs = list("vax_eligibility_inputs","generate_index_dates"),
    highly_sensitive = list(
      cohort = glue("output/input_prevax.feather")
    )
  ),
  #comment("Generate dummy data for study_definition - vax"),
  action(
    name = "generate_study_population_vax",
    run = "cohortextractor:latest generate_cohort --study-definition study_definition_vax --output-format feather",
    needs = list("generate_index_dates","vax_eligibility_inputs"),
    highly_sensitive = list(
      cohort = glue("output/input_vax.feather")
    )
  ),
  #comment("Generate dummy data for study_definition - unvax"),
  action(
    name = "generate_study_population_unvax",
    run = "cohortextractor:latest generate_cohort --study-definition study_definition_unvax --output-format feather",
    needs = list("vax_eligibility_inputs","generate_index_dates"),
    highly_sensitive = list(
      cohort = glue("output/input_unvax.feather")
    )
  ),
  
  #comment("Preprocess data - prevax"),
  action(
    name = "preprocess_data_prevax",
    run = "r:latest analysis/preprocess/preprocess_data.R prevax",
    needs = list( "generate_index_dates","generate_study_population_prevax"),
    moderately_sensitive = list(
      describe = glue("output/not-for-review/describe_input_prevax_stage0.txt"),
      describe_venn = glue("output/not-for-review/describe_venn_prevax.txt")
    ),
    highly_sensitive = list(
      cohort = glue("output/input_prevax.rds"),
      venn = glue("output/venn_prevax.rds")
    )
  ),
  #comment("Preprocess data - vax"),
  action(
    name = "preprocess_data_vax",
    run = "r:latest analysis/preprocess/preprocess_data.R vax",
    needs = list("generate_index_dates","generate_study_population_vax"),
    moderately_sensitive = list(
      describe = glue("output/not-for-review/describe_input_vax_stage0.txt"),
      descrive_venn = glue("output/not-for-review/describe_venn_vax.txt")
    ),
    highly_sensitive = list(
      cohort = glue("output/input_vax.rds"),
      venn = glue("output/venn_vax.rds")
    )
  ),
  #comment("Preprocess data - unvax"),
  action(
    name = "preprocess_data_unvax",
    run = "r:latest analysis/preprocess/preprocess_data.R unvax",
    needs = list("generate_index_dates", "generate_study_population_unvax"),
    moderately_sensitive = list(
      describe = glue("output/not-for-review/describe_input_unvax_stage0.txt"),
      describe_venn = glue("output/not-for-review/describe_venn_unvax.txt")
    ),
    highly_sensitive = list(
      cohort = glue("output/input_unvax.rds"),
      venn = glue("output/venn_unvax.rds")
    )
  ),
  
  #comment("Stage 1 - Data cleaning - all cohorts"),
  action(
    name = "stage1_data_cleaning_all",
    run = "r:latest analysis/preprocess/Stage1_data_cleaning.R all",
    needs = list("preprocess_data_prevax","preprocess_data_vax", "preprocess_data_unvax","vax_eligibility_inputs"),
    moderately_sensitive = list(
      refactoring = glue("output/not-for-review/meta_data_factors_*.csv"),
      QA_rules = glue("output/review/descriptives/QA_summary_*.csv"),
      IE_criteria = glue("output/review/descriptives/Cohort_flow_*.csv"),
      histograms = glue("output/not-for-review/numeric_histograms_*.svg")
    ),
    highly_sensitive = list(
      cohort = glue("output/input_*.rds")
    )
  ),
  
  # #comment("Stage 2 - Missing - Table 1 - all cohorts"),
  # action(
  #   name = "stage2_missing_table1_all",
  #   run = "r:latest analysis/descriptives/Stage2_missing_table1.R all",
  #   needs = list("stage1_data_cleaning_all"),
  #   moderately_sensitive = list(
  #     Missing_RangeChecks = glue("output/not-for-review/Check_missing_range_*.csv"),
  #     DateChecks = glue("output/not-for-review/Check_dates_range_*.csv"),
  #     Descriptive_Table = glue("output/review/descriptives/Table1_*.csv")
  #   )
  # ),
  
  # #comment("Format Table 1"),
  # action(
  #   name = "format_table1",
  #   run = "r:latest analysis/descriptives/format_table1.R",
  #   needs = list("stage2_missing_table1_all"),
  #   moderately_sensitive = list(
  #     formatted_tables = glue("output/review/descriptives/Table1_Formatted_To_Release_*.csv")
  #   )
  # ),
  
  # #comment("Stage 3 - No action there for Mental Health outcomes"),  
  
  #comment("Stage 4 - Create input for table2"),
  # splice(
  #   # over outcomes
  #   unlist(lapply(cohort_to_run, function(x) table2(cohort = x)), recursive = FALSE)
  # ),
  
  comment("Stage 5a - Make model input"),
  # Note: this can be split in various ways, cohort seems to be a fair compromise on number of actions vs runtime
  
  action(
    name = "make_model_input-cohort_vax",
    run = "r:latest analysis/model/make_model_input.R cohort_vax",
    needs = list("stage1_data_cleaning_all"),
    highly_sensitive = list(
      model_input = glue("output/model_input-cohort_vax*.csv")
    )
  ),
  
  action(
    name = "make_model_input-cohort_unvax",
    run = "r:latest analysis/model/make_model_input.R cohort_unvax",
    needs = list("stage1_data_cleaning_all"),
    highly_sensitive = list(
      model_input = glue("output/model_input-cohort_unvax*.csv")
    )
  ),
  
  action(
    name = "make_model_input-cohort_prevax",
    run = "r:latest analysis/model/make_model_input.R cohort_prevax",
    needs = list("stage1_data_cleaning_all"),
    highly_sensitive = list(
      model_input = glue("output/model_input-cohort_prevax*.csv")
    )
  ),
  
  comment("Stage 5b - Run models"),

  action(
    name = "cox_ipw-cohort_vax-vascular_dementia-main",
    run = glue("cox-ipw:v0.0.8",
               " --df_input=model_input-", active_analyses$name[1], ".csv",
               " --ipw=",active_analyses$ipw[1],
               " --exposure=exp_date",
               " --outcome=out_date",
               " --strata=",active_analyses$strata[1],
               " --covariate_sex=",active_analyses$covariate_sex[1],
               " --covariate_age=",active_analyses$covariate_age[1],
               " --covariate_other=",active_analyses$covariate_other[1],
               " --cox_start=",active_analyses$cox_start[1],
               " --cox_stop=",active_analyses$cox_stop[1],
               " --study_start=",active_analyses$study_start[1],
               " --study_stop=",active_analyses$study_stop[1],
               " --cut_points=",active_analyses$cut_points[1],
               " --controls_per_case=",active_analyses$controls_per_case[1],
               " --total_event_threshold=",active_analyses$total_event_threshold[1],
               " --episode_event_threshold=",active_analyses$episode_event_threshold[1],
               " --covariate_threshold=",active_analyses$covariate_threshold[1],
               " --age_spline=",active_analyses$age_spline[1],
               " --df_output=results-",active_analyses$name[1],".csv"),
    needs = list("make_model_input-cohort_vax"),
    moderately_sensitive = list(
      model_input = glue("output/results-*.csv")
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