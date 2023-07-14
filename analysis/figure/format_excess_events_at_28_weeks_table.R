################################################################################

#Load library
library(dplyr)
library(readr)
library(stringr)
library(tidyr)

#Read in AER
df <- readr::read_csv("C:/Users/rs22981/Opensafely/Neurodegenerative/14_07_2023/AER_compiled_results.csv") #Change according to repo/OneDrive

df <- df %>% filter(days == 196 & subgroup == "aer_overall") # & time_points == "reduced"

# The column cumulative_difference_absolute_excess_risk is weighted by th prevax population size
# See lines 144 onwards in analysis/model/Absolute_excess_risk_function.R

#df$time_points <- NULL

# Get excess events at 28 weeks per 100,000 COVID-19 diagnosis
df$cumulative_difference_absolute_excess_risk <- df$cumulative_difference_absolute_excess_risk * 100000
df <- df %>% select(outcome, cohort, cumulative_difference_absolute_excess_risk)
colnames(df) <- c("Outcome", "cohort","Excess events after 100,000 COVID-19 diagnosis")

write.csv(df,"C:/Users/rs22981/Opensafely/Neurodegenerative/14_07_2023/Estimated excess events at 28 weeks.csv", row.names = F) #Change according to repo/OneDrive

################################################################################