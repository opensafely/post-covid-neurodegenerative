## =============================================================================
## Purpose:  Create data for venn diagrams
## 
## Programmed by:   Yinghui Wei, Venexia Walker, Kurt Taylor
## Updated by: Jose Ignacio Cuitun Coronado
## Reviewer: Renin Toms, Venexia Walker, Yinghui Wei
##
## Date:     07 July 2022
##
## Data:     Post covid unvaccinated study population
##
## Content:  to create a Venn diagram for each outcome outlining overlap in 
##           reporting from different data sources
## Output:   Venn diagrams in SVG files, venn_diagram_number_check.csv
## =============================================================================
library(data.table)
library(readr)
library(dplyr)
library(purrr)
library(tidyverse)

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  # use for interactive testing
  cohort <- "prevax"
  #model <- "model_input-cohort_"
  #analysis <- "depression"
  group <- "parkinson_disease"
} else {
  cohort <- args[[1]]
  #group <- args[[2]]
}

fs::dir_create(here::here("output", "not-for-review"))
fs::dir_create(here::here("output", "review", "venn-diagrams"))

#cohorts <- c("vax","unvax","prevax")

venn_output <- function(cohort, group){
  
  # Identify active outcomes ---------------------------------------------------
  
  ## Read in active analyses table and filter to relevant outcomes
  active_analyses <- readr::read_rds("lib/active_analyses.rds")
  
  outcomes <- unique(active_analyses[active_analyses$analysis == "main" & grepl("out_date_", active_analyses$outcome),]$outcome)
  #outcomes <- active_analyses %>% select(outcome) %>% unique() 
  
  if(length(outcomes) == 0){
    print(paste0("No venn diagram generated for outcome group ", group))
  } else{  
    
    #Load data
    input <- readr::read_rds(paste0("output/venn_", cohort, ".rds"))
    
    #follow up end dates variables
    model_input <- readr::read_rds(paste0("output/model_input-cohort_", cohort,"-main-", group, ".rds"))
    
    #input<- input %>% left_join(end_dates, by="patient_id")
    input <- left_join(input, model_input, by = "patient_id")
    
    rm(model_input)
    
    # Create empty table ---------------------------------------------------------
    
    df <- data.frame(outcome = character(),
                     only_snomed = numeric(),
                     only_hes = numeric(),
                     only_death = numeric(),
                     snomed_hes = numeric(),
                     snomed_death = numeric(),
                     hes_death = numeric(),
                     snomed_hes_death = numeric(),
                     total_snomed = numeric(),
                     total_hes = numeric(),
                     total_death = numeric(),
                     total = numeric(),
                     stringsAsFactors = FALSE)
    
    # Populate table and make Venn for each outcome ------------------------------
    for (i in outcomes) {
      outcome_save_name <- i
      
      print(paste0("Working on ", i))
      
      outcome <- outcomes #Ask
      #outcome_save_name <- outcome
      
      tmp <- input[!is.na(input[,i]), c("patient_id", "index_date", "end_date", colnames(input)[grepl(i, colnames(input))])] 
      
      colnames(tmp) <- gsub(paste0("tmp_",i,"_"),"",colnames(tmp)) 
      
      setnames(tmp,
               old=i,
               new="event_date") #Ask
      
      # Identify and add missing columns -----------------------------------------
      
      complete <- data.frame(patient_id = tmp$patient_id,
                             snomed = as.Date(NA),
                             hes = as.Date(NA),
                             death = as.Date(NA))
      
      complete[,setdiff(colnames(tmp),"patient_id")] <- NULL
      notused <- NULL
      
      if (ncol(complete)>1) {
        tmp <- merge(tmp, complete, by = c("patient_id"))
        notused <- setdiff(colnames(complete),"patient_id")
      }
      
      # Calculate the number contributing to each source combo -------------------
      
      tmp$snomed_contributing <- !is.na(tmp$snomed) & 
        is.na(tmp$hes) & 
        is.na(tmp$death)
      
      tmp$hes_contributing <- is.na(tmp$snomed) & 
        !is.na(tmp$hes) & 
        is.na(tmp$death)
      
      tmp$death_contributing <- is.na(tmp$snomed) & 
        is.na(tmp$hes) & 
        !is.na(tmp$death)
      
      tmp$snomed_hes_contributing <- !is.na(tmp$snomed) & 
        !is.na(tmp$hes) & 
        is.na(tmp$death)
      
      tmp$hes_death_contributing <- is.na(tmp$snomed) & 
        !is.na(tmp$hes) & 
        !is.na(tmp$death)
      
      tmp$snomed_death_contributing <- !is.na(tmp$snomed) & 
        is.na(tmp$hes) & 
        !is.na(tmp$death)
      
      tmp$snomed_hes_death_contributing <- !is.na(tmp$snomed) & 
        !is.na(tmp$hes) & 
        !is.na(tmp$death)
      
      df[nrow(df)+1,] <- c(outcome_save_name,
                           only_snomed = nrow(tmp %>% filter(snomed_contributing==T)),
                           only_hes = nrow(tmp %>% filter(hes_contributing==T)),
                           only_death = nrow(tmp %>% filter(death_contributing==T)),
                           snomed_hes = nrow(tmp %>% filter(snomed_hes_contributing==T)),
                           snomed_death = nrow(tmp %>% filter(snomed_death_contributing==T)),
                           hes_death = nrow(tmp %>% filter(hes_death_contributing==T)),
                           snomed_hes_death = nrow(tmp %>% filter(snomed_hes_death_contributing==T)),
                           total_snomed = nrow(tmp %>% filter(!is.na(snomed))),
                           total_hes = nrow(tmp %>% filter(!is.na(hes))),
                           total_death = nrow(tmp %>% filter(!is.na(death))),
                           total = nrow(tmp %>% filter(!is.na(event_date))))
      
      # Remove sources not in study definition from Venn plots and summary -------
      
      source_combos <- c("only_snomed","only_hes","only_death","snomed_hes","snomed_death","hes_death","snomed_hes_death")
      source_consid <- source_combos
      
      if (!is.null(notused)) {
        for (i in notused) {
          
          # Add variables to consider for Venn plot to vector
          
          source_consid <- source_combos[!grepl(i,source_combos)]
          
          # Replace unused sources with NA in summary table
          
          for (j in setdiff(source_combos,source_consid)) {
            df[df$outcome==outcome,j] <- NA
          }
        }
      }
      
      # Save summary file ----------------------------------------------------------
      
      # DISCLOSURE CONTROL ------------------------------------------------------
      
      # round to nearest value
      ceiling_any <- function(x, to=1){
        # round to nearest 100 millionth to avoid floating point errors
        ceiling(plyr::round_any(x/to, 1/100000000))*to
      }
      
      df <- df %>%
        # remove totals column as these are calculated in external_venn_script.R
        dplyr::select(-contains('total')) %>%
        # #change NAs to 0
        replace(is.na(.), 0) %>%
        mutate_at(vars(contains(c('snomed', 'hes', 'death'))), ~ as.numeric(.)) %>%
        # mutate_all(~ as.numeric(.)) %>%
        mutate_at(vars(contains(c('snomed', 'hes', 'death'))), ~ ceiling_any(., to=7))
      
      write.csv(df, file = paste0("output/review/venn-diagrams/venn_diagram_number_check_", cohort, ".csv"), row.names = F)#"_", group, 
    }
  }
}

# Run function using specified commandArgs and active analyses for group

# active_analyses <- readr::read_rds("lib/active_analyses.rds")
# active_analyses <- active_analyses %>% filter(analysis == "main")
# group <- unique(active_analyses$outcome)
# group <- unique(str_remove(active_analyses$outcome, "out_date_"))

group <- c("vascular_dementia", "other_dementias", "unspecified_dementias", "any_dementia", "cognitive_impairment", "restless_leg_syndrome", "rem_sleep_disorder",
           "motor_neurone_disease", "multiple_sclerosis", "migraine", "alzheimer_disease", "parkinson_disease")

# if (cohort_name == "all") {
#   venn_output("prevax")
#   venn_output("vax")
#   venn_output("unvax")
# } else{
#   venn_output(cohort_name)
# }

for(i in group){
  if (cohort == "all") {
    venn_output("prevax", i)
    venn_output("vax", i)
    venn_output("unvax", i)
  } else{
    venn_output(cohort, i)
  }
}

# if (cohort == "all") {
#   venn_output("prevax", i)
#   venn_output("vax", i)
#   venn_output("unvax", i)
# } else{
#   venn_output(cohort, i)
# }