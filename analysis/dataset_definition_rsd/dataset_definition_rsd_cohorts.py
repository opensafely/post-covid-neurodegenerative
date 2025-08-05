from ehrql import (
    create_dataset,
)
# Bring table definitions from the TPP backend 
from ehrql.tables.tpp import ( 
    patients, 
)

from ehrql.query_language import table_from_file, PatientFrame, Series

from datetime import date

# Create dataset

def generate_dataset_rsd(index_date, end_date_exp, end_date_out):
    dataset = create_dataset()
    
    dataset.define_population(
        patients.date_of_birth.is_not_null()
    )

# Configure dummy data

    dataset.configure_dummy_data(population_size=5000)

# Import variables function

    from variables_rsd import generate_rsd

    variables = generate_rsd(index_date, end_date_exp, end_date_out)

    # Assign each variable to the dataset

    for var_name, var_value in variables.items():
        setattr(dataset, var_name, var_value)

# Extract date variables for later pipelines

    @table_from_file("output/dataset_definition/index_dates.csv.gz")
    
    class index_dates(PatientFrame):
    # Vaccine category and eligibility variables
        vax_cat_jcvi_group = Series(str)
        vax_date_eligible = Series(date)

    # General COVID vaccination dates
        vax_date_covid_1 = Series(date)
        vax_date_covid_2 = Series(date)
        vax_date_covid_3 = Series(date)

    # Pfizer vaccine-specific dates
        vax_date_Pfizer_1 = Series(date)
        vax_date_Pfizer_2 = Series(date)
        vax_date_Pfizer_3 = Series(date)

    # AstraZeneca vaccine-specific dates
        vax_date_AstraZeneca_1 = Series(date)
        vax_date_AstraZeneca_2 = Series(date)
        vax_date_AstraZeneca_3 = Series(date)

    # Moderna vaccine-specific dates
        vax_date_Moderna_1 = Series(date)
        vax_date_Moderna_2 = Series(date)
        vax_date_Moderna_3 = Series(date)

    # Censoring date due to death
        cens_date_death = Series(date)

    # Mapping all variables from index_dates to the dataset
    dataset.vax_cat_jcvi_group = index_dates.vax_cat_jcvi_group
    dataset.vax_date_eligible = index_dates.vax_date_eligible
    dataset.vax_date_covid_1 = index_dates.vax_date_covid_1
    dataset.vax_date_covid_2 = index_dates.vax_date_covid_2
    dataset.vax_date_covid_3 = index_dates.vax_date_covid_3
    dataset.vax_date_Pfizer_1 = index_dates.vax_date_Pfizer_1
    dataset.vax_date_Pfizer_2 = index_dates.vax_date_Pfizer_2
    dataset.vax_date_Pfizer_3 = index_dates.vax_date_Pfizer_3
    dataset.vax_date_AstraZeneca_1 = index_dates.vax_date_AstraZeneca_1
    dataset.vax_date_AstraZeneca_2 = index_dates.vax_date_AstraZeneca_2
    dataset.vax_date_AstraZeneca_3 = index_dates.vax_date_AstraZeneca_3
    dataset.vax_date_Moderna_1 = index_dates.vax_date_Moderna_1
    dataset.vax_date_Moderna_2 = index_dates.vax_date_Moderna_2
    dataset.vax_date_Moderna_3 = index_dates.vax_date_Moderna_3
    dataset.cens_date_death = index_dates.cens_date_death

    return dataset
