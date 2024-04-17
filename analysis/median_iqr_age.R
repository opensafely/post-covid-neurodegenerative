# Load libraries ---------------------------------------------------------------
print('Load libraries')

library(magrittr)

# Create empty output ----------------------------------------------------------
print('Create empty output')

df <- data.frame(cohort = character(),
                 median_iqr_age = character())

# Loop over cohorts ------------------------------------------------------------
print("Loop over cohorts")

for (cohort in c("prevax","vax","unvax")) {
  
  # Load data ------------------------------------------------------------------
  print(paste0("Load data for cohort: ",cohort))
  
  tmp <- readr::read_rds(paste0("output/input_",cohort,"_stage1.rds"))
  
  # Calculate median (IQR) age -------------------------------------------------
  print("Calculate median (IQR) age")
  
  df[nrow(df)+1,] <- c(cohort, paste0(quantile(tmp$cov_num_age)[3]," (",
                                      quantile(tmp$cov_num_age)[2],"-",
                                      quantile(tmp$cov_num_age)[4],")"))
  
}

# Save median (IQR) age --------------------------------------------------------
print('Save median (IQR) age')

write.csv(df, "output/median_iqr_age.csv", row.names = FALSE)