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

describe <- FALSE # This prints descriptive files for each dataset in the pipeline

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
    comment(glue("Generate input_{cohort}")),
    action(
      name = glue("generate_input_{cohort}"),
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

# Create function to generate rsd study population ---------------------------------

generate_rsd_cohort <- function(cohort) {
  splice(
    comment(glue("Generate input_rsd_{cohort}")),
    action(
      name = glue("generate_input_rsd_{cohort}"),
      run = glue(
        "ehrql:v1 generate-dataset analysis/dataset_definition_rsd/dataset_definition_rsd_{cohort}.py --output output/dataset_definition_rsd/input_rsd_{cohort}.csv.gz"
      ),
      needs = list("generate_dates"),
      highly_sensitive = list(
        cohort = glue("output/dataset_definition_rsd/input_rsd_{cohort}.csv.gz")
      )
    )
  )
}

# Create function to run code diagnostics on a particular variable -------------

check_outcome <- function(outcome, cohort, dd_group = "") {
  cohort_names <- stringr::str_split(as.vector(cohort), ";")[[1]]
  cohort_str <- paste0("-", paste0(cohort_names, collapse = "_"))
  if (dd_group != "") {
    dd_group_str <- paste0("_", dd_group)
  } else {
    dd_group_str <- ""
  }
  splice(
    comment(glue("Run check_outcome_{outcome}{dd_group_str}{cohort_str}")),
    action(
      name = glue("check_outcome_{outcome}{dd_group_str}{cohort_str}"),
      run = glue("r:v2 analysis/code_diagnostics/diagnose_outcome.R"),
      arguments = unlist(lapply(
        list(c(outcome, cohort, dd_group)),
        function(x) {
          x[x != ""]
        }
      )),
      needs = c(as.list(paste0(
        "generate_input",
        dd_group_str,
        "_",
        cohort_names
      ))),
      moderately_sensitive = list(
        describe_outcome = glue(
          "output/code_diagnostics/{outcome}{dd_group_str}{cohort_str}.txt"
        )
      )
    )
  )
}

# Create function to clean data -------------------------------------------------

clean_data <- function(cohort, describe = describe) {
  splice(
    comment(glue("Generate input_{cohort}_clean, with describe = {describe}")),
    if (isTRUE(describe)) {
      # Action to include describe*.txt files
      action(
        name = glue("generate_input_{cohort}_clean"),
        run = glue("r:v2 analysis/dataset_clean/dataset_clean.R"),
        arguments = c(c(cohort), c(describe)),
        needs = list(
          "study_dates",
          glue("generate_input_{cohort}")
        ),
        moderately_sensitive = list(
          describe_raw = glue("output/describe/{cohort}_raw.txt"),
          describe_venn = glue("output/describe/{cohort}_venn.txt"),
          describe_preprocessed = glue(
            "output/describe/{cohort}_preprocessed.txt"
          ),
          flow = glue("output/dataset_clean/flow-cohort_{cohort}.csv"),
          flow_midpoint6 = glue(
            "output/dataset_clean/flow-cohort_{cohort}-midpoint6.csv"
          )
        ),
        highly_sensitive = list(
          venn = glue("output/dataset_clean/venn-cohort_{cohort}.rds"),
          cohort_clean = glue("output/dataset_clean/input_{cohort}_clean.rds")
        )
      )
    } else {
      # Action to exclude describe*.txt files
      action(
        name = glue("generate_input_{cohort}_clean"),
        run = glue("r:v2 analysis/dataset_clean/dataset_clean.R"),
        arguments = c(c(cohort), c(describe)),
        needs = list(
          "study_dates",
          glue("generate_input_{cohort}")
        ),
        moderately_sensitive = list(
          flow = glue("output/dataset_clean/flow-cohort_{cohort}.csv"),
          flow_midpoint6 = glue(
            "output/dataset_clean/flow-cohort_{cohort}-midpoint6.csv"
          )
        ),
        highly_sensitive = list(
          venn = glue("output/dataset_clean/venn-cohort_{cohort}.rds"),
          cohort_clean = glue("output/dataset_clean/input_{cohort}_clean.rds")
        )
      )
    }
  )
}


# Create function for table_age --------------------------------------------

table_age <- function(cohort, ages = "18;40;60;80", preex = "All") {
  if (preex == "All" | preex == "") {
    preex_str <- ""
  } else {
    preex_str <- paste0("-preex_", preex)
  }
  splice(
    comment(glue("Generate table_age_cohort_{cohort}{preex_str}")),
    action(
      name = glue("table_age-cohort_{cohort}{preex_str}"),
      run = "r:v2 analysis/table_age/table_age.R",
      arguments = c(c(cohort), c(ages), c(preex)),
      needs = list("study_dates", glue("generate_input_{cohort}_clean")),
      moderately_sensitive = list(
        table_age = glue(
          "output/table_age/table_age-cohort_{cohort}{preex_str}.csv"
        ),
        table_age_midpoint6 = glue(
          "output/table_age/table_age-cohort_{cohort}{preex_str}-midpoint6.csv"
        )
      )
    )
  )
}


# Create function for making combined table/venn outputs ------------------------

make_other_output <- function(action_name, cohort, subgroup = "") {
  cohort_names <- stringr::str_split(as.vector(cohort), ";")[[1]]
  if (grepl("_noday0", subgroup)) {
    noday0_str <- "_noday0"
    subgroup <- gsub("_noday0", "", subgroup)
  } else {
    noday0_str <- ""
  }
  if (subgroup == "All" | subgroup == "") {
    sub_str <- ""
  } else if (subgroup == "main") {
    sub_str <- "-main"
  } else {
    if (grepl("preex", subgroup)) {
      sub_str <- paste0("-", subgroup)
    } else {
      sub_str <- paste0("-sub_", subgroup)
    }
  }

  splice(
    comment(glue("Generate make-{action_name}{sub_str}{noday0_str}-output")),
    action(
      name = glue("make-{action_name}{sub_str}{noday0_str}-output"),
      run = "r:v2 analysis/make_output/make_other_output.R",
      arguments = unlist(lapply(
        list(
          c(action_name, cohort, paste0(subgroup, noday0_str))
        ),
        function(x) {
          x[x != ""]
        }
      )),
      needs = c(as.list(paste0(
        ifelse(
          action_name == "flow",
          "generate_input_",
          paste0(action_name, "-cohort_")
        ),
        cohort_names,
        ifelse(action_name == "flow", "_clean", paste0(sub_str, noday0_str))
      ))),
      moderately_sensitive = setNames(
        list(glue(
          "output/make_output/{action_name}{sub_str}{noday0_str}_output_midpoint6.csv"
        )),
        glue("{action_name}{noday0_str}_output_midpoint6")
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
    run = "r:v2 analysis/study_dates.R",
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

  ## Generate RSD study population --------------------------------------------

  splice(
    unlist(
      lapply(cohorts, function(x) generate_rsd_cohort(cohort = x)),
      recursive = FALSE
    )
  ),

  ## Run code diagnostics a particular outcome ---------------------------------

  # All RSD outcomes in core dataset
  splice(
    check_outcome(outcome = "rsd", cohort = paste0(cohorts, collapse = ";"))
  ),
  check_outcome(outcome = "rsd", cohort = "prevax"),

  # All RSD outcomes in rsd dataset
  splice(
    check_outcome(
      outcome = "rsd",
      cohort = paste0(cohorts, collapse = ";"),
      dd_group = "rsd"
    )
  ),
  check_outcome(outcome = "rsd", cohort = "prevax", dd_group = "rsd"),

  ## Clean data -----------------------------------------------------------

  splice(
    unlist(
      lapply(cohorts, function(x) clean_data(cohort = x, describe = describe)),
      recursive = FALSE
    )
  ),

  ## Table Age -------------------------------------------------------------------

  splice(
    unlist(
      lapply(
        unique(active_analyses$cohort),
        function(x) {
          table_age(cohort = x, ages = "40;45;50;55;60;65", preex = "")
        }
      ),
      recursive = FALSE
    )
  ),

  splice(
    make_other_output(
      action_name = "table_age",
      cohort = paste0(cohorts, collapse = ";"),
      subgroup = ""
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
  writeLines("analysis/archive/project_archive.yaml")

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
