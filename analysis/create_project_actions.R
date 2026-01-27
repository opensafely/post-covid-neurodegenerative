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
analyses <- unique(grep("^main", active_analyses$analysis, value = TRUE))
subgroups <- unique(str_extract(active_analyses$analysis, "^main|sub_[^_]+"))
subgroups_noday0 <- paste0(subgroups, "_noday0")
subgroups_all <- c(subgroups, subgroups_noday0)
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

describe <- FALSE # This prints descriptive files for each dataset in the pipeline

# List of models excluded from model output generation

excluded_models <- c(
  "cohort_vax-sub_age_18_49-dem_lb",
  "cohort_unvax-sub_age_18_49-dem_lb",
  "cohort_prevax-sub_age_18_49-dem_lb",
  "cohort_vax-sub_age_18_49-dem_vasc",
  "cohort_unvax-sub_age_18_49-dem_vasc",
  "cohort_prevax-sub_age_18_49-dem_vasc",
  "cohort_vax-sub_age_18_49-dem_any",
  "cohort_unvax-sub_age_18_49-dem_any",
  "cohort_prevax-sub_age_18_49-dem_any",
  "cohort_vax-sub_age_18_49-dem_alz",
  "cohort_unvax-sub_age_18_49-dem_alz",
  "cohort_prevax-sub_age_18_49-dem_alz",
  "cohort_vax-sub_age_18_49-park",
  "cohort_unvax-sub_age_18_49-park",
  "cohort_prevax-sub_age_18_49-park",
  "cohort_vax-sub_age_18_49_noday0-dem_lb",
  "cohort_unvax-sub_age_18_49_noday0-dem_lb",
  "cohort_prevax-sub_age_18_49_noday0-dem_lb",
  "cohort_vax-sub_age_18_49_noday0-dem_vasc",
  "cohort_unvax-sub_age_18_49_noday0-dem_vasc",
  "cohort_prevax-sub_age_18_49_noday0-dem_vasc",
  "cohort_vax-sub_age_18_49_noday0-dem_any",
  "cohort_unvax-sub_age_18_49_noday0-dem_any",
  "cohort_prevax-sub_age_18_49_noday0-dem_any",
  "cohort_vax-sub_age_18_49_noday0-dem_alz",
  "cohort_unvax-sub_age_18_49_noday0-dem_alz",
  "cohort_prevax-sub_age_18_49_noday0-dem_alz",
  "cohort_vax-sub_age_18_49_noday0-park",
  "cohort_unvax-sub_age_18_49_noday0-park",
  "cohort_prevax-sub_age_18_49_noday0-park"
)

