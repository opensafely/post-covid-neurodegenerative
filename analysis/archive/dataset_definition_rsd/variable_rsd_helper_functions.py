import operator
from functools import reduce # for function building, e.g. any_of
from ehrql.tables.tpp import (
    apcs, 
    clinical_events, 
    medications, 
    ons_deaths,
    emergency_care_attendances,
)


# helper function
def any_of(conditions):
    return reduce(operator.or_, conditions)

def first_matching_event_clinical_snomed_between(codelist, start_date, end_date, where=True):
    return(
        clinical_events.where(where)
        .where(clinical_events.snomedct_code.is_in(codelist))
        .where(clinical_events.date.is_on_or_between(start_date, end_date))
        .sort_by(clinical_events.date)
        .first_for_patient()
    )

def first_matching_event_apc_between(codelist, start_date, end_date, only_prim_diagnoses=False, where=True):
    query = apcs.where(where).where(apcs.admission_date.is_on_or_between(start_date, end_date))
    if only_prim_diagnoses:
        query = query.where(
            apcs.primary_diagnosis.is_in(codelist)
        )
    else:
        query = query.where(apcs.all_diagnoses.contains_any_of(codelist))
    return query.sort_by(apcs.admission_date).first_for_patient()
  
def first_matching_event_clinical_ctv3_between(codelist, start_date, end_date, where=True):
    return(
        clinical_events.where(where)
        .where(clinical_events.ctv3_code.is_in(codelist))
        .where(clinical_events.date.is_on_or_between(start_date, end_date))
        .sort_by(clinical_events.date)
        .first_for_patient()
    )

def matching_death_between(codelist, start_date, end_date, where=True):
    return(
        ons_deaths.cause_of_death_is_in(codelist) & ons_deaths.date.is_on_or_between(start_date, end_date)
    )

# filter a codelist based on whether its values included a specified set of allowed values (include)
def filter_codes_by_category(codelist, include):
    return {k:v for k,v in codelist.items() if v in include}
