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
active_analyses <- active_analyses[order(active_analyses$analysis,active_analyses$cohort,active_analyses$outcome),]
cohort_to_run <- unique(active_analyses$cohort)
#names <- unique(active_analyses$names)

# Determine which outputs are ready --------------------------------------------

success <- readxl::read_excel("C:/Users/rs22981/OneDrive - University of Bristol/Projects/post-covid-outcome-tracker.xlsx",
                              sheet = "neurodegenerative",
                      col_types = c("text","text", "text", "text", "text", "text",
                                    "text", "text", "text", "text", "text",
                                    "text", "text", "text", "text", "text", "text",
                                    "skip", "skip"))

success <- tidyr::pivot_longer(success,
                               cols = setdiff(colnames(success),c("outcome","cohort")),
                               names_to = "analysis")

success$name <- paste0("cohort_",success$cohort, "-",success$analysis, "-",success$outcome)

success <- success[grepl("success",success$value, ignore.case = TRUE),]

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
    
    # action(
    #   name = glue("describe_model_input-{name}"),
    #   run = glue("r:latest analysis/describe_file.R model_input-{name} rds"),
    #   needs = list(glue("make_model_input-{name}")),
    #   moderately_sensitive = list(
    #     describe_model_input = glue("output/describe-model_input-{name}.txt")
    #   )
    # ),
    
    #comment(glue("Cox model for {outcome} - {cohort}")),
    action(
      name = glue("cox_ipw-{name}"),
      run = glue("cox-ipw:v0.0.18 --df_input=model_input-{name}.rds --ipw={ipw} --exposure=exp_date --outcome=out_date --strata={strata} --covariate_sex={covariate_sex} --covariate_age={covariate_age} --covariate_other={covariate_other} --cox_start={cox_start} --cox_stop={cox_stop} --study_start={study_start} --study_stop={study_stop} --cut_points={cut_points} --controls_per_case={controls_per_case} --total_event_threshold={total_event_threshold} --episode_event_threshold={episode_event_threshold} --covariate_threshold={covariate_threshold} --age_spline={age_spline} --df_output=model_output-{name}.csv"),
      needs = list(glue("make_model_input-{name}")),
      moderately_sensitive = list(
        model_output = glue("output/model_output-{name}.csv"))
    )
  )
}