stata_models <- c(
  "cohort_prevax-main_noday0-migraine",
  "cohort_prevax-main_noday0-mnd",
  "cohort_unvax-main_noday0-dem_alz",
  "cohort_unvax-main_noday0-migraine",
  "cohort_unvax-main_noday0-rls",
  "cohort_prevax-sub_age_18_49_noday0-migraine",
  "cohort_prevax-sub_age_18_49_noday0-rls",
  "cohort_prevax-sub_age_50_64_noday0-dem_alz",
  "cohort_prevax-sub_age_50_64_noday0-dem_vasc",
  "cohort_prevax-sub_age_50_64_noday0-mnd",
  "cohort_prevax-sub_age_65_84_noday0-rls",
  "cohort_unvax-sub_age_18_49_noday0-migraine",
  "cohort_unvax-sub_age_18_49_noday0-rls",
  "cohort_unvax-sub_age_50_64_noday0-migraine",
  "cohort_unvax-sub_age_50_64_noday0-rsd",
  "cohort_vax-sub_age_18_49_noday0-migraine",
  "cohort_vax-sub_age_50_64_noday0-dem_alz",
  "cohort_vax-sub_age_50_64_noday0-dem_vasc",
  "cohort_vax-sub_age_50_64_noday0-park",
  "cohort_vax-sub_age_85_110_noday0-rsd",
  "cohort_unvax-sub_covidhistory_noday0-migraine",
  "cohort_vax-sub_covidhistory_noday0-dem_alz",
  "cohort_vax-sub_covidhistory_noday0-dem_vasc",
  "cohort_vax-sub_covidhistory_noday0-migraine",
  "cohort_prevax-sub_covidhospital_FALSE_noday0-migraine",
  "cohort_prevax-sub_covidhospital_TRUE_noday0-migraine",
  "cohort_prevax-sub_covidhospital_TRUE_noday0-ms",
  "cohort_prevax-sub_covidhospital_TRUE_noday0-rls",
  "cohort_prevax-sub_covidhospital_TRUE_noday0-rsd",
  "cohort_unvax-sub_covidhospital_FALSE_noday0-migraine",
  "cohort_unvax-sub_covidhospital_FALSE_noday0-rls",
  "cohort_unvax-sub_covidhospital_TRUE_noday0-dem_alz",
  "cohort_unvax-sub_covidhospital_TRUE_noday0-dem_any",
  "cohort_unvax-sub_covidhospital_TRUE_noday0-migraine",
  "cohort_unvax-sub_covidhospital_TRUE_noday0-rsd",
  "cohort_vax-sub_covidhospital_FALSE_noday0-mnd",
  "cohort_vax-sub_covidhospital_TRUE_noday0-migraine",
  "cohort_vax-sub_covidhospital_TRUE_noday0-ms",
  "cohort_vax-sub_covidhospital_TRUE_noday0-rsd",
  "cohort_prevax-sub_ethnicity_asian_noday0-dem_alz",
  "cohort_prevax-sub_ethnicity_asian_noday0-migraine",
  "cohort_prevax-sub_ethnicity_asian_noday0-rls",
  "cohort_prevax-sub_ethnicity_black_noday0-dem_any",
  "cohort_prevax-sub_ethnicity_black_noday0-migraine",
  "cohort_prevax-sub_ethnicity_mixed_noday0-migraine",
  "cohort_prevax-sub_ethnicity_mixed_noday0-rsd",
  "cohort_prevax-sub_ethnicity_other_noday0-dem_any",
  "cohort_prevax-sub_ethnicity_other_noday0-migraine",
  "cohort_unvax-sub_ethnicity_asian_noday0-migraine",
  "cohort_unvax-sub_ethnicity_black_noday0-migraine",
  "cohort_unvax-sub_ethnicity_mixed_noday0-migraine",
  "cohort_unvax-sub_ethnicity_white_noday0-dem_alz",
  "cohort_unvax-sub_ethnicity_white_noday0-migraine",
  "cohort_unvax-sub_ethnicity_white_noday0-rls",
  "cohort_vax-sub_ethnicity_asian_noday0-dem_any",
  "cohort_vax-sub_ethnicity_asian_noday0-migraine",
  "cohort_vax-sub_ethnicity_black_noday0-migraine",
  "cohort_vax-sub_ethnicity_mixed_noday0-migraine",
  "cohort_prevax-sub_highvascrisk_FALSE_noday0-dem_any",
  "cohort_prevax-sub_parkrisk_TRUE_noday0-park",
  "cohort_prevax-sub_sex_female_noday0-rls",
  "cohort_unvax-sub_sex_female_noday0-rls",
  "cohort_unvax-sub_sex_male_noday0-dem_any",
  "cohort_vax-sub_sex_male_noday0-mnd"
)

# These are currently based on manual check from outputs released on 2025-08-04, leave empty if no models need Stata
stata <- active_analyses[active_analyses$name %in% stata_models, ]

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

# Create function for table1 --------------------------------------------

