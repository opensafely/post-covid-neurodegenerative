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

# Determine which outputs are ready --------------------------------------------

success <- readxl::read_excel("../../OneDrive - University of Bristol/Projects/post-covid-outcome-tracker.xlsx", 
                              sheet = "neuro_extf",
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
        refactoring = glue("output/not-for-review/meta_data_factors_{cohort}.csv"),
        QA_rules = glue("output/review/descriptives/QA_summary_{cohort}.csv"),
        IE_criteria = glue("output/review/descriptives/Cohort_flow_{cohort}.csv"),
        histograms = glue("output/not-for-review/numeric_histograms_{cohort}.svg")#,
        #consort = glue("output/consort_{cohort}.csv"),
        #consort_rounded = glue("output/consort_{cohort}_rounded.csv")
      ),
      highly_sensitive = list(
        cohort = glue("output/input_{cohort}_stage1.rds")
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
        table1_rounded = glue("output/table1_{cohort}_rounded.csv")
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
      run = glue("cox-ipw:v0.0.27 --df_input=model_input-{name}.rds --ipw={ipw} --exposure=exp_date --outcome=out_date --strata={strata} --covariate_sex={covariate_sex} --covariate_age={covariate_age} --covariate_other={covariate_other} --cox_start={cox_start} --cox_stop={cox_stop} --study_start={study_start} --study_stop={study_stop} --cut_points={cut_points} --controls_per_case={controls_per_case} --total_event_threshold={total_event_threshold} --episode_event_threshold={episode_event_threshold} --covariate_threshold={covariate_threshold} --age_spline={age_spline} --df_output=model_output-{name}.csv"),
      needs = list(glue("make_model_input-{name}")),
      moderately_sensitive = list(
        model_output = glue("output/model_output-{name}.csv"))
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
        table2_rounded = glue("output/table2_{cohort}_rounded.csv")
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
        table2_rounded = glue("output/venn_{cohort}_rounded.csv")
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
  
  ## Stage 1 - data cleaning -----------------------------------------------------------
  
  splice(
    unlist(lapply(cohorts, 
                  function(x) stage1_data_cleaning(cohort = x)), 
           recursive = FALSE
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
  
  comment("Stage 6 - make model output"),

  action(
    name = "make_model_output",
    run = "r:latest analysis/model/make_model_output.R",
    needs = as.list(paste0("cox_ipw-",success$name)),
    moderately_sensitive = list(
      model_output = glue("output/model_output.csv")
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
      aer_input_rounded = glue("output/aer_input-main-rounded.csv")
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