# First function to preprocess data

preprocess <- function(cohort, describe) {
  # Get column names ----
  print('Get column names')

  file_path <- paste0("output/dataset_definition/input_", cohort, ".csv.gz")
  all_cols <- fread(
    file_path,
    header = TRUE,
    sep = ",",
    nrows = 0,
    stringsAsFactors = FALSE
  ) %>%
    names()
  message("Column names found")
  print(all_cols)

  # Define column classes ----
  print('Define column classes')

  cat_cols <- c("patient_id", grep("_cat", all_cols, value = TRUE))
  bin_cols <- c(grep("_bin", all_cols, value = TRUE))
  num_cols <- c(
    grep("_num", all_cols, value = TRUE),
    grep("vax_jcvi_age_", all_cols, value = TRUE)
  )
  date_cols <- grep("_date", all_cols, value = TRUE)
  message("Column classes identified")

  col_classes <- setNames(
    c(
      rep("c", length(cat_cols)),
      rep("l", length(bin_cols)),
      rep("d", length(num_cols)),
      rep("D", length(date_cols))
    ),
    all_cols[match(c(cat_cols, bin_cols, num_cols, date_cols), all_cols)]
  )
  message("Column classes defined")

  # Load cohort dataset ----
  print('Load cohort dataset')

  input <- read_csv(file_path, col_types = col_classes)
  message(paste0(
    "Dataset has been read successfully with N = ",
    nrow(input),
    " rows"
  ))

  # Modify dummy data ----
  print('Modify dummy data')

  if (Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations")) {
    input <- modify_dummy(input, cohort)
  }

  # Format dataset columns ----
  print('Format dataset columns')

  input <- input %>%
    mutate(
      across(
        all_of(date_cols),
        ~ floor_date(as.Date(., format = "%Y-%m-%d"), unit = "days")
      ),
      across(contains('_birth_year'), ~ as.numeric(.)), #~ year(as.Date(., origin = "1970-01-01"))),
      across(all_of(num_cols), ~ as.numeric(.)),
      across(all_of(cat_cols), ~ as.character(.))
    )

  # Describe data ----
  print('Describe data')

  if (isTRUE(describe)) {
    describe_data(df = input, name = paste0(cohort, "_raw"))
  }

  # Remove records with missing patient id ----
  print('Remove records with missing patient id')

  input <- input[!is.na(input$patient_id), ]
  message("All records with valid patient IDs retained.")

  # Make Venn diagram input dataset ----
  print('Make Venn diagram input dataset')

  venn <- input %>%
    select(starts_with(c("patient_id", "tmp_out_date", "out_date")))

  # Restrict columns ----
  print('Restrict columns')

  input <- input %>%
    select(
      patient_id,
      starts_with("index_date"),
      starts_with("end_date_"),
      starts_with("sub_"), # Subgroups
      starts_with("exp_"), # Exposures
      starts_with("out_"), # Outcomes
      starts_with("cov_"), # Covariates
      starts_with("inex_"), # Inclusion/exclusion
      starts_with("cens_"), # Censor
      starts_with("qa_"), # Quality assurance
      starts_with("strat_"), # Strata
      starts_with("vax_date_"), # Vaccination dates and vax type
      starts_with("vax_cat_") # Vaccination products
    )

  # Describe files ----
  print('Describe files')

  if (isTRUE(describe)) {
    describe_data(df = venn, name = paste0(cohort, "_venn"))
    describe_data(df = input, name = paste0(cohort, "_preprocessed"))
  }

  # Return data ----
  print('Return data')

  return(list(venn = venn, input = input))
}