table1 <- function(cohort, ages = "18;40;60;80", preex = "All") {
  if (preex == "All" | preex == "") {
    preex_str <- ""
  } else {
    preex_str <- paste0("-preex_", preex)
  }
  splice(
    comment(glue("Generate table1_cohort_{cohort}{preex_str}")),
    action(
      name = glue("table1-cohort_{cohort}{preex_str}"),
      run = "r:v2 analysis/table1/table1.R",
      arguments = c(c(cohort), c(ages), c(preex)),
      needs = list(glue("generate_input_{cohort}_clean")),
      moderately_sensitive = list(
        table1 = glue(
          "output/table1/table1-cohort_{cohort}{preex_str}.csv"
        ),
        table1_midpoint6 = glue(
          "output/table1/table1-cohort_{cohort}{preex_str}-midpoint6.csv"
        )
      )
    )
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
      run = glue("r:v2 analysis/model/make_model_input.R {name}"),
      needs = as.list(glue("generate_input_{cohort}_clean")),
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

# Create function to make Stata models -----------------------------------------

apply_stata_model_function <- function(
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
      name = glue("ready-{name}"),
      run = glue(
        "cox-ipw:v0.0.37 --df_input=model/model_input-{name}.rds --ipw={ipw} --exposure=exp_date --outcome=out_date --strata={strata} --covariate_sex={covariate_sex} --covariate_age={covariate_age} --covariate_other={covariate_other} --cox_start={cox_start} --cox_stop={cox_stop} --study_start={study_start} --study_stop={study_stop} --cut_points={cut_points} --controls_per_case={controls_per_case} --total_event_threshold={total_event_threshold} --episode_event_threshold={episode_event_threshold} --covariate_threshold={covariate_threshold} --age_spline={age_spline} --save_analysis_ready=model/ready-{name}.dta --run_analysis=FALSE --df_output=model/model_output-{name}.csv"
      ),
      needs = list(glue("make_model_input-{name}")),
      highly_sensitive = list(ready = glue("output/model/ready-{name}.dta"))
    ),
    action(
      name = glue("stata_cox_ipw-{name}"),
      run = "stata-mp:latest analysis/model/cox_model.do",
      arguments = c(name, cut_points, study_start),
      needs = c(as.list(glue("ready-{name}"))),
      moderately_sensitive = list(
        model_output = glue("output/model/stata_model_output-{name}.csv")
      )
    )
  )
}

# Create function to make Table 2 ----------------------------------------------

table2 <- function(cohort, subgroup) {
  if (grepl("_noday0", subgroup)) {
    noday0_str <- "_noday0"
    noday0_flag <- TRUE
    subgroup <- gsub("_noday0", "", subgroup)
  } else {
    noday0_str <- ""
    noday0_flag <- FALSE
  }
  if (subgroup == "All" | subgroup == "") {
    sub_str <- ""
  } else {
    if (grepl("preex", subgroup)) {
      sub_str <- paste0("-", subgroup)
    } else {
      sub_str <- paste0("-sub_", subgroup)
    }
  }

  table2_names <- gsub(
    "out_date_",
    "",
    unique(
      active_analyses[
        active_analyses$cohort ==
          {
            cohort
          },
      ]$name
    )
  )

  table2_names <- table2_names[
    (grepl("-main", table2_names) |
      grepl(paste0("-sub_", subgroup), table2_names)) &
      grepl("_noday0", table2_names) == noday0_flag
  ]

  splice(
    comment(glue("Generate table2-cohort_{cohort}-sub_{subgroup}{noday0_str}")),
    action(
      name = glue("table2-cohort_{cohort}-sub_{subgroup}{noday0_str}"),
      run = "r:v2 analysis/table2/table2.R",
      arguments = c(cohort, paste0(subgroup, noday0_str)),
      needs = c(as.list(paste0("make_model_input-", table2_names))),
      moderately_sensitive = list(
        table2 = glue(
          "output/table2/table2-cohort_{cohort}-sub_{subgroup}{noday0_str}.csv"
        ),
        table2_midpoint6 = glue(
          "output/table2/table2-cohort_{cohort}-sub_{subgroup}{noday0_str}-midpoint6.csv"
        )
      )
    )
  )
}

