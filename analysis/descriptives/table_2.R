## ====================================================================================
## Purpose:  Table 2 for all subgroups + number of events on day of COVID
## 
## Author:   Yinghui Wei
##
## Reviewer: Rochelle Knight
##
##
## Data:     Post covid vaccinated project study population
##
## Content:  person days of follow up, unexposed person days and event counts
##
## Output:   CSV files: table2_*.csv
## ====================================================================================

library(readr)
library(dplyr)
library(data.table) 
library(lubridate)
library(stringr)
library(tidyverse)

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  # use for interactive testing
  cohort_name <- "vax"
  #cohort_name = "electively_unvaccinated"
}else{
  cohort_name <- args[[1]]
}

fs::dir_create(here::here("output", "not-for-review"))
fs::dir_create(here::here("output", "review", "descriptives"))

# DATES

cohort_start_date_prevax <- as.Date("2020-01-01")
cohort_end_date_prevax <- as.Date("2021-06-18")

cohort_start_date_delta <- as.Date("2021-06-01")
cohort_end_date_delta <- as.Date("2021-12-14")

agebreaks <- c(0, 40, 60, 80, 111)
agelabels <- c("18_39", "40_59", "60_79", "80_110")

table_2_subgroups_output <- function(cohort_name){#, group
  
  #----------------------Define analyses of interests---------------------------
  
  active_analyses <- read_rds("lib/active_analyses.rds")
  active_analyses <- active_analyses %>%dplyr::filter(active == "TRUE")# & outcome_group == group)
  
  analyses_of_interest <- as.data.frame(matrix(ncol = 8,nrow = 0))
  
  outcomes<-active_analyses$outcome_variable
  
  #--------------------Load data and left join end dates------------------------
  
  survival_data <- read_rds(paste0("output/input_", cohort_name,"_stage1",".rds"))#cohort_name,"_stage1_", group,
  end_dates <- read_rds(paste0("output/follow_up_end_dates_",cohort_name,".rds")) #cohort_name,"_",group,
  end_dates$index_date <- NULL
  
  survival_data<- survival_data %>% left_join(end_dates, by="patient_id")
  rm(end_dates)
  
  survival_data<-survival_data[,c("patient_id","index_date","cov_cat_sex",
                                  "cov_num_age","cov_cat_ethnicity",
                                  "sub_bin_covid19_confirmed_history","exp_date_covid19_confirmed","sub_cat_covid19_hospital",
                                  colnames(survival_data)[grepl("out_",colnames(survival_data))],
                                  colnames(survival_data)[grepl("follow_up",colnames(survival_data))],
                                  colnames(survival_data)[grepl("_expo_",colnames(survival_data))],
                                  active_analyses$prior_history_var[active_analyses$prior_history_var !=""])]
  
  setnames(survival_data, 
           old = c("cov_cat_sex", 
                   "cov_cat_ethnicity"), 
           new = c("sex",
                   "ethnicity"))
  
  #-----------------------Add in age groups category----------------------------
  
  setDT(survival_data)[ , agegroup := cut(cov_num_age, 
                                          breaks = agebreaks, 
                                          right = FALSE, 
                                          labels = agelabels)]
  
  for(i in outcomes){
    analyses_to_run <- active_analyses %>% filter(outcome_variable==i)
    
    ##Set which cohorts are required
    if(analyses_to_run$cohort=="all"){
      cohort_to_run=c("prevax", "vax", "unvax")
    }else{
      analyses_to_run=active_analyses$cohort
    }  
    
    # Transpose active_analyses to single column so can filter to analysis models to run
    analyses_to_run <- as.data.frame(t(analyses_to_run))
    analyses_to_run$subgroup <- row.names(analyses_to_run)
    colnames(analyses_to_run) <- c("run","subgroup")
    
    #analyses_to_run<- analyses_to_run %>% filter(run=="TRUE"  & subgroup != "active" & subgroup != "main" & subgroup !="venn") 
    analyses_to_run<- analyses_to_run %>% filter(run=="TRUE"  & subgroup != "active" & subgroup != "venn") #MH
    #analyses_to_run<-analyses_to_run %>% filter(run=="TRUE")# & subgroup !="active")
    rownames(analyses_to_run) <- NULL
    analyses_to_run <- analyses_to_run %>% select(!run)
    analyses_to_run$event=i
    
    # Add in  all possible combinations of the subgroups, models and cohorts
    analyses_to_run <- crossing(analyses_to_run,cohort_to_run)
    
    # Add in which covariates to stratify by
    analyses_to_run$stratify_by_subgroup=NA
    for(j in c("ethnicity","sex")){
      analyses_to_run$stratify_by_subgroup <- ifelse(startsWith(analyses_to_run$subgroup,j),j,analyses_to_run$stratify_by_subgroup)
    }
    
    index = which(active_analyses$outcome_variable == i)
    analyses_to_run$stratify_by_subgroup <- ifelse(startsWith(analyses_to_run$subgroup,"prior_history"),active_analyses$prior_history_var[index],analyses_to_run$stratify_by_subgroup)
    analyses_to_run$stratify_by_subgroup <- ifelse(is.na(analyses_to_run$stratify_by_subgroup),analyses_to_run$subgroup,analyses_to_run$stratify_by_subgroup)
    
    # Add in relevant subgroup levels to specify which stratum to run for
    analyses_to_run$strata <- NA
    analyses_to_run$strata <- ifelse(analyses_to_run$subgroup=="covid_history","TRUE",analyses_to_run$strata)
    
    for(k in c("covid_pheno_","agegp_","sex_","ethnicity_","prior_history_")){
      analyses_to_run$strata <- ifelse(startsWith(analyses_to_run$subgroup,k),gsub(k,"",analyses_to_run$subgroup),analyses_to_run$strata)
    }
    analyses_of_interest <- rbind(analyses_of_interest,analyses_to_run)
    
  }
  
  analyses_of_interest$strata[analyses_of_interest$strata=="South_Asian"]<- "South Asian"
  analyses_of_interest <- analyses_of_interest %>% filter(cohort_to_run == cohort_name)
  
  #-----------------Add subgroup category for low count redaction---------------
  analyses_of_interest <- analyses_of_interest %>% 
    dplyr::mutate(subgroup_cat = case_when(
      startsWith(subgroup, "agegp") ~ "age",
      startsWith(subgroup, "covid_history") ~ "covid_history",
      startsWith(subgroup, "covid_pheno") ~ "covid_pheno",
      startsWith(subgroup, "ethnicity") ~ "ethnicity",
      startsWith(subgroup, "prior_history") ~ "prior_history",
      startsWith(subgroup, "sex") ~ "sex",
      TRUE ~ as.character(subgroup)))
  
  analyses_of_interest[,c("unexposed_person_days", "unexposed_event_count","post_exposure_event_count", "total_person_days","day_0_event_counts")] <- NA
  
  #-----------Populate analyses_of_interest with events counts/follow up--------
  for(i in 1:nrow(analyses_of_interest)){
    print(paste0("Working on ", analyses_of_interest$event[i]," ", analyses_of_interest$subgroup[i]))
    
    event_short = gsub("out_date_", "",analyses_of_interest$event[i])
    setnames(survival_data,
             old = c(paste0("out_date_",event_short),
                     paste0(event_short,"_follow_up_end_unexposed"),
                     paste0(event_short,"_follow_up_end"),
                     paste0(event_short,"_hospitalised_follow_up_end"),
                     paste0(event_short,"_non_hospitalised_follow_up_end"),
                     paste0(event_short,"_hospitalised_date_expo_censor"),
                     paste0(event_short,"_non_hospitalised_date_expo_censor")),
             
             new = c("event_date",
                     "follow_up_end_unexposed",
                     "follow_up_end",
                     "hospitalised_follow_up_end",
                     "non_hospitalised_follow_up_end",
                     "hospitalised_date_expo_censor",
                     "non_hospitalised_date_expo_censor"))
    
    table2_output <- table_2_calculation(survival_data,
                                         event=analyses_of_interest$event[i],
                                         cohort=analyses_of_interest$cohort_to_run[i],
                                         subgroup=analyses_of_interest$subgroup[i], 
                                         stratify_by=analyses_of_interest$strata[i], 
                                         stratify_by_subgroup=analyses_of_interest$stratify_by_subgroup[i])
    
    
    analyses_of_interest$unexposed_person_days[i] <- table2_output[[1]]
    analyses_of_interest$unexposed_event_count [i] <- table2_output[[2]]
    analyses_of_interest$post_exposure_event_count[i] <- table2_output[[3]]
    analyses_of_interest$total_person_days[i] <- table2_output[[4]]
    analyses_of_interest$day_0_event_counts[i] <- table2_output[[5]]
    
    setnames(survival_data,
             old = c("event_date",
                     "follow_up_end_unexposed",
                     "follow_up_end",
                     "hospitalised_follow_up_end",
                     "non_hospitalised_follow_up_end",
                     "hospitalised_date_expo_censor",
                     "non_hospitalised_date_expo_censor"),
             
             new = c(paste0("out_date_",event_short),
                     paste0(event_short,"_follow_up_end_unexposed"),
                     paste0(event_short,"_follow_up_end"),
                     paste0(event_short,"_hospitalised_follow_up_end"),
                     paste0(event_short,"_non_hospitalised_follow_up_end"),
                     paste0(event_short,"_hospitalised_date_expo_censor"),
                     paste0(event_short,"_non_hospitalised_date_expo_censor")))
    
    print(paste0("event count and person years have been produced successfully for", analyses_of_interest$event[i], " in ", cohort_name, " population!"))
  }
  
  #Redact all subgroups levels if one level is redacted so that back calculation 
  #is not possible
  analyses_of_interest <- analyses_of_interest %>%
    group_by(subgroup_cat,event) %>%
    dplyr::mutate(post_exposure_event_count = case_when(
      any(post_exposure_event_count == "[Redacted]") ~ "[Redacted]",
      TRUE ~ as.character(post_exposure_event_count)))
  
  analyses_of_interest <- analyses_of_interest %>%
    group_by(subgroup_cat,event) %>%
    dplyr::mutate(unexposed_event_count = case_when(
      any(unexposed_event_count == "[Redacted]") ~ "[Redacted]",
      TRUE ~ as.character(unexposed_event_count)))
  
  analyses_of_interest <- analyses_of_interest %>%
    group_by(subgroup_cat,event) %>%
    dplyr::mutate(day_0_event_counts = case_when(
      any(day_0_event_counts == "[Redacted]") ~ "[Redacted]",
      TRUE ~ as.character(day_0_event_counts)))
  
  # write output for table2
  write.csv(analyses_of_interest, file=paste0("output/review/descriptives/table2_",cohort_name, ".csv"), row.names = F)#cohort_name,"_",group, 
}

