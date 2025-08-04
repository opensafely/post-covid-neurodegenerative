# Setup
from ehrql import codelist_from_csv



# REM sleep disorder (RSD)
rsd_snomed = codelist_from_csv(
  "codelists/bristol-rem-sleep-disorder-snomed-ct-v13.csv",
  column = "code",
)
rsd_icd10 = codelist_from_csv(
  "codelists/bristol-rem-sleep-disorder-icd10-v13.csv",
  column = "code",
)

# Additional temporary REM sleep disorder (RSD)
rsd_snomed_new = codelist_from_csv(
  "codelists/bristol-rem-sleep-behaviour-disorder-snomed-ct-v13.csv",
  column = "code",
)