# Create function to make Venn data --------------------------------------------

venn <- function(cohort, analyses = "") {
  if (grepl("_noday0", analyses)) {
    noday0_str <- "_noday0"
    noday0_flag <- TRUE
    analyses <- gsub("_noday0", "", analyses)
  } else {
    noday0_str <- ""
    noday0_flag <- FALSE
  }

  if (analyses == "") {
    analyses_str <- ""
    analyses <- "main"
    analyses_input <- ""
  } else {
    analyses_str <- paste0("-", analyses)
    analyses_input <- analyses
  }

  venn_outcomes <- gsub(
    "cohort_",
    "",
    unique(
      active_analyses[
        active_analyses$cohort == cohort &
          grepl(analyses, active_analyses$analysis) &
          grepl("_noday0", active_analyses$analysis) == noday0_flag,
      ]$name
    )
  )

  splice(
    comment(glue("Generate venn-cohort_{cohort}{analyses_str}{noday0_str}")),
    action(
      name = glue("venn-cohort_{cohort}{analyses_str}{noday0_str}"),
      run = "r:v2 analysis/venn/venn.R",
      arguments = unlist(lapply(
        list(c(cohort, paste0(analyses_input, noday0_str))),
        function(x) {
          x[x != ""]
        }
      )),
      needs = c(
        as.list(glue("generate_input_{cohort}_clean")),
        as.list(paste0(
          glue("make_model_input-cohort_"),
          venn_outcomes
        ))
      ),
      moderately_sensitive = list(
        venn = glue(
          "output/venn/venn-cohort_{cohort}{analyses_str}{noday0_str}.csv"
        ),
        venn_midpoint6 = glue(
          "output/venn/venn-cohort_{cohort}{analyses_str}{noday0_str}-midpoint6.csv"
        )
      )
    )
  )
}

# Create function for making model outputs --------------------------------------

