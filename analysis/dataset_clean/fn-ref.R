# Function to set reference levels for factors
ref <- function(input) {
  # Handle missing values in cov_cat_sex ---------------------------------------
  print('Handle missing values in cov_cat_sex')

  if ("cov_cat_sex" %in% names(input)) {
    input$cov_cat_sex <- ifelse(
      input$cov_cat_sex %in% c("male", "female"),
      input$cov_cat_sex,
      "missing"
    )
    if ("missing" %in% unique(input$cov_cat_sex)) {
      stop("cov_cat_sex contains missing values.")
    }
  }

  # Handle missing values in cov_cat_imd -------------------------------
  print('Handle missing values in cov_cat_imd')

  if ("cov_cat_imd" %in% names(input)) {
    input$cov_cat_imd <- ifelse(
      input$cov_cat_imd %in%
        c("1 (most deprived)", "2", "3", "4", "5 (least deprived)"),
      input$cov_cat_imd,
      "missing"
    )
    if ("missing" %in% unique(input$cov_cat_imd)) {
      stop("cov_cat_imd contains missing values.")
    }
  }

  # Handle missing values in cov_cat_ethnicity ---------------------------------
  print('Handle missing values in cov_cat_ethnicity')

  if ("cov_cat_ethnicity" %in% names(input)) {
    input$cov_cat_ethnicity <- ifelse(
      input$cov_cat_ethnicity %in% c("1", "2", "3", "4", "5"),
      input$cov_cat_ethnicity,
      "0"
    )
  }

  # Handle missing values in cov_cat_smoking -----------------------------------
  print('Handle missing values in cov_cat_smoking')

  if ("cov_cat_smoking" %in% names(input)) {
    input$cov_cat_smoking <- ifelse(
      input$cov_cat_smoking %in% c("E", "N", "S"),
      input$cov_cat_smoking,
      "M"
    )
  }

  # Recode missing values in binary variables as FALSE -------------------------
  print(' Recode missing values in binary variables as FALSE')

  input <- input %>%
    mutate(across(contains("_bin_"), ~ ifelse(. == TRUE, TRUE, FALSE))) %>%
    mutate(across(contains("_bin_"), ~ replace_na(., FALSE)))

  # Set reference levels for factors ---------------------------------------------
  print('Set reference levels for factors')

  cat_factors <- colnames(input)[grepl("_cat_", colnames(input))]
  input[, cat_factors] <- lapply(
    input[, cat_factors],
    function(x) factor(x, ordered = FALSE)
  )

  # Set reference level for variable: sub_cat_covidhospital -------------------
  print('Set reference level for variable: sub_cat_covidhospital')

  input$sub_cat_covidhospital <- ordered(
    input$sub_cat_covidhospital,
    levels = c("no_infection", "non_hospitalised", "hospitalised")
  )

  # Set reference level for variable: cov_cat_ethnicity --------------------------
  print('Set reference level for variable: cov_cat_ethnicity')

  levels(input$cov_cat_ethnicity) <- list(
    "Missing" = "0",
    "White" = "1",
    "Mixed" = "2",
    "South Asian" = "3",
    "Black" = "4",
    "Other" = "5"
  )
  input$cov_cat_ethnicity <- relevel(input$cov_cat_ethnicity, ref = "White")

  # Set reference level for variable: cov_cat_imd -------------------------------
  print('Set reference level for variable: cov_cat_imd')

  input$cov_cat_imd <- ordered(
    input$cov_cat_imd,
    levels = c("1 (most deprived)", "2", "3", "4", "5 (least deprived)")
  )

  # Set reference level for variable: strat_cat_region -----------------------------
  print('Set reference level for variable: strat_cat_region')

  input$strat_cat_region <- factor(
    input$strat_cat_region,
    levels = c(
      "East",
      "East Midlands",
      "London",
      "North East",
      "North West",
      "South East",
      "South West",
      "West Midlands",
      "Yorkshire and The Humber"
    )
  )
  input$strat_cat_region <- relevel(input$strat_cat_region, ref = "East")

  # Set reference level for variable: cov_cat_smoking ---------------------
  print('Set reference level for variable: cov_cat_smoking')

  levels(input$cov_cat_smoking) <- list(
    "Ever smoker" = "E",
    "Missing" = "M",
    "Never smoker" = "N",
    "Current smoker" = "S"
  )
  input$cov_cat_smoking <- ordered(
    input$cov_cat_smoking,
    levels = c("Never smoker", "Ever smoker", "Current smoker", "Missing")
  )

  # Set reference level for variable: cov_cat_sex --------------------------------
  print('Set reference level for variable: cov_cat_sex')

  levels(input$cov_cat_sex) <- list("Female" = "female", "Male" = "male")
  input$cov_cat_sex <- relevel(input$cov_cat_sex, ref = "Female")

  # Set reference level for variable: vax_cat_jcvi_group -------------------------
  print('Set reference level for variable: vax_cat_jcvi_group')

  input$vax_cat_jcvi_group <- ordered(
    input$vax_cat_jcvi_group,
    levels = c(
      "12",
      "11",
      "10",
      "09",
      "08",
      "07",
      "06",
      "05",
      "04",
      "03",
      "02",
      "01",
      "99"
    )
  )

  # Set reference level for binaries ---------------------------------------------
  print('Set reference level for binaries')

  bin_factors <- colnames(input)[grepl("cov_bin_", colnames(input))]
  input[, bin_factors] <- lapply(
    input[, bin_factors],
    function(x) factor(x, levels = c("FALSE", "TRUE"))
  )

  return(input)
}
