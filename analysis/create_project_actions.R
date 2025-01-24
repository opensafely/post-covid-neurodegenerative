library(tidyverse)
library(yaml)
library(here)
library(glue)
library(readr)
library(dplyr)

# Specify defaults -------------------------------------------------------------

defaults_list <- list(
  version = "3.0",
  expectations = list(population_size = 1000L)
)
cohorts <- c("prevax","vax","unvax")
# Create generic action function -----------------------------------------------

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

# Create generic comment function ----------------------------------------------

comment <- function(...){
  list_comments <- list(...)
  comments <- map(list_comments, ~paste0("## ", ., " ##"))
  comments
}


# Create function to convert comment "actions" in a yaml string into proper comments

convert_comment_actions <-function(yaml.txt){
  yaml.txt %>%
    str_replace_all("\\\n(\\s*)\\'\\'\\:(\\s*)\\'", "\n\\1")  %>%
    #str_replace_all("\\\n(\\s*)\\'", "\n\\1") %>%
    str_replace_all("([^\\'])\\\n(\\s*)\\#\\#", "\\1\n\n\\2\\#\\#") %>%
    str_replace_all("\\#\\#\\'\\\n", "\n")
}

# Create function to generate study population ---------------------------------

generate_study_population <- function(cohort){
  splice(
    comment(glue("Generate study population - {cohort}")),
    action(
      name = glue("generate_study_population_{cohort}"),
      run = glue("ehrql:v1 generate-dataset analysis/dataset_definition/dataset_definition_{cohort}.py --output output/input_{cohort}.csv.gz"),
      needs = list("generate_dataset_index_dates"),
      highly_sensitive = list(
        cohort = glue("output/input_{cohort}.csv.gz")
      )
    )
  )
}

# Create function to preprocess data -------------------------------------------

preprocess_data <- function(cohort){
  splice(
    comment(glue("Preprocess data - {cohort}")),
    action(
      name = glue("preprocess_data_{cohort}"),
      run = glue("r:latest analysis/preprocess/preprocess_data.R"),
      arguments = c(cohort),
      needs = list("generate_dataset_index_dates",glue("generate_study_population_{cohort}")),
      moderately_sensitive = list(
        describe = glue("output/describe_input_{cohort}_stage0.txt"),
        describe_venn = glue("output/describe_venn_{cohort}.txt")
      ),
      highly_sensitive = list(
        cohort = glue("output/input_{cohort}.rds"),
        venn = glue("output/venn_{cohort}.rds")
      )
    )
  )
}

# Define and combine all actions into a list of actions ------------------------------0

actions_list <- splice(
  
  ## Post YAML disclaimer ------------------------------------------------------
  
  comment("# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #",
          "DO NOT EDIT project.yaml DIRECTLY",
          "This file is created by create_project_actions.R",
          "Edit and run create_project_actions.R to update the project.yaml",
          "# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #"
  ),
  
  ## Generate vaccination eligibility information ------------------------------
  comment("Generate vaccination eligibility information"),
  
  action(
    name = glue("vax_eligibility_inputs"),
    run = "r:latest analysis/dataset_definition/metadates.R",
    highly_sensitive = list(
      study_dates_json = glue("output/study_dates.json")
    )
  ),
  
  ## Generate index dates for all study cohorts ------------------------------------------
  comment("Generate dates for all cohorts"),
  
  action(
    name = "generate_dataset_index_dates",
    run = "ehrql:v1 generate-dataset analysis/dataset_definition/dataset_definition_dates.py --output output/index_dates.csv.gz",
    needs = list("vax_eligibility_inputs"),
    highly_sensitive = list(
      dataset = glue("output/index_dates.csv.gz")
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
  )
)


# Combine actions into project list --------------------------------------------

project_list <- splice(
  defaults_list,
  list(actions = actions_list)
)

# Convert list to yaml, reformat, and output a .yaml file ----------------------

as.yaml(project_list, indent=2) %>%
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

print(paste0("YAML created with ",count_run_elements(actions_list)," actions."))