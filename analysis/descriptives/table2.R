# Load libraries ---------------------------------------------------------------
print('Load libraries')

library(readr)
library(dplyr)
library(magrittr)

# Specify redaction threshold --------------------------------------------------
print('Specify redaction threshold')

threshold <- 6

# Source common functions ------------------------------------------------------
print('Source common functions')

source("analysis/utility.R")

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  cohort <- "vax"
} else {
  cohort <- args[[1]]
}

# Load active analyses ---------------------------------------------------------
print('Load active analyses')

#active_analyses <- readr::read_rds("lib/active_analyses.rds")
#active_analyses <- active_analyses[active_analyses$cohort==cohort,]

active_analyses <- readr::read_rds("lib/active_analyses.rds") %>% 
  filter(outcome %in% c("out_date_alzheimer_disease", "out_date_parkinson_disease", "out_date_any_dementia", "out_date_rem_sleep_disorder",
                        "out_date_migraine", "out_date_vascular_dementia", "out_date_other_dementias", "out_date_unspecified_dementias")) %>% #outcomes
  filter(analysis %in% c("main", "sub_covid_hospitalised","sub_covid_nonhospitalised","sub_covid_history")) #sub-analysis
  
#outcomes to be reviewed
#"out_date_cognitive_impairment", "out_date_multiple_sclerosis", "out_date_restless_leg_syndrome", "out_date_motor_neurone_disease"

# Make empty table 2 -----------------------------------------------------------
print('Make empty table 2')

table2 <- data.frame(name = character(),
                     cohort = character(),
                     exposure = character(),
                     outcome = character(),
                     analysis = character(),
                     unexposed_person_days = numeric(),
                     unexposed_events = numeric(),
                     exposed_person_days = numeric(),
                     exposed_events = numeric(),
                     total_person_days = numeric(),
                     total_events = numeric(),
                     day0_events = numeric(),
                     total_exposed = numeric(),
                     sample_size = numeric())

# Record number of events and person days for each active analysis -------------
print('Record number of events and person days for each active analysis')

for (i in 1:nrow(active_analyses)) {
  
  ## Load data -----------------------------------------------------------------
  print(paste0("Load data for ",active_analyses$name[i]))
  
  df <- read_rds(paste0("output/model_input-",active_analyses$name[i],".rds"))
  df <- df[,c("patient_id","index_date","exp_date","out_date","end_date")] #"end_date_exposure","end_date_outcome"
  
  ## Calculate person days -----------------------------------------------------
  print('Calculate person days')
  
  df <- df %>% 
    dplyr::mutate(total_person_days = as.numeric((end_date - index_date))+1, #end_date_outcome
                  fup_end_unexposed = min(end_date, exp_date, na.rm = TRUE), #end_date_outcome
                  unexposed_person_days = as.numeric((fup_end_unexposed - index_date))+1,
                  exposed_person_days = as.numeric((exp_date - index_date))+1)
  
  ## Append to table 2 ---------------------------------------------------------
  print('Append to table 2')
  
  table2[nrow(table2)+1,] <- c(name = active_analyses$name[i],
                               cohort = active_analyses$cohort[i],
                               exposure = active_analyses$exposure[i],
                               outcome = active_analyses$outcome[i],
                               analysis = active_analyses$analysis[i],
                               unexposed_person_days = sum(df$unexposed_person_days),
                               unexposed_events = nrow(df[!is.na(df$out_date) & is.na(df$exp_date),]),
                               exposed_person_days = sum(df$exposed_person_days, na.rm = TRUE),
                               exposed_events = nrow(df[!is.na(df$out_date) & !is.na(df$exp_date),]),
                               total_person_days = sum(df$total_person_days),
                               total_events = nrow(df[!is.na(df$out_date),]),
                               day0_events = nrow(df[!is.na(df$out_date) & !is.na(df$exp_date) & df$exp_date==df$out_date,]),
                               total_exposed = nrow(df[!is.na(df$exp_date),]),
                               sample_size = nrow(df))
  
}

# Save Table 2 -----------------------------------------------------------------
print('Save Table 2')

write.csv(table2, "output/table2.csv")
#write.csv(table2, paste0("output/table2_",cohort,".csv"))

# Perform redaction ------------------------------------------------------------
print('Perform redaction')

table2[,setdiff(colnames(table2),c("name","cohort","exposure","outcome","analysis"))] <- lapply(table2[,setdiff(colnames(table2),c("name","cohort","exposure","outcome","analysis"))],
                                                                                                FUN=function(y){roundmid_any(as.numeric(y), to=threshold)})

# Save Table 2 -----------------------------------------------------------------
print('Save rounded Table 2')

write.csv(table2, paste0("output/table2","_rounded.csv"))
#write.csv(table2, paste0("output/table2_",cohort,"_rounded.csv"))
