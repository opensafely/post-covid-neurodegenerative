from dataset_definition_cohorts import generate_dataset

from ehrql.query_language import table_from_file, PatientFrame, Series

from datetime import date

# extract index dates for unvax cohort from index_dates.csv

@table_from_file("output/dataset_definition/index_dates.csv.gz")

class index_dates(PatientFrame):
    index_unvax = Series(date)
    end_unvax_exposure = Series(date)
    end_unvax_outcome = Series(date)

index_date = index_dates.index_unvax
end_date_exposure = index_dates.end_unvax_exposure
end_date_outcome = index_dates.end_unvax_outcome

# Create dataset

dataset = generate_dataset(index_date, end_date_exposure, end_date_outcome)

dataset.index_date = index_date
dataset.end_date_exposure = end_date_exposure
dataset.end_date_outcome = end_date_outcome