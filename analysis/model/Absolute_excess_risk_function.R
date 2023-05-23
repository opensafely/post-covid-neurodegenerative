## =============================================================================
## Project:     Vaccinated delta wave population study
##
## Purpose:  
##  Apply stage 5. Absolute excess risk analysis
##  - Create a function to calculate absolute excess risks
## 
## Authors: Lucy Teece (adapted from RT, XJ, VW)
## Reviewer: Genevieve Cezard
## 
## TO RUN OUTSIDE OPENSAFELY PLATFORM
## Content: 
## 0. Clean input data and subset to relevant event / cohort
## 1. Average daily incidence of each outcome in unexposed age/sex subgroups
## 2. Life table approach to calculate cumulative risk over time
## 3. Carry over time-varying hazard ratios
## 4. Daily event incidence in exposed age/sex subgroups
## 5. Daily excess risk between exposed and unexposed age/sex subgroups
## 6. Absolute excess risk weighted by total number of COVID cases
## 7. total absolute excess risk as culmination of age/sex subgroups
## =============================================================================

# # CODE FOR SINGLE AER
# event_of_interest="REM, vascular dementia"
# cohort_of_interest="pre_vaccination"
# model_of_interest="mdl_max_adj"     #Should always be maximum adjusted model
# subgroup_of_interest="hospitalised"

excess_risk <- function(outcome_of_interest, cohort_of_interest, model_of_interest, analysis_of_interest, input) { ##check email / diabetes repo
  
  
  #-------------------------Check structure the input---------------------------
  input <- input %>% mutate(across(c("hr","unexposed_person_days","unexposed_events","total_exposed", "sample_size"), as.numeric)) #check email
  input <- as.data.frame(input)
  
  #---------------------------------Subset to relevant data---------------------
  input <- input[input$outcome == outcome_of_interest
                 & input$model == model_of_interest
                 & input$cohort == cohort_of_interest
                 & input$analysis == analysis_of_interest,]
  
  #----Add start and end days for time periods which are needed for lifetable---
  for(i in c("time_period_start","time_period_end")){
    input[,i] <- input$term
    input[,i] <- gsub("days", "",input[,i])                                     #Remove 'days'
  }
  
  input$time_period_start <- gsub("\\_.*", "",input[,i])                        #Remove everything after _
  input$time_period_end <- gsub(".*_", "",input[,i])                            #Remove everything before _
  input <- input %>% mutate(across(c("time_period_start", "time_period_end"), as.numeric))
  
  
  #---------------------------------------------------------------
  # LIFETABLE APPROACH
  #---------------------------------------------------------------
  lifetable <- data.frame(c(0:(max(input$time_period_end)-1)))
  
  colnames(lifetable) <- c("days")
  lifetable$outcome <- outcome_of_interest
  lifetable$cohort <- cohort_of_interest
  lifetable$model <- model_of_interest
  lifetable$analysis <- analysis_of_interest
  
  
  #Step1. Calculate average daily incidence of outcome in unexposed age/sex subgroups
  #As number of events (in the unexposed) divided by time (days)
  lifetable$incidence_unexp <- input$unexposed_event[1] / input$unexposed_person_days[1]
  
  #Step2. Use life table approach to calculate cumulative risk over time in unexposed age/sex subgroups
  lifetable$cumulative_survival_unexp <- cumprod(1 - lifetable$incidence_unexp) 
  
  #Step3. Carry over maximally adjusted hazard ratio estimates (time varying) for event after COVID exposure
  lifetable$hr <- NA
  
  for(i in 1:nrow(input)){
    tmp <- input[i,]
    lifetable$hr <- ifelse(lifetable$days >= tmp$time_period_start & lifetable$days < tmp$time_period_end, tmp$hr, lifetable$hr)
  }
  
  #Step4. Calculate predicted incidence of outcome after COVID exposure in age/sex subgroups
  #Multiply daily incidence in unexposed by maximally adjusted hazard ratios (time varying) for event after COVID exposure
  lifetable$cumulative_survival_exp <- cumprod(1 - (lifetable$hr * lifetable$incidence_unexp))
  
  #Step5. Calculate daily excess risk
  #As difference in cumulative survival unexposed and expected cumulative survival in unexposed
  lifetable$excess_risk <- lifetable$cumulative_survival_unexp - lifetable$cumulative_survival_exp
  
  #Step6. Carry over total number of COVID cases in age/sex subgroup, calculate subgroup-specific absolute excess risk
  lifetable$N_exposed <- input$N_exposed[1] 
  lifetable$AER <- lifetable$excess_risk * lifetable$N_exposed 
  
  #Step7. Total AER as total of all subgroups
  
  #lifetable$total_AER = rowSums(select(lifetable, ends_with("_AER")))
  
  # write output for AER figure
  write.csv(lifetable, file=paste0(aer_raw_output_dir, "/lifetable_" ,event_of_interest, "_" ,subgroup_of_interest, "_",cohort_of_interest,"_",time_point_of_interest, "_time_points.csv"), row.names = F)
  
  
  #AER_followup_end <- lifetable[nrow(lifetable),]$total_AER
  
  # results <- data.frame(event=event_of_interest,
  #                       cohort=cohort_of_interest,
  #                       model=model_of_interest,
  #                       AER_followup_end=AER_followup_end)
  
  #write.csv(results, paste0(aer_raw_results_dir, "/AER_raw_results_", cohort_of_interest, "_", model_of_interest, "_", event_of_interest,".csv"), row.names = F)
  #return(results)
}