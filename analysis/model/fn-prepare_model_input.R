prepare_model_input <- function(name) {
  # Load active analyses ---------------------------------------------------------
  print("Load active analyses")

  active_analyses <- readr::read_rds("lib/active_analyses.rds")

  # Filter active_analyses to model inputs to be prepared ------------------------
  print("Filter active_analyses to model inputs to be prepared")

  active_analyses <- active_analyses[active_analyses$name == name, ]

  if (nrow(active_analyses) == 0) {
    stop(paste0("Input: ", name, " does not match any analyses"))
  }

  # Load data ------------------------------------------------------------------
  print(paste0("Load data for ", active_analyses$name))

  input <- dplyr::as_tibble(readr::read_rds(paste0(
    "output/dataset_clean/input_",
    active_analyses$cohort,
    "_clean.rds"
  )))

  # Restrict to required variables for dataset preparation ---------------------
  print("Restrict to required variables for dataset preparation")

  input <- input[, unique(c(
    "patient_id",
    "index_date",
    "end_date_exposure",
    "end_date_outcome",
    active_analyses$exposure,
    active_analyses$outcome,
    active_analyses$strata,
    active_analyses$covariate_age,
    "cov_cat_sex",
    "cov_cat_ethnicity",
    unlist(strsplit(covariate_other, split = ";")),
    c(grep("sub_", colnames(input), value = TRUE)) #sub_cat_covidhospital, sub_cat_covidhistory, and other subgroups
  ))]

  # Identify final list of variables to keep -----------------------------------
  print("Identify final list of variables to keep")

  keep <- c(
    "patient_id",
    "index_date",
    "end_date_exposure",
    "end_date_outcome",
    "exp_date",
    "out_date"
  )
  varlists <- c("strata", "covariate_age", "covariate_sex", "covariate_other")
  for (j in varlists) {
    if (active_analyses[, j] != "NULL") {
      keep <- c(
        keep,
        stringr::str_split(as.vector(active_analyses[, j]), ";")[[1]]
      )
    }
  }

  # Remove outcomes outside of follow-up time ----------------------------------
  print("Remove outcomes outside of follow-up time")

  input <- dplyr::rename(
    input,
    "out_date" = active_analyses$outcome,
    "exp_date" = active_analyses$exposure
  )

  input <- input %>%
    dplyr::mutate(
      out_date = replace(
        out_date,
        which(out_date > end_date_outcome | out_date < index_date),
        NA
      ),
      exp_date = replace(
        exp_date,
        which(exp_date > end_date_exposure | exp_date < index_date),
        NA
      ),
      sub_cat_covidhospital = replace(
        sub_cat_covidhospital,
        which(is.na(exp_date)),
        "no_infection"
      )
    )

  # Update end date to be outcome date where applicable ------------------------
  print("Update end date to be outcome date where applicable")

  input <- input %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      end_date_outcome = min(end_date_outcome, out_date, na.rm = TRUE)
    )

  return(list(input = input, keep = keep))
}