make_model_output <- function(subgroup) {
  if (grepl("_noday0", subgroup)) {
    noday0_str <- "_noday0"
    subgroup <- gsub("_noday0", "", subgroup)
    noday0_flag <- TRUE
  } else {
    noday0_str <- ""
    noday0_flag <- FALSE
  }

  splice(
    comment(glue("Generate model_output-{subgroup}{noday0_str}")),
    action(
      name = glue(
        "make_model_output-{subgroup}{noday0_str}"
      ),
      run = "r:v2 analysis/make_output/make_model_output.R",
      arguments = c(paste0(subgroup, noday0_str)),
      needs = as.list(c(
        paste0(
          "cox_ipw-",
          setdiff(
            active_analyses$name[
              str_detect(
                active_analyses$analysis,
                paste0(subgroup, "(?=[_-]|$)")
              ) &
                (grepl("_noday0", active_analyses$analysis) == noday0_flag)
            ],
            c(stata$name, excluded_models)
          )
        ),
        if (
          length(stata_models) > 0 &&
            any(
              str_detect(stata$analysis, subgroup) &
                (grepl("_noday0", stata$analysis) == noday0_flag)
            )
        ) {
          paste0(
            "stata_cox_ipw-",
            setdiff(
              stata$name[
                str_detect(stata$analysis, subgroup) &
                  (grepl("_noday0", stata$analysis) == noday0_flag)
              ],
              excluded_models
            )
          )
        } else {
          character(0)
        }
      )),
      moderately_sensitive = list(
        model_output = glue(
          "output/make_output/model_output-{subgroup}{noday0_str}.csv"
        ),
        model_output_midpoint6 = glue(
          "output/make_output/model_output-{subgroup}{noday0_str}-midpoint6.csv"
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

  ## Clean data -----------------------------------------------------------

  splice(
    unlist(
      lapply(cohorts, function(x) clean_data(cohort = x, describe = describe)),
      recursive = FALSE
    )
  ),

  ## Table 1 -------------------------------------------------------------------

  splice(
    unlist(
      lapply(
        unique(active_analyses$cohort),
        function(x) table1(cohort = x, ages = age_str, preex = "")
      ),
      recursive = FALSE
    )
  ),

  splice(
    make_other_output(
      action_name = "table1",
      cohort = paste0(cohorts, collapse = ";"),
      subgroup = ""
    )
  ),

  ## Run models ----------------------------------------------------------------
  comment("Run models"),

  splice(
    unlist(
      lapply(
        1:nrow(active_analyses),
        function(x) {
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
        }
      ),
      recursive = FALSE
    )
  ),

  # Stata models (only if stata_models not empty) ------------------------------
  if (length(stata_models) > 0) {
    splice(
      unlist(
        lapply(
          1:nrow(stata),
          function(x) {
            apply_stata_model_function(
              name = stata$name[x],
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
              age_spline = stata$age_spline[x]
            )
          }
        ),
        recursive = FALSE
      )
    )
  } else {
    list()
  },

  ## Flow ----------------------------------------------------------------------

  splice(
    make_other_output(
      action_name = "flow",
      cohort = paste0(cohorts, collapse = ";")
    )
  ),

  ## Table 2 -------------------------------------------------------------------

  splice(
    unlist(
      lapply(
        cohorts,
        function(x) table2(cohort = x, subgroup = "covidhospital")
      ),
      recursive = FALSE
    )
  ),

  splice(
    make_other_output(
      action_name = "table2",
      cohort = paste0(cohorts, collapse = ";"),
      subgroup = "covidhospital"
    )
  ),

  splice(
    unlist(
      lapply(
        cohorts,
        function(x) table2(cohort = x, subgroup = "covidhospital_noday0")
      ),
      recursive = FALSE
    )
  ),

  splice(
    make_other_output(
      action_name = "table2",
      cohort = paste0(cohorts, collapse = ";"),
      subgroup = "covidhospital_noday0"
    )
  ),

  ## Venn data -----------------------------------------------------------------

  splice(
    unlist(
      lapply(
        unique(active_analyses$cohort),
        function(x) venn(cohort = x)
      ),
      recursive = FALSE
    )
  ),

  splice(
    make_other_output(
      action_name = "venn",
      cohort = paste0(cohorts, collapse = ";"),
      subgroup = ""
    )
  ),

  splice(
    unlist(
      lapply(
        unique(active_analyses$cohort),
        function(x) venn(cohort = x, analyses = "_noday0")
      ),
      recursive = FALSE
    )
  ),

  splice(
    make_other_output(
      action_name = "venn",
      cohort = paste0(cohorts, collapse = ";"),
      subgroup = "_noday0"
    )
  ),

  ## Model output --------------------------------------------------------------

  splice(
    unlist(
      lapply(subgroups_all, function(x) make_model_output(subgroup = x)),
      recursive = FALSE
    )
  ),

  ## Make absolute excess risk (AER) input -------------------------------------

  comment("Make absolute excess risk (AER) input"),

  action(
    name = "make_aer_input_noday0",
    run = "r:v2 analysis/make_output/make_aer_input.R main_noday0",
    needs = as.list(paste0(
      "make_model_input-",
      active_analyses[
        grepl("main_noday0", active_analyses$analysis),
      ]$name
    )),
    moderately_sensitive = list(
      aer_input = glue("output/make_output/aer_input-main_noday0.csv"),
      aer_input_midpoint6 = glue(
        "output/make_output/aer_input-main_noday0-midpoint6.csv"
      )
    )
  ),

  action(
    name = "make_aer_input",
    run = "r:v2 analysis/make_output/make_aer_input.R main",
    needs = as.list(paste0(
      "make_model_input-",
      active_analyses[
        "main" == active_analyses$analysis,
      ]$name
    )),
    moderately_sensitive = list(
      aer_input = glue("output/make_output/aer_input-main.csv"),
      aer_input_midpoint6 = glue(
        "output/make_output/aer_input-main-midpoint6.csv"
      )
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
