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

active_analyses <- readr::read_rds("lib/active_analyses.rds")
active_analyses <- active_analyses[active_analyses$cohort==cohort,]
active_analyses <- active_analyses[active_analyses$analysis == "main",]

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
  df <- df[,c("patient_id","index_date","exp_date","out_date","end_date_exposure","end_date_outcome")]
  
  # Remove exposures and outcomes outside follow-up ----------------------------
  print("Remove exposures and outcomes outside follow-up")
  
  df <- df %>% 
    dplyr::mutate(exposure = replace(exp_date, which(exp_date>end_date_exposure | exp_date<index_date), NA),
                  outcome = replace(out_date, which(out_date>end_date_outcome | out_date<index_date), NA))
  
  ## Make exposed subset -------------------------------------------------------
  print('Make exposed subset')
  
  exposed <- df[!is.na(df$exp_date),c("patient_id","exp_date","out_date","end_date_outcome")]
  
  exposed <- exposed %>% dplyr::mutate(fup_start = exp_date,
                                       fup_end = min(end_date_outcome, out_date, na.rm = TRUE))
  
  exposed <- exposed[exposed$fup_start<=exposed$fup_end,]
  
  exposed <- exposed %>% dplyr::mutate(person_days = as.numeric((fup_end - fup_start))+1)
  
  ## Make unexposed subset -----------------------------------------------------
  print('Make unexposed subset')
  
  unexposed <- df[,c("patient_id","index_date","exp_date","out_date","end_date_outcome")]
  
  unexposed <- unexposed %>% dplyr::mutate(fup_start = index_date,
                                           fup_end = min(exp_date-1, end_date_outcome, out_date, na.rm = TRUE),
                                           out_date = replace(out_date, which(out_date>fup_end), NA))
  
  unexposed <- unexposed[unexposed$fup_start<=unexposed$fup_end,]
  
  unexposed <- unexposed %>% dplyr::mutate(person_days = as.numeric((fup_end - fup_start))+1)
  
  ## Append to table 2 ---------------------------------------------------------
  print('Append to table 2')
  
  table2[nrow(table2)+1,] <- c(name = active_analyses$name[i],
                               cohort = active_analyses$cohort[i],
                               exposure = active_analyses$exposure[i],
                               outcome = active_analyses$outcome[i],
                               analysis = active_analyses$analysis[i],
                               unexposed_person_days = sum(unexposed$person_days),
                               unexposed_events = nrow(unexposed[!is.na(unexposed$out_date),]),
                               exposed_person_days = sum(exposed$person_days, na.rm = TRUE),
                               exposed_events = nrow(exposed[!is.na(exposed$out_date),]),
                               total_person_days = sum(unexposed$person_days) + sum(exposed$person_days),
                               total_events = nrow(unexposed[!is.na(unexposed$out_date),]) + nrow(exposed[!is.na(exposed$out_date),]),
                               day0_events = nrow(exposed[exposed$exp_date==exposed$out_date & !is.na(exposed$exp_date) & !is.na(exposed$out_date),]),
                               total_exposed = nrow(exposed),
                               sample_size = nrow(df))
  
}

# Save Table 2 -----------------------------------------------------------------
print('Save Table 2')

write.csv(table2, paste0("output/table2_",cohort,".csv"), row.names = FALSE)

# Perform redaction ------------------------------------------------------------
print('Perform redaction')

table2[,setdiff(colnames(table2),c("name","cohort","exposure","outcome","analysis"))] <- lapply(table2[,setdiff(colnames(table2),c("name","cohort","exposure","outcome","analysis"))],
                                                                                                FUN=function(y){roundmid_any(as.numeric(y), to=threshold)})

# Save Table 2 -----------------------------------------------------------------
print('Save rounded Table 2')

write.csv(table2, paste0("output/table2_",cohort,"_rounded.csv"), row.names = FALSE)