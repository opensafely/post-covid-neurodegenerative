
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
    ref_cev = "2021-01-18", # reference date for calculating eligibility for phase 1 group 4 (CEV)
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

# create jcvi_groups ----
jcvi_groups <- 
tribble(
    ~group, ~definition,
    "01", "longres_group AND vax_jcvi_age_1 > 65",
    "02", "vax_jcvi_age_1 >=80",
    "03", "vax_jcvi_age_1 >=75",
    "04", "vax_jcvi_age_1 >=70 OR (cev_group AND vax_jcvi_age_1 >=16 AND NOT preg_group)",
    "05", "vax_jcvi_age_1 >=65",
    "06", "atrisk_group AND vax_jcvi_age_1 >=16",
    "07", "vax_jcvi_age_1 >=60",
    "08", "vax_jcvi_age_1 >=55",
    "09", "vax_jcvi_age_1 >=50",
    "10", "vax_jcvi_age_2 >=40",
    "11", "vax_jcvi_age_2 >=30",
    "12", "vax_jcvi_age_2 >=18",
    "99", "DEFAULT",
)

readr::write_csv(jcvi_groups,here::here( "output","vax_jcvi_groups.csv"))

# create elig_dates ----
elig_dates <-
tribble(
    ~date, ~description, ~jcvi_groups,
    "2020-12-08", "vax_cat_jcvi_group='01' OR vax_cat_jcvi_group='02'", "01, 02",
    "2021-01-18", "vax_cat_jcvi_group='03' OR vax_cat_jcvi_group='04'", "03, 04",
    ###
    "2021-02-15", "vax_cat_jcvi_group='05' OR vax_cat_jcvi_group='06'", "05, 06",
    ###
    "2021-02-22", "vax_jcvi_age_1 >= 64 AND vax_jcvi_age_1 < 65", "07", 
    "2021-03-01", "vax_jcvi_age_1 >= 60 AND vax_jcvi_age_1 < 64", "07",
    ###
    "2021-03-08", "vax_jcvi_age_1 >= 56 AND vax_jcvi_age_1 < 60", "08",
    "2021-03-09", "vax_jcvi_age_1 >= 55 AND vax_jcvi_age_1 < 56", "08",
    ###
    "2021-03-19", "vax_jcvi_age_1 >= 50 AND vax_jcvi_age_1 < 55", "09",
    ###
    "2021-04-13", "vax_jcvi_age_2 >= 45 AND vax_jcvi_age_1 < 50", "10",
    "2021-04-26", "vax_jcvi_age_2 >= 44 AND vax_jcvi_age_1 < 45", "10",
    "2021-04-27", "vax_jcvi_age_2 >= 42 AND vax_jcvi_age_1 < 44", "10",
    "2021-04-30", "vax_jcvi_age_2 >= 40 AND vax_jcvi_age_1 < 42", "10",
    ###
    "2021-05-13", "vax_jcvi_age_2 >= 38 AND vax_jcvi_age_2 < 40", "11",
    "2021-05-19", "vax_jcvi_age_2 >= 36 AND vax_jcvi_age_2 < 38", "11",
    "2021-05-21", "vax_jcvi_age_2 >= 34 AND vax_jcvi_age_2 < 36", "11",
    "2021-05-25", "vax_jcvi_age_2 >= 32 AND vax_jcvi_age_2 < 34", "11",
    "2021-05-26", "vax_jcvi_age_2 >= 30 AND vax_jcvi_age_2 < 32", "11",
    ###
    "2021-06-08", "vax_jcvi_age_2 >= 25 AND vax_jcvi_age_2 < 30", "12",
    "2021-06-15", "vax_jcvi_age_2 >= 23 AND vax_jcvi_age_2 < 25", "12",
    "2021-06-16", "vax_jcvi_age_2 >= 21 AND vax_jcvi_age_2 < 23", "12",
    "2021-06-18", "vax_jcvi_age_2 >= 18 AND vax_jcvi_age_2 < 21", "12",
    "2100-12-31", "DEFAULT", "NA",
)

readr::write_csv(elig_dates, here::here("output","vax_eligible_dates.csv"))