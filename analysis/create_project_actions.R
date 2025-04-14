# Load libraries ---------------------------------------------------------------

library(tidyverse)
library(yaml)
library(here)
library(glue)
library(readr)
library(dplyr)

# Specify defaults -------------------------------------------------------------

defaults_list <- list(
  version = "3.0",
  expectations = list(population_size = 5000L)
)

active_analyses <- read_rds("lib/active_analyses.rds")
active_analyses <- active_analyses[
  order(
    active_analyses$analysis,
    active_analyses$cohort,
    active_analyses$outcome
  ),
]
cohorts <- unique(active_analyses$cohort)

active_age <- active_analyses[grepl("_age_", active_analyses$name), ]$name
age_str <- paste0(
  paste0(
    unique(sub(".*_age_([0-9]+)_([0-9]+).*", "\\1", active_age)),
    collapse = ";"
  ),
  ";",
  max(
    as.numeric(unique(sub(".*_age_([0-9]+)_([0-9]+).*", "\\2", active_age))) +
      1
  )
) #create age vector in form "X;XX;XX;XX;XXX"

describe <- TRUE # This prints descriptive files for each dataset in the pipeline

# Create generic action function -----------------------------------------------

action <- function(
  name,
  run,
  dummy_data_file = NULL,
  arguments = NULL,
  needs = NULL,
  highly_sensitive = NULL,
  moderately_sensitive = NULL
) {
  outputs <- list(
    moderately_sensitive = moderately_sensitive,
    highly_sensitive = highly_sensitive
  )
  outputs[sapply(outputs, is.null)] <- NULL

  actions <- list(
    run = paste(c(run, arguments), collapse = " "),
    dummy_data_file = dummy_data_file,
    needs = needs,
    outputs = outputs
  )
  actions[sapply(actions, is.null)] <- NULL

  action_list <- list(name = actions)
  names(action_list) <- name

  action_list
}

# Create generic comment function ----------------------------------------------

comment <- function(...) {
  list_comments <- list(...)
  comments <- map(list_comments, ~ paste0("## ", ., " ##"))
  comments
}


# Create function to convert comment "actions" in a yaml string into proper comments

convert_comment_actions <- function(yaml.txt) {
  yaml.txt %>%
    str_replace_all("\\\n(\\s*)\\'\\'\\:(\\s*)\\'", "\n\\1") %>%
    #str_replace_all("\\\n(\\s*)\\'", "\n\\1") %>%
    str_replace_all("([^\\'])\\\n(\\s*)\\#\\#", "\\1\n\n\\2\\#\\#") %>%
    str_replace_all("\\#\\#\\'\\\n", "\n")
}

# Create function to generate study population ---------------------------------

generate_cohort <- function(cohort) {
  splice(
    comment(glue("Generate cohort - {cohort}")),
    action(
      name = glue("generate_cohort_{cohort}"),
      run = glue(
        "ehrql:v1 generate-dataset analysis/dataset_definition/dataset_definition_{cohort}.py --output output/dataset_definition/input_{cohort}.csv.gz"
      ),
      needs = list("generate_dates"),
      highly_sensitive = list(
        cohort = glue("output/dataset_definition/input_{cohort}.csv.gz")
      )
    )
  )
}

# Create function to clean data -------------------------------------------------

clean_data <- function(cohort, describe = describe) {
  splice(
    comment(glue("Clean data - {cohort}, with describe = {describe}")),
    if (isTRUE(describe)) {
      # Action to include describe*.txt files
      action(
        name = glue("clean_data_{cohort}"),
        run = glue("r:latest analysis/dataset_clean/dataset_clean.R"),
        arguments = c(c(cohort), c(describe)),
        needs = list(
          "study_dates",
          glue("generate_cohort_{cohort}")
        ),
        moderately_sensitive = list(
          describe_raw = glue("output/describe/{cohort}_raw.txt"),
          describe_venn = glue("output/describe/{cohort}_venn.txt"),
          describe_preprocessed = glue(
            "output/describe/{cohort}_preprocessed.txt"
          ),
          flow = glue("output/dataset_clean/flow_{cohort}.csv"),
          flow_midpoint6 = glue(
            "output/dataset_clean/flow_{cohort}_midpoint6.csv"
          )
        ),
        highly_sensitive = list(
          venn = glue("output/dataset_clean/venn_{cohort}.rds"),
          cohort_clean = glue("output/dataset_clean/input_{cohort}_clean.rds")
        )
      )
    } else {
      # Action to exclude describe*.txt files
      action(
        name = glue("clean_data_{cohort}"),
        run = glue("r:latest analysis/dataset_clean/dataset_clean.R"),
        arguments = c(c(cohort), c(describe)),
        needs = list(
          "study_dates",
          glue("generate_cohort_{cohort}")
        ),
        moderately_sensitive = list(
          flow = glue("output/dataset_clean/flow_{cohort}.csv"),
          flow_midpoint6 = glue(
            "output/dataset_clean/flow_{cohort}_midpoint6.csv"
          )
        ),
        highly_sensitive = list(
          venn = glue("output/dataset_clean/venn_{cohort}.rds"),
          cohort_clean = glue("output/dataset_clean/input_{cohort}_clean.rds")
        )
      )
    }
  )
}

