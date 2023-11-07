# Specify redaction threshold --------------------------------------------------
print('Specify redaction threshold')

threshold <- 6

# Source common functions ------------------------------------------------------
print('Source common functions')

source("analysis/utility.R")

# Make empty table 2 -----------------------------------------------------------
print('Make empty table 2')

df <- data.frame(name = character(),
                 cohort = character(),
                 exposure = character(),
                 outcome = character(),
                 analysis = character(),
                 unexposed_person_days = numeric(),
                 unexposed_events_rounded = numeric(),
                 exposed_person_days = numeric(),
                 exposed_events_rounded = numeric(),
                 total_person_days = numeric(),
                 total_events_rounded = numeric(),
                 day0_events_rounded = numeric(),
                 total_exposed_rounded = numeric(),
                 sample_size_rounded = numeric())

for (cohort in c("prevax","vax","unvax")) {
  
  # Load data ------------------------------------------------------------------
  print('Load data')
  
  table2 <- readr::read_csv(paste0("output/table2_",cohort,".csv"))
  
  # Perform redaction ----------------------------------------------------------
  print('Perform redaction')
  
  table2$unexposed_events_rounded <- roundmid_any(as.numeric(table2$unexposed_events), to=threshold)
  table2$exposed_events_rounded <- roundmid_any(as.numeric(table2$exposed_events), to=threshold)
  table2$day0_events_rounded <- roundmid_any(as.numeric(table2$day0_events), to=threshold)
  table2$total_exposed_rounded <- roundmid_any(as.numeric(table2$total_exposed), to=threshold)
  table2$sample_size_rounded <- roundmid_any(as.numeric(table2$sample_size), to=threshold)
  
  # Recalculate total columns --------------------------------------------------
  print('Recalculate total columns')
  
  table2$total_events_rounded <- table2$exposed_events_rounded + table2$unexposed_events_rounded
  
  # Merge to main dataframe ----------------------------------------------------
  print('Recalculate total columns')
  
  table2 <- table2[,c("name","cohort","exposure","outcome","analysis",
                      "unexposed_person_days","unexposed_events_rounded",
                      "exposed_person_days","exposed_events_rounded",
                      "total_person_days","total_events_rounded","day0_events_rounded",
                      "total_exposed_rounded","sample_size_rounded")]
  
  df <- rbind(df, table2)
  
}

# Save Table 2 -----------------------------------------------------------------
print('Save rounded Table 2')

write.csv(df, "output/table2_output_rounded.csv", row.names = FALSE)