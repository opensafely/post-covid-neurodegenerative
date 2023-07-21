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
# active <- readr::read_rds("lib/active_analyses.rds")  #(According to CVD) Wait to test with real data
# 
# active <- active %>%
#   select(c("cohort", "outcome", "analysis")) %>%
#   mutate(outcome = str_remove(outcome, "out_date_")) %>%
#   filter(grepl("main", analysis)) %>% #sub_sex_female|sub_sex_male
#   filter(outcome == "parkinson_disease") #optional step at the moment
# 
# #Add HR time point terms so that results can be left joined
# term <- c("days0_28","days28_197","days197_365", "days365_714")
# results <- crossing(active, term)

#------------------------------------ Load results------------------------------
input <- file.path("C:/Users/rs22981/Opensafely/AER/") #Change according to repo/OneDrive
#data <- file.path(model_output, "model_output.csv") 

#model output
input <- read.csv(file.path(results_dir, "model_output.csv")) %>%
  filter(str_detect(term, "days\\d+") & (analysis == "main") 
         & model == "mdl_max_adj"
         & hr != "[redact]") %>%
  mutate(hr = as.numeric(hr)) %>% 
  select(c(cohort, outcome, analysis, model, term, hr)) %>%
  #mutate(outcome = str_to_title(outcome)) %>%
  #mutate(outcome = str_replace_all(outcome, "_", " ")) %>%
  filter(grepl("parkinson_disease", outcome)) #temporary step

#------------------------- Input AER table ------------------------------------#

aer_table <- read.csv(paste0(results_dir, "aer_input-main-rounded.csv")) %>%
  #temporary step, should be changed according to each repo 
  filter(cohort == "prevax") %>% 
  filter(grepl("parkinson_disease", outcome))
  #filter(!grepl("any_dementia|restless_leg_syndrome", outcome))

#------------------ Select required columns and term --------------------------#

#Join input (model_output) with aer_table
results <- input %>%
  left_join(aer_table, by = c("cohort", "outcome", "analysis"), relationship = "many-to-many") %>%
  mutate(across(c(hr, unexposed_person_days, unexposed_events, total_exposed, sample_size), as.numeric)) %>%
  as_tibble()

#-------------------------Run AER function--------------------------------------

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

#----------------------------- Calculate overall AER --------------------------#
AER_combined <- AER_compiled_results %>% 
  select(days, outcome, cohort, analysis, cumulative_difference_absolute_excess_risk)

aer_table <- aer_table %>% 
  select(outcome, cohort, analysis, sample_size)

aer_table <- aer_table %>% filter(cohort == "prevax") %>% select(!cohort)
aer_table$weight <- aer_table$sample_size/sum(aer_table$sample_size) #ASK

AER_combined <- AER_combined %>% left_join(aer_table %>%
                                             select(outcome, analysis, weight), by=c("outcome", "analysis"), relationship = "many-to-many") #

AER_combined <- AER_combined %>% filter(!is.na(cumulative_difference_absolute_excess_risk))

AER_combined <- AER_combined %>% 
  dplyr::group_by(days, outcome, cohort) %>% 
  dplyr::summarise(weighted_mean = weighted.mean(cumulative_difference_absolute_excess_risk, weight)) #warning due to synthetic data, only using prevax. Need to be tested with real data.

#-------------------------- Join all results together--------------------------#
AER_combined$subgroup <- "aer_overall"

AER_combined <- AER_combined %>% dplyr::rename(cumulative_difference_absolute_excess_risk = weighted_mean)

AER_compiled_results <- rbind(AER_compiled_results, AER_combined, fill = TRUE)

write.csv(AER_compiled_results, paste0(aer_compiled_output_dir,"/AER_compiled_results.csv"), row.names = F)

################################################################################             