# table2 <- function(cohort){
#   splice(
#     comment(glue("Stage 4 - Table 2 - {cohort} cohort")),
#     action(
#       name = glue("stage4_table_2_{cohort}"),
#       run = "r:latest analysis/descriptives/table_2.R",
#       arguments = c(cohort),
#       needs = list("stage1_data_cleaning_all"),
#       moderately_sensitive = list(
#         input_table_2 = glue("output/review/descriptives/table2_{cohort}.csv")
#       )
#     )
#   )
# }

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
    run = "cohortextractor:latest generate_cohort --study-definition study_definition_prevax --output-format csv.gz",
    needs = list("vax_eligibility_inputs","generate_index_dates"),
    highly_sensitive = list(
      cohort = glue("output/input_prevax.csv.gz")
    )
  ),
  #comment("Generate dummy data for study_definition - vax"),
  action(
    name = "generate_study_population_vax",
    run = "cohortextractor:latest generate_cohort --study-definition study_definition_vax --output-format csv.gz",
    needs = list("generate_index_dates","vax_eligibility_inputs"),
    highly_sensitive = list(
      cohort = glue("output/input_vax.csv.gz")
    )
  ),
  #comment("Generate dummy data for study_definition - unvax"),
  action(
    name = "generate_study_population_unvax",
    run = "cohortextractor:latest generate_cohort --study-definition study_definition_unvax --output-format csv.gz",
    needs = list("vax_eligibility_inputs","generate_index_dates"),
    highly_sensitive = list(
      cohort = glue("output/input_unvax.csv.gz")
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

  #comment("Stage 1 - Data cleaning - PREVAX cohort"),
  action(
    name = "stage1_data_cleaning_prevax",
    run = "r:latest analysis/preprocess/Stage1_data_cleaning.R prevax",
    needs = list("preprocess_data_prevax","preprocess_data_vax", "preprocess_data_unvax","vax_eligibility_inputs"),
    moderately_sensitive = list(
      refactoring = glue("output/not-for-review/meta_data_factors_prevax.csv"),
      QA_rules = glue("output/review/descriptives/QA_summary_prevax.csv"),
      IE_criteria = glue("output/review/descriptives/Cohort_flow_prevax.csv"),
      histograms = glue("output/not-for-review/numeric_histograms_prevax.svg")
    ),
    highly_sensitive = list(
      cohort = glue("output/input_prevax_*.rds")
    )
  ),
  
  #comment("Stage 1 - Data cleaning - VAX cohort"),
  action(
    name = "stage1_data_cleaning_vax",
    run = "r:latest analysis/preprocess/Stage1_data_cleaning.R vax",
    needs = list("preprocess_data_prevax","preprocess_data_vax", "preprocess_data_unvax","vax_eligibility_inputs"),
    moderately_sensitive = list(
      refactoring = glue("output/not-for-review/meta_data_factors_vax.csv"),
      QA_rules = glue("output/review/descriptives/QA_summary_vax.csv"),
      IE_criteria = glue("output/review/descriptives/Cohort_flow_vax.csv"),
      histograms = glue("output/not-for-review/numeric_histograms_vax.svg")
    ),
    highly_sensitive = list(
      cohort = glue("output/input_vax_*.rds")
    )
  ),
  
  #comment("Stage 1 - Data cleaning - UNVAX cohort"),
  action(
    name = "stage1_data_cleaning_unvax",
    run = "r:latest analysis/preprocess/Stage1_data_cleaning.R unvax",
    needs = list("preprocess_data_prevax","preprocess_data_vax", "preprocess_data_unvax","vax_eligibility_inputs"),
    moderately_sensitive = list(
      refactoring = glue("output/not-for-review/meta_data_factors_unvax.csv"),
      QA_rules = glue("output/review/descriptives/QA_summary_unvax.csv"),
      IE_criteria = glue("output/review/descriptives/Cohort_flow_unvax.csv"),
      histograms = glue("output/not-for-review/numeric_histograms_unvax.svg")
    ),
    highly_sensitive = list(
      cohort = glue("output/input_unvax_*.rds")
    )
  ),
  
  # 
  # #comment("Stage 1 - End date table - prevax"),
  # action(
  #    name = "stage1_end_date_table_prevax",
  #    run = "r:latest analysis/preprocess/create_follow_up_end_date.R prevax",
  #    needs = list("preprocess_data_prevax","preprocess_data_vax", "preprocess_data_unvax", "stage1_data_cleaning_all","vax_eligibility_inputs"),
  #    highly_sensitive = list(
  #      end_date_table = glue("output/follow_up_end_dates_prevax.rds")#_*
  #   )
  # ),
  # #comment("Stage 1 - End date table - vax"),
  # action(
  #   name = "stage1_end_date_table_vax",
  #   run = "r:latest analysis/preprocess/create_follow_up_end_date.R vax",
  #   needs = list("preprocess_data_prevax","preprocess_data_vax", "preprocess_data_unvax", "stage1_data_cleaning_all","vax_eligibility_inputs"),
  #   highly_sensitive = list(
  #     end_date_table = glue("output/follow_up_end_dates_vax.rds")#_*
  #   )
  # ),
  # #comment("Stage 1 - End date table - unvax"),
  # action(
  #   name = "stage1_end_date_table_unvax",
  #   run = "r:latest analysis/preprocess/create_follow_up_end_date.R unvax",
  #   needs = list("preprocess_data_prevax","preprocess_data_vax", "preprocess_data_unvax", "stage1_data_cleaning_all","vax_eligibility_inputs"),
  #   highly_sensitive = list(
  #     end_date_table = glue("output/follow_up_end_dates_unvax.rds")#_*
  #   )
  # )
  
  # action(
  #   name = glue("describe_file-input_prevax_stage1"),
  #   run = glue("r:latest analysis/describe_file.R input_prevax_stage1 rds"),
  #   needs = list("stage1_data_cleaning_all"),
  #   moderately_sensitive = list(
  #     describe_model_input = glue("output/describe-input_prevax_stage1.txt")
  #   )
  # ),
  # 
  # action(
  #   name = glue("describe_file-input_vax_stage1"),
  #   run = glue("r:latest analysis/describe_file.R input_vax_stage1 rds"),
  #   needs = list("stage1_data_cleaning_all"),
  #   moderately_sensitive = list(
  #     describe_model_input = glue("output/describe-input_vax_stage1.txt")
  #   )
  # ),
  # 
  # action(
  #   name = glue("describe_file-input_unvax_stage1"),
  #   run = glue("r:latest analysis/describe_file.R input_unvax_stage1 rds"),
  #   needs = list("stage1_data_cleaning_all"),
  #   moderately_sensitive = list(
  #     describe_model_input = glue("output/describe-input_unvax_stage1.txt")
  #   )
  # ),
  
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
  )#,
  
  # comment("Stage 6 - make model output"),
  # 
  # action(
  #   name = "make_model_output",
  #   run = "r:latest analysis/model/make_model_output.R",
  #   needs = as.list(paste0("cox_ipw-",success$name)),
  #   moderately_sensitive = list(
  #     model_output = glue("output/model_output.csv")
  #   )
  # )
  
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