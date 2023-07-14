################################################################################
#-------------------------- IMPORTANT - PLEASE READ ---------------------------#
# This script will save results directly to the EHR sharepoint so will save over any results that are already there
# The lifetables will be saved into the directory aer_raw_output_dir. 
# To create a new folder, please change the 'date' variable to avoid overwriting any previous results
# To save from your own OneDrive, update the staff ID (currenlty zy21123) to your own
#------------------------------------------------------------------------------#
################################################################################

#table 2
results_dir <- "C:/Users/rs22981/GitHub/post-covid-neurodegenerative/output/" #Change according to each repo/OneDrive

#Output directories 
#Raw
aer_raw_output_dir <- paste0("C:/Users/rs22981/Opensafely/Neurodegenerative/", format(Sys.time(), "%d_%m_%Y"), "/") #Change according to repo/OneDrive
#Compiled
aer_compiled_output_dir <- paste0("C:/Users/rs22981/Opensafely/Neurodegenerative/", format(Sys.time(), "%d_%m_%Y"), "/") #Change according to repo/OneDrive

#Create directories with dates
dir.create(file.path(aer_raw_output_dir), recursive =TRUE, showWarnings = FALSE)
dir.create(file.path(aer_compiled_output_dir), recursive =TRUE, showWarnings = FALSE)

#-------------------------Call AER function-------------------------------------
source("analysis/model/Absolute_excess_risk_function.R")

library(purrr)
library(data.table)
library(tidyverse)

#--------------------which analyses to calculate AER for------------------------
#Define the active analyses
# active <- readr::read_rds("lib/active_analyses.rds")  (According to CVD) Wait to test with real data
# 
# active <- active %>% 
#   select(c("cohort", "outcome", "analysis")) %>%
#   mutate(outcome = str_remove(outcome, "out_date_")) %>%
#   filter(grepl("sub_male_age_|sub_female_age_", analysis)) %>%
#   filter(outcome == "alzheimer_disease") #optional step at the moment
# 
# #Add HR time point terms so that results can be left joined
# term <- c("days0_28","days28_197","days197_365", "days365_714")
# results <- crossing(active, term)

#------------------------------------ Load results------------------------------
input <- file.path("C:/Users/rs22981/Opensafely/AER/") #Change according to repo/OneDrive
#data <- file.path(model_output, "model_output.csv") 

#model output
input <- read.csv(file.path(input, "model_output.csv")) %>%
  filter(model == "mdl_max_adj") %>% #main according to cvd & (analysis == "main") Wait to test with real data
  filter(grepl("sub_male_age_|sub_female_age_", analysis)) %>%
  #filter(grepl("^days", term)) %>% #pre days
  filter(grepl("days\\d+", term)) %>%
  filter(!grepl("[redact]", hr)) %>%
  mutate(hr = as.numeric(hr)) %>% 
  select(c(cohort, outcome, analysis, model, term, hr)) 

#------------ Input Table 2 & Selected columns and terms ----------------------#

clean_table2 <- function(df) {
  df <- df %>% 
    mutate(outcome = str_remove(outcome, "out_date_")) %>% 
    filter(grepl("sub_male_age_|sub_female_age_", analysis)) %>% #main & sex female/male ~ aer models #main| Wait to test with real data
    select(c(outcome, analysis, cohort, unexposed_person_days, unexposed_events, total_exposed, sample_size)) 
}

#Cohort names per table 2
dataset_names <- c("prevax", "vax", "unvax")
#Load table 2 csv files
df_list_t2 <- lapply(dataset_names, function(name) read.csv(paste0(results_dir, "table2_", name, "_rounded.csv")))

#Apply clean table 2 function
table_2 <- lapply(df_list_t2, clean_table2) %>% 
  #Combine tables into 1
  bind_rows() 

#------------------ Select required columns and term --------------------------#

# #join HR onto active df (According to CVD) Wait to test with real data
# results <- results %>%
#   left_join(input, by = c("cohort", "outcome", "analysis", "term"))
# results <- results %>%
#   filter(!is.na(hr))
# 
# #Join on table 2 event counts (According to CVD) Wait to test with real data
# results <- results %>%
#   left_join(table_2, by = c("cohort", "outcome", "analysis")) %>%
#   mutate(across(c(hr, unexposed_person_days, unexposed_events, total_exposed, sample_size), as.numeric)) %>%
#   as_tibble()

#Join input (model_output) with table_2
results <- input %>%
  left_join(table_2, by = c("cohort", "outcome", "analysis")) %>%
  mutate(across(c(hr, unexposed_person_days, unexposed_events, total_exposed, sample_size), as.numeric)) %>%
  as_tibble()


##### From here, please check diabetes repo 

#-------------------------Run AER function--------------------------------------

#CVD
# lapply(split(active, seq(nrow(active))), #input can/should be changed, accoding to the diabetes repo, it should use the input file (line 70), because it contains the variables of interest
#        function(active)
#          excess_risk(
#            outcome_of_interest = active$outcome,
#            cohort_of_interest = active$cohort,
#            model_of_interest = active$model,
#            analysis_of_interest = active$analysis,
#            results))

lapply(split(input, seq(nrow(input))), #input can/should be changed, accoding to the diabetes repo, it should use the input file (line 70), because it contains the variables of interest
       function(input)
         excess_risk(
           outcome_of_interest = input$outcome,
           cohort_of_interest = input$cohort,
           model_of_interest = input$model,
           analysis_of_interest = input$analysis,
           results))

#----------------------------- Compile the results ----------------------------#

AER_files = list.files(path = aer_raw_output_dir, pattern = "lifetable_")
AER_files = paste0(aer_raw_output_dir,"/",AER_files)
AER_compiled_results <- purrr::pmap(list(AER_files),
                                    function(fpath){
                                      df <- fread(fpath)
                                      return(df)})
AER_compiled_results = rbindlist(AER_compiled_results, fill=TRUE)

# Calculate overall AER
AER_combined <- AER_compiled_results %>% 
  select(days, outcome, cohort, analysis, cumulative_difference_absolute_excess_risk)
table_2 <- table_2 %>% 
  select(outcome, cohort, analysis, sample_size)

#Standardize AER and use pre-vax subgroup sizes for all cohorts
table_2 <- table_2 %>% filter(cohort == "prevax") %>% select(!cohort)
table_2$weight <- table_2$sample_size/sum(table_2$sample_size) #ASK

AER_combined <- AER_combined %>% left_join(table_2 %>%
                                             select(outcome, analysis, weight), by=c("outcome","analysis"))

AER_combined <- AER_combined %>% filter(!is.na(cumulative_difference_absolute_excess_risk))

AER_combined <- AER_combined %>% 
  dplyr::group_by(days, outcome, cohort) %>% #time_points removed
  dplyr::summarise(weighted_mean = weighted.mean(cumulative_difference_absolute_excess_risk, weight)) #warning due to synthetic data


# AER_combined <- AER_combined %>% filter(!is.na(excess_risk)) #Wait for real data to test

# AER_combined <- AER_combined %>% #Wait to test with real data
#   group_by(days, outcome, cohort) %>%
#   mutate(weight = sample_size/sum(sample_size)) FROM CVD/Diabetes

#Join all results together 
AER_combined$subgroup <- "aer_overall"

AER_combined <- AER_combined %>% dplyr::rename(cumulative_difference_absolute_excess_risk = weighted_mean)

AER_compiled_results <- rbind(AER_compiled_results, AER_combined, fill = TRUE)

write.csv(AER_compiled_results, paste0(aer_compiled_output_dir,"/AER_compiled_results.csv"), row.names = F)

################################################################################             