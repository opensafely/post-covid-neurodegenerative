## =============================================================================
## Purpose:  Create data for venn diagrams
## 
## Programmed by:   Yinghui Wei, Venexia Walker, Kurt Taylor
##
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

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  # use for interactive testing
  cohort_name <- "all"
  #group <- "diabetes"
} else {
  cohort_name <- args[[1]]
}

fs::dir_create(here::here("output", "not-for-review"))
fs::dir_create(here::here("output", "review", "venn-diagrams"))

venn_output <- function(cohort_name){#, group
  
  # Identify active outcomes ---------------------------------------------------
  
  active_analyses <- readr::read_rds("lib/active_analyses.rds")
  # added extra statement to include only those with venn == TRUE - because some diabetes outcomes only use one data source and so venn is not applicable
  #outcomes <- active_analyses[active_analyses$active==TRUE & active_analyses$venn==TRUE & active_analyses$outcome_group==group,]$outcome_variable
  outcomes <- active_analyses[active_analyses$active==TRUE & active_analyses$venn==TRUE,]$outcome_variable
  
  #if(length(outcomes) == 0){
  #  print(paste0("No venn diagram generated for outcome group ",group))
  #} else{
  
  # Load data ------------------------------------------------------------------
  
  input <- readr::read_rds(paste0("output/venn_",cohort_name, ".rds"))
  end_dates <- read_rds(paste0("output/follow_up_end_dates_",cohort_name, ".rds"))#cohort_name, "_",group
  
  input_stage1 <- readr::read_rds(paste0("output/input_", cohort_name,"_stage1", ".rds"))#cohort_name,"_stage1_", group
  input_stage1 <- input_stage1[input_stage1$sub_bin_covid19_confirmed_history==FALSE,]
  
  input <- input[input$patient_id %in% input_stage1$patient_id,]
  input<- input %>% left_join(end_dates, by="patient_id")
  
  rm(input_stage1,end_dates)
  
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
  # Populate table and make Venn for each outcome ------------------------------
  for (outcome in outcomes) {
    outcome_save_name <- outcome
    
    print(paste0("Working on ", outcome))
    # Restrict data to that relevant to the given outcome ----------------------
    
    if(grepl("_primary_position",outcome)==TRUE){
      tmp <- input[!is.na(input[,outcome]),c("patient_id","index_date",paste0(gsub("out_date_","", outcome),"_follow_up_end"),outcome, colnames(input)[grepl(paste0("tmp_",gsub("_primary_position","", outcome)),colnames(input))])]
      tmp[,grepl(paste0("tmp_",gsub("_primary_position","", outcome),"_hes"),colnames(tmp))] <- NULL
      colnames(tmp) <- gsub("_primary_position","",colnames(tmp))
    }else{
      tmp <- input[!is.na(input[,outcome]),c("patient_id","index_date",paste0(gsub("out_date_","", outcome),"_follow_up_end"), colnames(input)[grepl(outcome,colnames(input))])]
      tmp[,grepl("_primary_position",colnames(tmp))] <- NULL
    }
    
    if(dim(tmp)[1] == 0){
      print(paste0("No venn diagram generated for outcome ",outcome))
    } else{
      
      outcome <- gsub("_primary_position","",outcome)    
      colnames(tmp) <- gsub(paste0("tmp_",outcome,"_"),"",colnames(tmp))
      
      setnames(tmp,
               old=c(paste0(gsub("out_date_","", outcome),"_follow_up_end"),
                     outcome),
               new=c("follow_up_end",
                     "event_date"))
      
      tmp <- tmp %>% filter(follow_up_end >= index_date)
      
      # Impose follow-up start and end dates on events dates
      
      event_cols <- c("snomed","hes","death","event_date")
      for(colname in event_cols){
        if(colname %in% colnames(tmp)){
          tmp <- tmp %>% mutate(!!sym(colname) := replace(!!sym(colname), which(!!sym(colname)>follow_up_end | !!sym(colname)<index_date), NA))
          
        }
      }
      
      # Identify and add missing columns -----------------------------------------
      
      complete <- data.frame(patient_id = tmp$patient_id,
                             snomed = as.Date(NA),
                             hes = as.Date(NA),
                             death = as.Date(NA))
      
      #colnames(complete) <- c("patient_id",paste0("tmp_",outcome,c("_snomed","_hes","_death")))
      
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
      
      write.csv(df, file = paste0("output/review/venn-diagrams/venn_diagram_number_check_", cohort_name, ".csv"), row.names = F)#cohort_name, "_",group
    }
  }
}
#}

# Run function using specified commandArgs and active analyses for group

# active_analyses <- read_rds("lib/active_analyses.rds")
# active_analyses <- active_analyses %>% filter(active==TRUE & venn==TRUE)
# group <- unique(active_analyses$outcome_group)

if (cohort_name == "all") {
  venn_output("prevax")
  venn_output("vax")
  venn_output("unvax")
} else{
  venn_output(cohort_name)
}

# for(i in group){
#   if (cohort_name == "all") {
#     venn_output("prevax", i)
#     venn_output("vax", i)
#     venn_output("unvax", i)
#   } else{
#     venn_output(cohort_name, i)
#   }
# }