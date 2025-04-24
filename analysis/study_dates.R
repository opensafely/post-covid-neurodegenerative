# Import libraries ----
print("Import libraries")

library('tidyverse')
library('here')

# Create output/dataset_definition directory ----
print("Create output/dataset_definition directory")

fs::dir_create(here::here("output/dataset_definition"))

# create study_dates ----
print("Create study_dates")

study_dates <-
  list(
    earliest_expec = "1900-01-01", # earliest date limit for project
    ref_age_1 = "2021-03-31", # reference date for calculating age for phase 1 JCVI groups
    ref_age_2 = "2021-07-01", # reference date for calculating age forfor phase 2 JCVI groups
    ref_cev = "2021-01-18", # reference date for calculating eligibility for phase 1 JCVI group 4 (CEV: clinically extremely vulnerable group)
    ref_ar = "2021-02-15", # reference date for calculating eligibility for phase 1 JCVI group 5 (at-risk)
    pandemic_start = "2020-01-01", # start date for pandemic in UK
    mixed_vax_threshold = "2021-05-07", # date that courses of mixed vaccine products were permitted
    delta_date = "2021-06-01", # date that Delta variant became dominant in the UK
    omicron_date = "2021-12-14", # date that Omicron variant became dominant in the UK
    vax1_earliest = "2020-12-08", # earliest expectation date for 1st vaccination
    vax2_earliest = "2021-01-08", # earliest expectation date for 2nd vaccination
    vax3_earliest = "2021-02-08", # earliest expectation date for 3rd vaccination
    all_eligible = "2021-06-18", # date that all UK adults (18+) are eligible for vaccination
    lcd_date = "2024-04-30" # last collection date for linked data (APCS; ONS_Deaths; SGSS_*)
  )

# Save study_dates ----
print("Save study_dates")

jsonlite::write_json(
  study_dates,
  path = "output/study_dates.json",
  auto_unbox = TRUE,
  pretty = TRUE
)
