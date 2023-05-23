################################################################################
#-------------------------- IMPORTANT - PLEASE READ ---------------------------#
# This script will save results directly to the EHR sharepoint so will save over any results that are already there
# The lifetables will be saved into the directory aer_raw_output_dir. 
# To create a new folder, please change the 'date' variable to avoid overwriting any previous results
# To save from your own OneDrive, update the staff ID (currenlty zy21123) to your own
#------------------------------------------------------------------------------#
################################################################################

#table 2
results_dir <- "C:/Users/rs22981/GitHub/post-covid-neurodegenerative/output/"

# Set file locations
date <- "22_05_2023" #Check diabetes repo
aer_raw_output_dir <- paste0("C:/Users/rs22981/Opensafely/Neurodegenerative/",date,"/") #Check diabetes repo


aer_compiled_output_dir <- paste0("C:/Users/rs22981/Opensafely/Neurodegenerative/",date,"/") #Check diabetes repo
scripts_dir <- "analysis/model"

dir.create(file.path(aer_raw_output_dir), recursive =TRUE, showWarnings = FALSE) #Check diabetes repo
dir.create(file.path(aer_compiled_output_dir), recursive =TRUE, showWarnings = FALSE) #Check diabetes repo

#-------------------------Call AER function-------------------------------------
source(file.path(scripts_dir,"Absolute_excess_risk_function.R"))

library(purrr)
library(data.table)
library(tidyverse)

#--------------------which analyses to calculate AER for------------------------

#Define analyses
model_output <- file.path("C:/Users/rs22981/Opensafely/Neuro/Release/20230505/") 
data <- file.path(model_output, "model_output.csv") 
#model output
model_output <- read.csv(data) %>%
  filter(model == "mdl_max_adj" & analysis == "main") %>% 
  #filter(grepl("sub_male_age_", analysis)) %>% #wait for new models
  #filter(grepl("sub_female_age_", analysis)) %>% #wait for new models
  #keep only rows with time points 
  filter(grepl("days\\d+", term)) %>%
  #filter(grepl("^days", term)) %>% #pre days
  filter(!grepl("[redact]", hr)) %>%
  mutate(hr = as.numeric(hr)) %>% 
  select(c(cohort, outcome, analysis, model, term, hr)) #Check email
  
#------------ Input Table 2 & Selected columns and terms ----------------------#

clean_table2 <- function(df) {
  df <- df %>% 
    mutate(outcome = str_remove(outcome, "out_date_")) %>% 
    select(c(outcome, analysis, cohort, unexposed_person_days, unexposed_events, total_exposed, sample_size)) #Check email
}

#load files and apply clean table 2 function
table2_prevax <- clean_table2(read.csv(paste0(results_dir,"table2_prevax_rounded.csv")))
table2_unvax <- clean_table2(read.csv(paste0(results_dir,"table2_unvax_rounded.csv")))
table2_vax <- clean_table2(read.csv(paste0(results_dir,"table2_vax_rounded.csv")))

#Combine tables 
table2 <- rbind(table2_prevax, table2_vax, table2_unvax) #consider bind_rows

#remove original tables
rm(table2_prevax, table2_vax, table2_unvax)

#------------------ Select required columns and term --------------------------#

# Join model_output file (aer) with table2
input <- model_output %>%
  left_join(table2, by = c("cohort", "outcome", "analysis")) %>%
  as_tibble()


##### From here, please check diabetes repo 

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

# Calculate overall AER
AER_combined <- AER_compiled_results %>% select(days, outcome, cohort, analysis, excess_risk)
table_2 <- table_2 %>% select(outcome, cohort, analysis, N_population_size)

# Calculate overall AER
AER_combined <- AER_compiled_results %>% select(days, event, cohort, analysis, excess_risk)
table_2 <- table_2 %>% select(outcome, cohort, analysis, sample_size)

#Standardize AER and use pre-vax subgroup sizes for all cohorts
table_2 <- table_2 %>% filter(cohort == "prevax") %>% select(!cohort)
AER_combined <- AER_combined %>% left_join(table_2, by=c("outcome","analysis"))

AER_combined <- AER_combined %>% filter(!is.na(excess_risk))

AER_combined <- AER_combined %>% 
  group_by(days, outcome, cohort) %>%
  mutate(weight = sample_size/sum(sample_size))

AER_combined <- AER_combined %>% 
  dplyr::group_by(days, outcome, cohort) %>%
  dplyr::summarise(weighted_mean = weighted.mean(excess_risk, weight))

#Join all results together 
AER_combined$subgroup <- "aer_overall"

AER_combined <- AER_combined %>% dplyr::rename(excess_risk = weighted_mean )

AER_compiled_results <- rbind(AER_compiled_results, AER_combined, fill = TRUE)

write.csv(AER_compiled_results, paste0(aer_compiled_output_dir,"/AER_compiled_results.csv"), row.names = F)

################################################################################             