# Create function to make model input and run a model --------------------------

apply_model_function <- function(
  name,
  cohort,
  analysis,
  ipw,
  strata,
  covariate_sex,
  covariate_age,
  covariate_other,
  cox_start,
  cox_stop,
  study_start,
  study_stop,
  cut_points,
  controls_per_case,
  total_event_threshold,
  episode_event_threshold,
  covariate_threshold,
  age_spline
) {
  splice(
    action(
      name = glue("make_model_input-{name}"),
      run = glue("r:latest analysis/model/make_model_input.R {name}"),
      needs = as.list(glue("clean_data_{cohort}")),
      highly_sensitive = list(
        model_input = glue("output/model/model_input-{name}.rds")
      )
    ),

    action(
      name = glue("cox_ipw-{name}"),
      run = glue(
        "cox-ipw:v0.0.37 --df_input=model/model_input-{name}.rds --ipw={ipw} --exposure=exp_date --outcome=out_date --strata={strata} --covariate_sex={covariate_sex} --covariate_age={covariate_age} --covariate_other={covariate_other} --cox_start={cox_start} --cox_stop={cox_stop} --study_start={study_start} --study_stop={study_stop} --cut_points={cut_points} --controls_per_case={controls_per_case} --total_event_threshold={total_event_threshold} --episode_event_threshold={episode_event_threshold} --covariate_threshold={covariate_threshold} --age_spline={age_spline} --save_analysis_ready=FALSE --run_analysis=TRUE --df_output=model/model_output-{name}.csv"
      ),
      needs = list(glue("make_model_input-{name}")),
      moderately_sensitive = list(
        model_output = glue("output/model/model_output-{name}.csv")
      )
    )
  )
}

# Define and combine all actions into a list of actions ------------------------

actions_list <- splice(
  ## Post YAML disclaimer ------------------------------------------------------

  comment(
    "# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #",
    "DO NOT EDIT project.yaml DIRECTLY",
    "This file is created by create_project_actions.R",
    "Edit and run create_project_actions.R to update the project.yaml",
    "# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #"
  ),

  ## Define study dates --------------------------------------------------------
  comment("Define study dates"),

  action(
    name = glue("study_dates"),
    run = "r:latest analysis/study_dates.R",
    highly_sensitive = list(
      study_dates_json = glue("output/study_dates.json")
    )
  ),

  ## Generate index dates for all study cohorts --------------------------------
  comment("Generate dates for all cohorts"),

  action(
    name = "generate_dates",
    run = "ehrql:v1 generate-dataset analysis/dataset_definition/dataset_definition_dates.py --output output/dataset_definition/index_dates.csv.gz",
    needs = list("study_dates"),
    highly_sensitive = list(
      dataset = glue("output/dataset_definition/index_dates.csv.gz")
    )
  ),

  ## Generate study population -------------------------------------------------

  splice(
    unlist(
      lapply(cohorts, function(x) generate_cohort(cohort = x)),
      recursive = FALSE
    )
  ),

  ## Clean data -----------------------------------------------------------

  splice(
    unlist(
      lapply(cohorts, function(x) clean_data(cohort = x, describe = describe)),
      recursive = FALSE
    )
  ),

  ## Run models ----------------------------------------------------------------
  comment("Run models"),

  splice(
    unlist(
      lapply(
        1:nrow(active_analyses),
        function(x)
          apply_model_function(
            name = active_analyses$name[x],
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
            episode_event_threshold = active_analyses$episode_event_threshold[
              x
            ],
            covariate_threshold = active_analyses$covariate_threshold[x],
            age_spline = active_analyses$age_spline[x]
          )
      ),
      recursive = FALSE
    )
  )
)

# Combine actions into project list --------------------------------------------

project_list <- splice(
  defaults_list,
  list(actions = actions_list)
)

# Convert list to yaml, reformat, and output a .yaml file ----------------------

as.yaml(project_list, indent = 2) %>%
  # convert comment actions to comments
  convert_comment_actions() %>%
  # add one blank line before level 1 and level 2 keys
  str_replace_all("\\\n(\\w)", "\n\n\\1") %>%
  str_replace_all("\\\n\\s\\s(\\w)", "\n\n  \\1") %>%
  writeLines("project.yaml")

# Return number of actions -----------------------------------------------------

count_run_elements <- function(x) {
  if (!is.list(x)) {
    return(0)
  }

  # Check if any names of this list are "run"
  current_count <- sum(names(x) == "run", na.rm = TRUE)

  # Recursively check all elements in the list
  return(current_count + sum(sapply(x, count_run_elements)))
}

print(paste0(
  "YAML created with ",
  count_run_elements(actions_list),
  " actions."
))
