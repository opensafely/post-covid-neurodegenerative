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
                 unexposed_events_midpoint6 = numeric(),
                 exposed_person_days = numeric(),
                 exposed_events_midpoint6 = numeric(),
                 total_person_days = numeric(),
                 total_events_midpoint6 = numeric(),
                 day0_events_midpoint6 = numeric(),
                 total_exposed_midpoint6 = numeric(),
                 sample_size_midpoint6 = numeric())

for (cohort in c("prevax","vax","unvax")) {
  
  # Load data ------------------------------------------------------------------
  print('Load data')
  
  table2 <- readr::read_csv(paste0("output/table2_",cohort,"_midpoint6.csv"))
  
  # Perform redaction ----------------------------------------------------------
  print('Perform redaction')
  
  table2$unexposed_events_midpoint6 <- roundmid_any(as.numeric(table2$unexposed_events), to=threshold)
  table2$exposed_events_midpoint6 <- roundmid_any(as.numeric(table2$exposed_events), to=threshold)
  table2$day0_events_midpoint6 <- roundmid_any(as.numeric(table2$day0_events), to=threshold)
  table2$total_exposed_midpoint6 <- roundmid_any(as.numeric(table2$total_exposed), to=threshold)
  table2$sample_size_midpoint6 <- roundmid_any(as.numeric(table2$sample_size), to=threshold)
  
  # Recalculate total columns --------------------------------------------------
  print('Recalculate total columns')
  
  table2$total_events_midpoint6_derived <- table2$exposed_events_midpoint6 + table2$unexposed_events_midpoint6
  
  # Merge to main dataframe ----------------------------------------------------
  print('Recalculate total columns')
  
  table2 <- table2[,c("name","cohort","exposure","outcome","analysis",
                      "unexposed_person_days","unexposed_events_midpoint6",
                      "exposed_person_days","exposed_events_midpoint6",
                      "total_person_days","total_events_midpoint6_derived","day0_events_midpoint6",
                      "total_exposed_midpoint6","sample_size_midpoint6")]
  
  df <- rbind(df, table2)
  
}

# Save Table 2 -----------------------------------------------------------------
print('Save rounded Table 2')

write.csv(df, "output/table2_output_rounded.csv", row.names = FALSE)