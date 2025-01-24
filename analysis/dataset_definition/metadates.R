# # # # # # # # # # # # # # # # # # # # #
# This script:
# creates metadata for aspects of the study design
# # # # # # # # # # # # # # # # # # # # #

# Import libraries ----
library('tidyverse')
library('here')

# create study_dates ----

study_dates <-
  list(
    earliest_expec = "1900-01-01",
    ref_age_1 = "2021-03-31", # reference date for calculating age for phase 1 groups
    ref_age_2 = "2021-07-01", # reference date for calculating age for phase 2 groups
    ref_cev = "2021-01-18", # reference date for calculating eligibility for phase 1 group 4 (CEV: clinically extremely vulnerable group)
    ref_ar = "2021-02-15", # reference date for calculating eligibility for phase 1 group 5 (at-risk)
    pandemic_start = "2020-01-01", # rough start date for pandemic in UK
    start_date = "2020-12-08", # start of phase 1 vaccinations
    start_date_pfizer = "2020-12-08",
    start_date_az = "2021-01-04",
    start_date_moderna = "2021-03-04",
    delta_date = "2021-06-01", 
    omicron_date = "2021-12-14",
    vax1_earliest = "2020-12-08", # earliest expectation date for first vaccination
    vax2_earliest = "2021-01-08", # earliest expectation date for 2nd vaccination
    vax3_earliest = "2021-02-08", # earliest expectation date for 3rd vaccination
    all_eligible = "2021-06-18", # all 18+ are eligible for vax on this date(protocol)
    end_date = "2021-09-15" # last date of available vaccination data. NEED TO ALSO CHECK END DATES FOR OTHER DATA SOURCES
  )

jsonlite::write_json(study_dates, path = "output/study_dates.json", auto_unbox = TRUE, pretty=TRUE)