import operator
from ehrql import case, when
from functools import reduce # for function building, e.g. any_of
from ehrql.tables.tpp import (
    addresses,
    apcs, 
    clinical_events, 
    emergency_care_attendances,
    ethnicity_from_sus,
    medications, 
    ons_deaths,
)

def ever_matching_event_clinical_ctv3_before(codelist, start_date, where=True):
    return(
        clinical_events.where(where)
        .where(clinical_events.ctv3_code.is_in(codelist))
        .where(clinical_events.date.is_before(start_date))
    )

def last_matching_event_clinical_ctv3_before(codelist, start_date, where=True):
    return(
        clinical_events.where(where)
        .where(clinical_events.ctv3_code.is_in(codelist))
        .where(clinical_events.date.is_before(start_date))
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

def last_matching_event_clinical_snomed_before(codelist, start_date, where=True):
    return(
        clinical_events.where(where)
        .where(clinical_events.snomedct_code.is_in(codelist))
        .where(clinical_events.date.is_before(start_date))
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

def last_matching_med_dmd_before(codelist, start_date, where=True):
    return(
        medications.where(where)
        .where(medications.dmd_code.is_in(codelist))
        .where(medications.date.is_before(start_date))
        .sort_by(medications.date)
        .last_for_patient()
    )

def last_matching_event_apc_before(codelist, start_date, only_prim_diagnoses=False, where=True):
    query = apcs.where(where).where(apcs.admission_date.is_before(start_date))
    if only_prim_diagnoses:
        query = query.where(
            apcs.primary_diagnosis.is_in(codelist)
        )
    else:
        query = query.where(apcs.all_diagnoses.contains_any_of(codelist))
    return query.sort_by(apcs.admission_date).last_for_patient()

# helper function
def any_of(conditions):
    return reduce(operator.or_, conditions)

def last_matching_event_ec_snomed_before(codelist, start_date, where=True):
    conditions = [
        getattr(emergency_care_attendances, column_name).is_in(codelist)
        for column_name in ([f"diagnosis_{i:02d}" for i in range(1, 25)])
    ]
    return(
        emergency_care_attendances.where(where)
        .where(any_of(conditions))
        .where(emergency_care_attendances.arrival_date.is_before(start_date))
        .sort_by(emergency_care_attendances.arrival_date)
        .last_for_patient()
    )

def matching_death_before(codelist, start_date, where=True):
    return(
        ons_deaths.cause_of_death_is_in(codelist)  & ons_deaths.date.is_before(start_date)
    )

def last_matching_event_clinical_snomed_between(codelist, start_date, end_date, where=True):
    return(
        clinical_events.where(where)
        .where(clinical_events.snomedct_code.is_in(codelist))
        .where(clinical_events.date.is_on_or_between(start_date, end_date))
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

def last_matching_med_dmd_between(codelist, start_date, end_date, where=True):
    return(
        medications.where(where)
        .where(medications.dmd_code.is_in(codelist))
        .where(medications.date.is_on_or_between(start_date, end_date))
        .sort_by(medications.date)
        .last_for_patient()
    )

def first_matching_event_clinical_ctv3_between(codelist, start_date, end_date, where=True):
    return(
        clinical_events.where(where)
        .where(clinical_events.ctv3_code.is_in(codelist))
        .where(clinical_events.date.is_on_or_between(start_date, end_date))
        .sort_by(clinical_events.date)
        .first_for_patient()
    )

def first_matching_event_clinical_snomed_between(codelist, start_date, end_date, where=True):
    return(
        clinical_events.where(where)
        .where(clinical_events.snomedct_code.is_in(codelist))
        .where(clinical_events.date.is_on_or_between(start_date, end_date))
        .sort_by(clinical_events.date)
        .first_for_patient()
    )

def first_matching_med_dmd_between(codelist, start_date, end_date, where=True):
    return(
        medications.where(where)
        .where(medications.dmd_code.is_in(codelist))
        .where(medications.date.is_on_or_between(start_date, end_date))
        .sort_by(medications.date)
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

def first_matching_event_ec_snomed_between(codelist, start_date, end_date, where=True):
    conditions = [
        getattr(emergency_care_attendances, column_name).is_in(codelist)
        for column_name in ([f"diagnosis_{i:02d}" for i in range(1, 25)])
    ]
    return(
        emergency_care_attendances.where(where)
        .where(any_of(conditions))
        .where(emergency_care_attendances.arrival_date.is_on_or_between(start_date, end_date))
        .sort_by(emergency_care_attendances.arrival_date)
        .first_for_patient()
    )

def matching_death_between(codelist, start_date, end_date, where=True):
    return(
        ons_deaths.cause_of_death_is_in(codelist) & ons_deaths.date.is_on_or_between(start_date, end_date)
    )

def get_latest_ethnicity(
        index_date, codelist, grouping=6
    ):
        latest_ethnicity_from_codes_category_num = (
            clinical_events.where(clinical_events.snomedct_code.is_in(codelist))
            .where(clinical_events.date.is_on_or_before(index_date))
            .sort_by(clinical_events.date)
            .last_for_patient()
            .snomedct_code.to_category(codelist)
        )

        if grouping == 6:
            latest_ethnicity_from_codes = case(
                when(latest_ethnicity_from_codes_category_num == "1").then("White"),
                when(latest_ethnicity_from_codes_category_num == "2").then("Mixed"),
                when(latest_ethnicity_from_codes_category_num == "3").then("Asian"), # Asian or Asian British
                when(latest_ethnicity_from_codes_category_num == "4").then("Black"), # Black or Black British
                when(latest_ethnicity_from_codes_category_num == "5").then("Other"), # Chinese or Other Ethnic group
            )

            ethnicity_sus = case(
                when(ethnicity_from_sus.code.is_in(["A", "B", "C"])).then("White"),
                when(ethnicity_from_sus.code.is_in(["D", "E", "F", "G"])).then("Mixed"),
                when(ethnicity_from_sus.code.is_in(["H", "J", "K", "L"])).then("Asian"),
                when(ethnicity_from_sus.code.is_in(["M", "N", "P"])).then("Black"),
                when(ethnicity_from_sus.code.is_in(["R", "S"])).then("Other"),
            )
        elif grouping == 16:
            latest_ethnicity_from_codes = case(
                when(latest_ethnicity_from_codes_category_num == "1").then("White British"),
                when(latest_ethnicity_from_codes_category_num == "2").then("White Irish"),
                when(latest_ethnicity_from_codes_category_num == "3").then("Other White"),
                when(latest_ethnicity_from_codes_category_num == "4").then("White and Caribbean"),
                when(latest_ethnicity_from_codes_category_num == "5").then("White and African"),
                when(latest_ethnicity_from_codes_category_num == "6").then("White and Asian"),
                when(latest_ethnicity_from_codes_category_num == "7").then("Other Mixed"),
                when(latest_ethnicity_from_codes_category_num == "8").then("Indian"),
                when(latest_ethnicity_from_codes_category_num == "9").then("Pakistani"),
                when(latest_ethnicity_from_codes_category_num == "10").then("Bangladeshi"),
                when(latest_ethnicity_from_codes_category_num == "11").then("Other Asian"),
                when(latest_ethnicity_from_codes_category_num == "12").then("Caribbean"),
                when(latest_ethnicity_from_codes_category_num == "13").then("African"),
                when(latest_ethnicity_from_codes_category_num == "14").then("Other Black"),
                when(latest_ethnicity_from_codes_category_num == "15").then("Chinese"),
                when(latest_ethnicity_from_codes_category_num == "16").then("All other ethnic groups"),
            )

            ethnicity_sus = case(
                when(ethnicity_from_sus.code == "A").then("White British"),
                when(ethnicity_from_sus.code == "B").then("White Irish"),
                when(ethnicity_from_sus.code == "C").then("Other White"),
                when(ethnicity_from_sus.code == "D").then("White and Caribbean"),
                when(ethnicity_from_sus.code == "E").then("White and African"),
                when(ethnicity_from_sus.code == "F").then("White and Asian"),
                when(ethnicity_from_sus.code == "G").then("Other Mixed"),
                when(ethnicity_from_sus.code == "H").then("Indian"),
                when(ethnicity_from_sus.code == "J").then("Pakistani"),
                when(ethnicity_from_sus.code == "K").then("Bangladeshi"),
                when(ethnicity_from_sus.code == "L").then("Other Asian"),
                when(ethnicity_from_sus.code == "M").then("Caribbean"),
                when(ethnicity_from_sus.code == "N").then("African"),
                when(ethnicity_from_sus.code == "P").then("Other Black"),
                when(ethnicity_from_sus.code == "R").then("Chinese"),
                when(ethnicity_from_sus.code == "S").then("All other ethnic groups"),
            )

        ethnicity_combined = case(
            when(latest_ethnicity_from_codes.is_not_null()).then(
                latest_ethnicity_from_codes
            ),
            when(
                latest_ethnicity_from_codes.is_null() & ethnicity_sus.is_not_null()
            ).then(ethnicity_sus),
            otherwise="Missing",
        )

        return ethnicity_combined
      
def get_imd(index_date, groups=5, max_imd=32844):
    step = max_imd / groups
    whens = []

    imd = addresses.for_patient_on(index_date).imd_rounded

    for i in range(groups):
        lower = int(step * i)
        upper = int(step * (i + 1))

        if i == 0:
            label = "1 (most deprived)"
        elif i == groups - 1:
            label = f"{groups} (least deprived)"
        else:
            label = str(i + 1)

        condition = (imd >= lower) & (imd < upper)
        whens.append(when(condition).then(label))

    imd_grouped=case(
        *whens,
        otherwise="unknown",
    )

    return imd_grouped

# filter a codelist based on whether its values included a specified set of allowed values (include)
def filter_codes_by_category(codelist, include):
    return {k:v for k,v in codelist.items() if v in include}
