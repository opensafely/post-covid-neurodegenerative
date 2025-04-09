# Modified from https://github.com/opensafely/waning-ve-2dose-1year/blob/main/analysis/dummy_data_vax.R
# And https://github.com/opensafely/post-covid-vaccinated/blob/main/analysis/modify_dummy_vax_data.R

modify_dummy <- function(df, cohort) {
  # Set seed -------------------------------------------------------------------
  set.seed(1)

  pandemic_start <- as.Date(
    study_dates$pandemic_start,
    format = "%Y-%m-%d",
    origin = "1970-01-01"
  )

  # Modifying vax-specific variables

  if (cohort == "vax") {
    df <- df %>%

      # Change first jab date so that they have roughly correct distribution
      mutate(
        vax_date_Pfizer_1 = as.Date(vax_date_eligible) +
          days(round(rnorm(nrow(.), mean = 10, sd = 3))),
        vax_date_AstraZeneca_1 = as.Date(vax_date_eligible) +
          days(round(rnorm(nrow(.), mean = 10, sd = 3))),
        vax_date_Moderna_1 = as.Date(vax_date_eligible) +
          days(round(rnorm(nrow(.), mean = 10, sd = 3)))
      ) %>%

      #Pick one vaccine type
      mutate(
        vaccine_1_type = sample(
          x = c("Pfizer", "AstraZeneca", "Moderna", "None"),
          size = nrow(.),
          replace = TRUE,
          prob = c(0.4, 0.4, 0.05, 0.1)
        ),

        # jabs missingness probabilities
        missing_pfizer_2 = rbernoulli(nrow(.), p = 0.05),
        missing_az_2 = rbernoulli(nrow(.), p = 0.05),
        missing_moderna_2 = rbernoulli(nrow(.), p = 0.05),
        missing_pfizer_3 = rbernoulli(nrow(.), p = 0.90),
        missing_az_3 = rbernoulli(nrow(.), p = 0.90),
        missing_moderna_3 = rbernoulli(nrow(.), p = 0.90)
      ) %>%

      #Set first jab date according to type and set others to NA
      mutate(across(
        vax_date_Pfizer_1,
        ~ if_else(
          vaccine_1_type %in% "Pfizer",
          .x,
          NA_Date_
        )
      )) %>%
      mutate(across(
        vax_date_AstraZeneca_1,
        ~ if_else(
          vaccine_1_type %in% "AstraZeneca",
          .x,
          NA_Date_
        )
      )) %>%
      mutate(across(
        vax_date_Moderna_1,
        ~ if_else(
          vaccine_1_type %in% "Moderna",
          .x,
          NA_Date_
        )
      )) %>%

      mutate(across(
        matches("vax_date\\w+_1"),
        ~ if_else(
          vaccine_1_type %in% "None",
          NA_Date_,
          .x
        )
      )) %>%

      mutate(
        vax_date_covid_1 = pmin(
          vax_date_Pfizer_1,
          vax_date_AstraZeneca_1,
          vax_date_Moderna_1,
          na.rm = T
        )
      ) %>%

      #Change date for the second jab
      mutate(
        vax_date_Pfizer_2 = vax_date_Pfizer_1 +
          days(round(rnorm(nrow(.), mean = 10 * 7, sd = 3))),
        vax_date_AstraZeneca_2 = vax_date_AstraZeneca_1 +
          days(round(rnorm(nrow(.), mean = 10 * 7, sd = 3))),
        vax_date_Moderna_2 = vax_date_Moderna_1 +
          days(round(rnorm(nrow(.), mean = 10 * 7, sd = 3))),
      ) %>%

      # Set 2nd vaccine type
      mutate(
        vaccine_2_type = ifelse(
          runif(nrow(df), 0, 1) > 0.95 & vaccine_1_type != "None",
          sample(
            x = c("Pfizer", "AstraZeneca", "Moderna", "None"),
            size = nrow(.),
            replace = TRUE,
            prob = c(0.4, 0.4, 0.05, 0.1)
          ),
          vaccine_1_type
        )
      ) %>%

      #Set second jab date according to type and set others to NA
      mutate(across(
        vax_date_Pfizer_2,
        ~ if_else(
          vaccine_2_type %in% "Pfizer",
          .x,
          NA_Date_
        )
      )) %>%
      mutate(across(
        vax_date_AstraZeneca_2,
        ~ if_else(
          vaccine_2_type %in% "AstraZeneca",
          .x,
          NA_Date_
        )
      )) %>%
      mutate(across(
        vax_date_Moderna_2,
        ~ if_else(
          vaccine_2_type %in% "Moderna",
          .x,
          NA_Date_
        )
      )) %>%

      mutate(across(
        matches("vax_date\\w+_2"),
        ~ if_else(
          vaccine_2_type %in% "None",
          NA_Date_,
          .x
        )
      )) %>%

      # Set to NA if jab is missing
      mutate(across(
        vax_date_Pfizer_2,
        ~ if_else(
          missing_pfizer_2,
          NA_Date_,
          .x
        )
      )) %>%
      mutate(across(
        vax_date_AstraZeneca_2,
        ~ if_else(
          missing_az_2,
          NA_Date_,
          .x
        )
      )) %>%
      mutate(across(
        vax_date_Moderna_2,
        ~ if_else(
          missing_moderna_2,
          NA_Date_,
          .x
        )
      )) %>%

      mutate(
        vax_date_covid_2 = pmin(
          vax_date_Pfizer_2,
          vax_date_AstraZeneca_2,
          vax_date_Moderna_2,
          na.rm = T
        )
      ) %>%

      #Set 3rd jab type
      mutate(
        vaccine_3_type = ifelse(
          vaccine_2_type != "None",
          sample(
            x = c("Pfizer", "AstraZeneca", "Moderna", "None"),
            size = nrow(.),
            replace = TRUE,
            prob = c(0.6, 0.1, 0.3, 0.1)
          ),
          vaccine_2_type
        )
      ) %>%

      #Change 3rd jab date
      mutate(
        vax_date_Pfizer_3 = vax_date_Pfizer_2 +
          days(round(rnorm(nrow(.), mean = 6 * 4 * 7, sd = 7))),
        vax_date_AstraZeneca_3 = vax_date_AstraZeneca_2 +
          days(round(rnorm(nrow(.), mean = 6 * 4 * 7, sd = 7))),
        vax_date_Moderna_3 = vax_date_Moderna_2 +
          days(round(rnorm(nrow(.), mean = 6 * 4 * 7, sd = 7))),
      ) %>%

      #Set 3rd jab date according to type and set others to NA
      mutate(across(
        vax_date_Pfizer_3,
        ~ if_else(
          vaccine_3_type %in% "Pfizer",
          .x,
          NA_Date_
        )
      )) %>%
      mutate(across(
        vax_date_AstraZeneca_3,
        ~ if_else(
          vaccine_3_type %in% "AstraZeneca",
          .x,
          NA_Date_
        )
      )) %>%
      mutate(across(
        vax_date_Moderna_3,
        ~ if_else(
          vaccine_3_type %in% "Moderna",
          .x,
          NA_Date_
        )
      )) %>%

      mutate(across(
        matches("vax_date\\w+_3"),
        ~ if_else(
          vaccine_3_type %in% "None",
          NA_Date_,
          .x
        )
      )) %>%

      mutate(across(
        vax_date_covid_3,
        ~ if_else(
          vaccine_3_type %in% "None",
          NA_Date_,
          pmin(
            vax_date_Pfizer_3,
            vax_date_AstraZeneca_3,
            vax_date_Moderna_3,
            na.rm = T
          )
        )
      )) %>%

      # Set to NA if jab is missing
      mutate(across(
        vax_date_Pfizer_3,
        ~ if_else(
          missing_pfizer_3,
          NA_Date_,
          .x
        )
      )) %>%
      mutate(across(
        vax_date_AstraZeneca_3,
        ~ if_else(
          missing_az_3,
          NA_Date_,
          .x
        )
      )) %>%
      mutate(across(
        vax_date_Moderna_3,
        ~ if_else(
          missing_moderna_3,
          NA_Date_,
          .x
        )
      )) %>%

      mutate(
        vax_date_covid_3 = pmin(
          vax_date_Pfizer_3,
          vax_date_AstraZeneca_3,
          vax_date_Moderna_3,
          na.rm = T
        )
      ) %>%

      select(-starts_with("missing"), -matches("vaccine_\\d_type")) %>%

      ## Inclusion/Exclusion modifications

      # Inclusion criteria: Did not receive a vaccination prior to 08-12-2020 (i.e., the start of the vaccination
      mutate(across(
        vax_date_covid_1,
        ~ if_else(
          runif(n()) < 0.002,
          as.Date("01-12-2020"),
          .x
        )
      )) %>%

      # Inclusion criteria: Did not receive a second dose vaccination before their first dose vaccination
      mutate(across(
        vax_date_covid_1,
        ~ if_else(
          runif(n()) < 0.002,
          vax_date_covid_2 + 10,
          .x
        )
      )) %>%

      # Inclusion criteria: Did not receive a second dose vaccination less than three weeks after their first dose
      mutate(across(
        vax_date_covid_2,
        ~ if_else(
          runif(n()) < 0.002,
          vax_date_covid_1 + 15,
          .x
        )
      )) %>%

      # Inclusion criteria: Did not receive mixed vaccine products before 07-05-2021
      mutate(modify_mixed_vax = rbernoulli(nrow(.), p = 0.002)) %>%
      mutate(across(
        vax_date_Moderna_2,
        ~ if_else(
          modify_mixed_vax,
          mixed_vax_threshold - 2,
          .x
        )
      )) %>%
      mutate(across(
        vax_date_covid_2,
        ~ if_else(
          modify_mixed_vax,
          mixed_vax_threshold - 2,
          .x
        )
      ))

    # Inclusion criteria: Index date is before cohort end date
  } else if (cohort == "unvax") {
    # Modifying unvax-specific variables

    # Redistribute vax_date_covid_1 to increase earlier values
    print("Redistributing vax_date_covid_1 for unvax cohort")

    df <- df %>%
      mutate(
        vax_date_covid_1 = case_when(
          # Shift all dates after 2021-12-10 one year earlier
          vax_date_covid_1 > as.Date("2021-12-10") ~ vax_date_covid_1 - 360,

          # Boost early vaccine dates by randomly pulling some later values earlier
          TRUE ~ vax_date_covid_1
        )
      ) %>%

      ## JCVI distribution
      mutate(
        vax_cat_jcvi_group = sample(
          x = c(
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
          ), # 8.25 for each group, 1.6% for missing
          size = nrow(.),
          replace = TRUE,
          prob = c(
            rep(0.082, 12),
            0.016
          )
        )
      )
  }

  ## Modifying variables across cohorts ----------------------------------------

  df <- df %>%

    ## Alive on the index date
    mutate(inex_bin_alive = rbernoulli(nrow(.), p = 0.99)) %>%

    ## Registered for a minimum of 6 months prior to index date
    mutate(inex_bin_6m_reg = rbernoulli(nrow(.), p = 0.99)) %>%

    ## Age distribution
    mutate(
      cov_num_age = sample(
        c(
          sample(1:17, round(nrow(.) * 0.02), replace = TRUE), # Proportion <18
          sample(111:120, round(nrow(.) * 0.02), replace = TRUE), # Proportion >110
          sample(18:110, nrow(.) - round(nrow(.) * 0.02) * 2, replace = TRUE)
        )
      )
    ) %>%

    ## Recalculate birth year based on new age
    mutate(
      qa_num_birth_year = as.numeric(format(as.Date(index_date), "%Y")) -
        cov_num_age
    ) %>%

    ## Sex
    mutate(
      cov_cat_sex = sample(
        x = c("female", "male", "intersex", "unknown"),
        size = nrow(.),
        replace = TRUE,
        prob = c(0.49, 0.49, 0.01, 0.01) # %49% Female, 49% Male, 1% Intersex, 1% missing
      )
    ) %>%

    ## Region
    mutate(
      strat_cat_region = sample(
        x = c(
          "East",
          "East Midlands",
          "London",
          "North East",
          "North West",
          "South East",
          "South West",
          "West Midlands",
          "Yorkshire and The Humber",
          ""
        ),
        size = nrow(.),
        replace = TRUE,
        prob = c(rep(0.11, 9), 0.01) # 11% for each area, %1 Missing
      )
    ) %>%

    ## IMD
    mutate(
      cov_cat_imd = sample(
        x = c("1 (most deprived)", "2", "3", "4", "5 (least deprived)", NA),
        size = nrow(.),
        replace = TRUE,
        prob = c(rep(0.195, 5), 0.025) # 19.5% for each area, 2.5% missing
      )
    ) %>%

    ## Outcome dates
    mutate(across(
      starts_with("out_date_"),
      ~ as.Date(
        ifelse(
          runif(n()) < 0.15, # 15% for each outcome
          index_date +
            round(
              (lcd_date - index_date) * runif(n(), min = 0, max = 1)
            ),
          NA_Date_
        ),
        format = "%Y-%m-%d",
        origin = "1970-01-01"
      )
    )) %>%

    ## Exposure date
    mutate(across(
      exp_date_covid,
      ~ as.Date(
        ifelse(
          runif(n()) < 0.50, # 50% With COVID
          sample(
            seq(pandemic_start, lcd_date, by = "day"),
            n(),
            replace = TRUE
          ),
          NA_Date_
        ),
        format = "%Y-%m-%d",
        origin = "1970-01-01"
      )
    )) %>%

    ## Update Covid Hospital proportions
    mutate(
      sub_cat_covidhospital = sample(
        x = c("non_hospitalised", "hospitalised"),
        size = nrow(.),
        replace = TRUE,
        prob = rep(0.5, 2)
      )
    ) %>%

    mutate(across(
      sub_cat_covidhospital,
      ~ if_else(is.na(exp_date_covid), "no_infection", .x)
    )) %>%

    ## Prior Covid History
    mutate(sub_bin_covidhistory = rbernoulli(nrow(.), p = 0.05)) %>%

    # Quality assurance: Year of birth is missing
    mutate(across(
      qa_num_birth_year,
      ~ if_else(
        runif(n()) < 0.002,
        as.numeric(""),
        .x
      )
    )) %>%

    # Quality assurance: Year of birth is before year of death
    mutate(modify_birth_then = rbernoulli(nrow(.), p = 0.002)) %>%
    mutate(across(
      qa_num_birth_year,
      ~ if_else(
        modify_birth_then,
        2024,
        .x
      )
    )) %>%

    mutate(across(
      cens_date_death,
      ~ if_else(
        modify_birth_then,
        as.Date("2023-03-02"),
        .x
      )
    )) %>%

    # Quality assurance: Year of birth is before today
    mutate(across(
      qa_num_birth_year,
      ~ if_else(
        runif(n()) < 0.005,
        as.numeric(format(Sys.Date() + 1000, "%Y")),
        .x
      )
    )) %>%

    # Quality assurance: Date of death before today
    mutate(across(
      cens_date_death,
      ~ if_else(
        runif(n()) < 0.002,
        Sys.Date() + 42,
        .x
      )
    )) %>%

    # Quality assurance: Pregnancy/birth codes for men
    mutate(qa_bin_pregnancy = rbernoulli(nrow(.), p = 0.005)) %>%

    # Quality assurance: HRT or COCP meds for men
    mutate(qa_bin_hrtcocp = rbernoulli(nrow(.), p = 0.005)) %>%

    # Quality assurance: Prostate cancer codes for women
    mutate(qa_bin_prostate_cancer = rbernoulli(nrow(.), p = 0.005)) %>%

    # remove stray variables
    select(-starts_with("modify_"))
}
