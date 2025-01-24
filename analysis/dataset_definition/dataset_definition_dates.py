from ehrql import (
    create_dataset,
    days,
    minimum_of,
    maximum_of,
)

# Bring table definitions from the TPP backend 

from ehrql.tables.tpp import ( 
    patients, 
)

# create dataset to create dates for different cohorts

dataset = create_dataset()
dataset.define_population(
    patients.date_of_birth.is_not_null()
)
dataset.configure_dummy_data(population_size=1000)

# Import study_dates dictionary

from variables_dates import study_dates

# Extracting all variables from the study_dates dictionary

earliest_expec = study_dates["earliest_expec"]  # earliest expectation date for events
ref_age_1 = study_dates["ref_age_1"]  # reference date for calculating age for phase 1 groups
ref_age_2 = study_dates["ref_age_2"]  # reference date for calculating age for phase 2 groups
ref_cev = study_dates["ref_cev"]  # reference date for calculating eligibility for phase 1 group 4 (CEV)
ref_ar = study_dates["ref_ar"]  # reference date for calculating eligibility for phase 1 group 5 (at-risk)
pandemic_start = study_dates["pandemic_start"]  # rough start date for pandemic in UK
start_date = study_dates["start_date"]  # start of phase 1 vaccinations
start_date_pfizer = study_dates["start_date_pfizer"]
start_date_az = study_dates["start_date_az"]
start_date_moderna = study_dates["start_date_moderna"]
delta_date = study_dates["delta_date"]
omicron_date = study_dates["omicron_date"]
vax1_earliest = study_dates["vax1_earliest"]  # earliest expectation date for first vaccination
vax2_earliest = study_dates["vax2_earliest"]  # earliest expectation date for 2nd vaccination
vax3_earliest = study_dates["vax3_earliest"]  # earliest expectation date for 3rd vaccination
all_eligible = study_dates["all_eligible"]  # all 18+ are eligible for vax on this date (protocol)
end_date = study_dates["end_date"]  # last date of available vaccination data. NEED TO ALSO CHECK END DATES FOR OTHER DATA SOURCES

# Import preliminary date variables (death date, vax dates)

from variables_dates import prelim_date_variables

  ## Add the imported variables to the dataset

for var_name, var_value in prelim_date_variables.items():
    setattr(dataset, var_name, var_value)

# Import jcvi variables ( JCVI group and derived variables; eligible date for vaccination based on JCVI group)
from variables_dates import jcvi_variables

  ## Add the imported variables to the dataset
for var_name, var_value in jcvi_variables.items():
    setattr(dataset, var_name, var_value)

# Generate cohort dates

dataset.index_prevax = minimum_of(pandemic_start, pandemic_start)

dataset.end_prevax_exposure = minimum_of(
    dataset.cens_date_death, dataset.vax_date_covid_1, dataset.vax_date_eligible, all_eligible
)

dataset.end_prevax_outcome = minimum_of(
    dataset.cens_date_death, omicron_date
)

dataset.index_vax = maximum_of(
    dataset.vax_date_covid_2 + days(14),
    delta_date
)
dataset.end_vax_exposure = minimum_of(
    dataset.cens_date_death, omicron_date
)

dataset.end_vax_outcome = dataset.end_vax_exposure

dataset.index_unvax = maximum_of(
    dataset.vax_date_eligible + days(84),
    delta_date
)
dataset.end_unvax_exposure = minimum_of(
    dataset.cens_date_death, omicron_date, dataset.vax_date_covid_1
)
dataset.end_unvax_outcome = minimum_of(
    dataset.cens_date_death, omicron_date
)