table_2_calculation <- function(survival_data, event,cohort,subgroup, stratify_by, stratify_by_subgroup){
  data_active <- survival_data
  
  data_active <- data_active %>% mutate(event_date = replace(event_date, which(event_date>follow_up_end | event_date<index_date), NA))
  data_active <- data_active %>% mutate(exp_date_covid19_confirmed = replace(exp_date_covid19_confirmed, which(exp_date_covid19_confirmed>follow_up_end | exp_date_covid19_confirmed<index_date), NA))
  
  # filter the population according to whether the subgroup is covid_history
  if(subgroup == "covid_history"){
    data_active <- data_active %>% filter(sub_bin_covid19_confirmed_history ==T)
  }else{
    data_active <- data_active %>% filter(sub_bin_covid19_confirmed_history ==F)
  }
  
  # filter the population according to the subgroup level
  
  for(i in c("ethnicity","sex","prior_history")){
    if(startsWith(subgroup,i)){
      data_active=data_active%>%filter_at(stratify_by_subgroup,all_vars(.==stratify_by))
    }
  }
  
  if(startsWith(subgroup,"agegp_")){
    data_active=data_active %>% filter(agegroup== stratify_by)
  }
  
  # calculate unexposed follow-up days for AER script
  data_active = data_active %>% mutate(person_days_unexposed = as.numeric((as.Date(follow_up_end_unexposed) - as.Date(index_date))))
  index <- which(data_active$follow_up_end_unexposed < data_active$exp_date_covid19_confirmed | is.na(data_active$exp_date_covid19_confirmed))
  data_active$person_days_unexposed[index] = data_active$person_days_unexposed[index] + 1
  
  if(subgroup == "covid_pheno_hospitalised"){
    data_active$exp_date_covid19_confirmed <- as.Date(ifelse((!is.na(data_active$hospitalised_date_expo_censor)) & (data_active$exp_date_covid19_confirmed >= data_active$hospitalised_date_expo_censor), NA, data_active$exp_date_covid19_confirmed), origin='1970-01-01')
    data_active$event_date <- as.Date(ifelse((!is.na(data_active$hospitalised_date_expo_censor)) & (data_active$event_date >= data_active$hospitalised_date_expo_censor), NA, data_active$event_date), origin='1970-01-01')
    data_active <- data_active %>% filter((index_date != hospitalised_date_expo_censor)|is.na(hospitalised_date_expo_censor))
  }
  
  if(subgroup == "covid_pheno_non_hospitalised"){
    data_active$exp_date_covid19_confirmed <- as.Date(ifelse((!is.na(data_active$non_hospitalised_date_expo_censor)) & (data_active$exp_date_covid19_confirmed >= data_active$non_hospitalised_date_expo_censor), NA, data_active$exp_date_covid19_confirmed), origin='1970-01-01')
    data_active$event_date <- as.Date(ifelse((!is.na(data_active$non_hospitalised_date_expo_censor)) & (data_active$event_date >= data_active$non_hospitalised_date_expo_censor), NA, data_active$event_date), origin='1970-01-01')
    data_active <- data_active %>% filter((index_date != non_hospitalised_date_expo_censor)|is.na(non_hospitalised_date_expo_censor))
  }
  
  
  if(!startsWith(subgroup,"covid_pheno_")){
    data_active = data_active %>% mutate(person_days = as.numeric((as.Date(follow_up_end) - as.Date(index_date)))+1)
  }
  
  if(subgroup=="covid_pheno_hospitalised"){
    data_active = data_active %>% mutate(person_days = as.numeric((as.Date(hospitalised_follow_up_end) - as.Date(index_date))))
    index <- which(data_active$hospitalised_follow_up_end > data_active$hospitalised_date_expo_censor | is.na(data_active$hospitalised_date_expo_censor))
    data_active$person_days[index] = data_active$person_days[index] + 1
  }
  
  if(subgroup=="covid_pheno_non_hospitalised"){
    data_active = data_active %>% mutate(person_days = as.numeric((as.Date(non_hospitalised_follow_up_end) - as.Date(index_date))))
    index <- which(data_active$non_hospitalised_follow_up_end > data_active$non_hospitalised_date_expo_censor | is.na(data_active$non_hospitalised_date_expo_censor))
    data_active$person_days[index] = data_active$person_days[index] + 1
  }
  
  if(cohort == "prevax"){
    
    data_active = data_active %>% filter((person_days_unexposed >=0 & person_days_unexposed <= 535)
                                         & (person_days >=0 & person_days <= 535)) # filter out follow up period
    
  } else if (cohort == "vax" | cohort == "unvax"){
    
    data_active = data_active %>% filter((person_days_unexposed >=0 & person_days_unexposed <= 197)
                                         & (person_days >=0 & person_days <= 197)) # filter out follow up period
  }
  
  person_days_total_unexposed  = round(sum(data_active$person_days_unexposed, na.rm = TRUE),1)
  person_days_total = round(sum(data_active$person_days, na.rm = TRUE),1)
  
  if(!startsWith(subgroup,"covid_pheno_")){
    event_count_exposed <- length(which(data_active$event_date >= data_active$index_date &
                                          data_active$event_date >= data_active$exp_date_covid19_confirmed & 
                                          data_active$event_date <= data_active$follow_up_end))
    
    event_count_unexposed<- length(which((data_active$event_date >= data_active$index_date & 
                                            data_active$event_date <= data_active$follow_up_end) &
                                           (data_active$event_date < data_active$exp_date_covid19_confirmed | is.na(data_active$exp_date_covid19_confirmed))))
    
    day_0_event_count <- length(which(data_active$event_date >= data_active$index_date &
                                        data_active$event_date == data_active$exp_date_covid19_confirmed & 
                                        data_active$event_date <= data_active$follow_up_end))
  }
  
  if(subgroup=="covid_pheno_hospitalised"){
    event_count_exposed <- length(which(data_active$event_date >= data_active$index_date &
                                          data_active$event_date >= data_active$exp_date_covid19_confirmed & 
                                          data_active$event_date <= data_active$hospitalised_follow_up_end))
    
    event_count_unexposed<- length(which((data_active$event_date >= data_active$index_date & 
                                            data_active$event_date <= data_active$hospitalised_follow_up_end) &
                                           (data_active$event_date < data_active$exp_date_covid19_confirmed | is.na(data_active$exp_date_covid19_confirmed))))
    
    day_0_event_count <- length(which(data_active$event_date >= data_active$index_date &
                                        data_active$event_date == data_active$exp_date_covid19_confirmed & 
                                        data_active$event_date <= data_active$hospitalised_follow_up_end))
  }
  
  if(subgroup=="covid_pheno_non_hospitalised"){
    event_count_exposed <- length(which(data_active$event_date >= data_active$index_date &
                                          data_active$event_date >= data_active$exp_date_covid19_confirmed & 
                                          data_active$event_date <= data_active$non_hospitalised_follow_up_end))
    
    event_count_unexposed<- length(which((data_active$event_date >= data_active$index_date & 
                                            data_active$event_date <= data_active$non_hospitalised_follow_up_end) &
                                           (data_active$event_date < data_active$exp_date_covid19_confirmed | is.na(data_active$exp_date_covid19_confirmed))))
    
    day_0_event_count <- length(which(data_active$event_date >= data_active$index_date &
                                        data_active$event_date == data_active$exp_date_covid19_confirmed &
                                        data_active$event_date <= data_active$non_hospitalised_follow_up_end))
    
  }
  
  if(day_0_event_count <= 5 | (event_count_exposed - day_0_event_count) <=5){
    day_0_event_count <- "[Redacted]"
  }
  
  if(event_count_unexposed <= 5){
    event_count_unexposed <- "[Redacted]"
  }
  
  if(event_count_exposed <= 5){
    event_count_exposed <- "[Redacted]"
  }
  
  return(list(person_days_total_unexposed, event_count_unexposed, event_count_exposed,person_days_total, day_0_event_count))
}


# Run function using specified commandArgs and active analyses for group

# active_analyses <- read_rds("lib/active_analyses.rds")
# active_analyses <- active_analyses %>% filter(active==TRUE)
# group <- unique(active_analyses$outcome_group)

if (cohort_name == "all") {
  table_2_subgroups_output("prevax")
  table_2_subgroups_output("vax")
  table_2_subgroups_output("unvax")
} else{
  table_2_subgroups_output(cohort_name)
}

# for(i in group){
#   if (cohort_name == "all") {
#     table_2_subgroups_output("prevax", i)
#     table_2_subgroups_output("vax", i)
#     table_2_subgroups_output("unvax", i)
#   } else{
#     table_2_subgroups_output(cohort_name, i)
#   }
# }