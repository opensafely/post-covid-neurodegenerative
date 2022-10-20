## =============================================================================
## Project:     Post covid vaccinated project
##
##
## Purpose: 
##  Apply stage 2. Create missing data, range and descriptive statistics tables
##  - Table 0 - Missing data and range
##  - Table 1 - Descriptive statistics
## 
## Authors: Genevieve Cezard, Rochelle Knight
## Combined by: Genevieve Cezard
## Reviewer: Yinghui Wei
## 
## Content: 
## 0. Load relevant libraries and read data/arguments
## 1. Output missing data  and range check tables
## 2. Output table 1
## 
## NOTE: This code outputs 3 .csv files and 1 R dataset
##       Output files have a specific name to reflect either the Vaccinated 
##       or Electively unvaccinated cohort
##
## =============================================================================

###############################################
# 0. Load relevant libraries and read in data #
###############################################
library(readr)
library(dplyr)
library(data.table)
library(tidyverse)
library(lubridate)
library(stringr)

# Specify command arguments ----------------------------------------------------

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  cohort_name <- "all" # interactive testing
  #group <- "Mental_health"
} else {
  cohort_name <- args[[1]]
}

fs::dir_create(here::here("output", "not-for-review"))
fs::dir_create(here::here("output", "review", "descriptives"))

# Determine which outcome groups are active
active_analyses <- read_rds("lib/active_analyses.rds")
#active_analyses <- active_analyses %>% filter(active == TRUE)
outcome_groups <- unique(active_analyses$outcome)#outcome_group

cohort_start_date_prevax <- as.Date("2020-01-01")
cohort_end_date_prevax <- as.Date("2021-06-18")

cohort_start_date_delta <- as.Date("2021-06-01")
cohort_end_date_delta <- as.Date("2021-12-14")

# Define stage2 function -------------------------------------------------------

stage2 <- function(cohort_name, covid_history, group) {#, group
  
  # Load relevant data
  input <- readr::read_rds(file.path("output", paste0("input_",cohort_name,"_stage1",".rds")))#cohort_name,"_stage1_",group,
  
  # Select data depending on covid history
  if(covid_history == "without_covid_history"){
    input <- filter(input, sub_bin_covid19_confirmed_history==F)
  }
  if(covid_history == "with_covid_history"){
    input <- filter(input, sub_bin_covid19_confirmed_history==T)
  }
  
  ################################
  # 1. Output missing data table #
  ################################
  
  N <- nrow(input)
  
  #-----------------------------------------------------------------------#
  # 1.a. Create a table with missing data information (N,%) for variables #
  #-----------------------------------------------------------------------#
  
  covariate_names <- tidyselect::vars_select(names(input), starts_with(c('sub_bin_','cov_','qa_','vax_cat','exp_cat'), ignore.case = TRUE))
  check_missing <- data.frame(variable = as.vector(covariate_names), N_missing = NA)
  
  for (i in covariate_names){
    if (is.factor(input[,i])) {
      check_missing[check_missing$variable==i,]$N_missing <- nrow(input[input[,i]=="Missing",])
    } else {
      check_missing[check_missing$variable==i,]$N_missing <- nrow(input[is.na(input[,i]),])
    }
  }
  
  check_missing$Perc_missing <- 100*(check_missing$N_missing/N)
  
  #---------------------------------------------------------------#
  # 1.b. Create a table with min and max for numerical covariates #
  #---------------------------------------------------------------#
  
  check_range <- data.frame(variable = character(), Minimum_value = character(), Maximum_value = character())
  numeric_var_names=colnames(select_if(input, is.numeric))
  numeric_var_names = numeric_var_names [!numeric_var_names == "patient_id"]
  
  for (i in numeric_var_names){
    check_range[nrow(check_range)+1,1] <- i
    check_range[nrow(check_range),2] <- min(na.omit(input %>% dplyr::select(i)))
    check_range[nrow(check_range),3] <- max(na.omit(input %>% dplyr::select(i)))
  }
  
  #---------------------------------------------------------------------------#
  # 1.a. c. Output table merging missing and range information for covariates #
  #---------------------------------------------------------------------------#
  
  check_both <- merge(x=check_missing, y=check_range, by = "variable",all.x=TRUE)
  write.csv(check_both, file = file.path("output/not-for-review", paste0("Check_missing_range_",cohort_name, "_",covid_history, ".csv")) , row.names=F)
  
  #---------------------------------------------------------#
  # 1.d. Create a table with min and max for date variables #
  #---------------------------------------------------------#
  
  check_dates <- data.frame(variable = character(), Earliest_date = character(), Latest_date = character())
  date_variables_names <- colnames(select_if(input, is.Date))
  input_date <- input[,date_variables_names]
  
  for (i in date_variables_names){
    date_var <- input_date %>% pull(i)
    check_dates[nrow(check_dates)+1,1] <- i
    check_dates[nrow(check_dates),2] <- paste0("",min(na.omit(date_var)))
    check_dates[nrow(check_dates),3] <- paste0("",max(na.omit(date_var)))
  }
  
  write.csv(check_dates, file = file.path("output/not-for-review", paste0("Check_dates_range_",cohort_name, "_",covid_history, ".csv")) , row.names=F)#cohort_name, "_",covid_history, 
  
  #####################
  # 2. Output table 1 #
  #####################
  
  #Define populations of interest
  
  pop <- data.frame(rbind(c("Whole_population","!is.na(input$patient_id)"),
                          c("COVID_exposed","!is.na(input$exp_date_covid19_confirmed)"),
                          c("COVID_hospitalised","!is.na(input$exp_date_covid19_confirmed) & input$sub_cat_covid19_hospital=='hospitalised'"),
                          c("COVID_non_hospitalised","!is.na(input$exp_date_covid19_confirmed) & input$sub_cat_covid19_hospital=='non_hospitalised'")),
                    stringsAsFactors = FALSE)
  
  # pop <- data.frame(rbind(c("Whole_population","!is.na(input$patient_id)"),
  #                         c("COVID_exposed","is.na(input$exp_date_covid19_confirmed)==F"),
  #                         c("COVID_hospitalised","input$sub_cat_covid19_hospital=='hospitalised'"),
  #                         c("COVID_non_hospitalised","input$sub_cat_covid19_hospital=='non_hospitalised'")),
  #                   stringsAsFactors = FALSE)
  
  colnames(pop) <- c("name","condition")
  
  # Define age groups
  
  input$cov_cat_age_group <- ""
  input$cov_cat_age_group <- ifelse(input$cov_num_age>=18 & input$cov_num_age<=29, "18-29", input$cov_cat_age_group)
  input$cov_cat_age_group <- ifelse(input$cov_num_age>=30 & input$cov_num_age<=39, "30-39", input$cov_cat_age_group)
  input$cov_cat_age_group <- ifelse(input$cov_num_age>=40 & input$cov_num_age<=49, "40-49", input$cov_cat_age_group)
  input$cov_cat_age_group <- ifelse(input$cov_num_age>=50 & input$cov_num_age<=59, "50-59", input$cov_cat_age_group)
  input$cov_cat_age_group <- ifelse(input$cov_num_age>=60 & input$cov_num_age<=69, "60-69", input$cov_cat_age_group)
  input$cov_cat_age_group <- ifelse(input$cov_num_age>=70 & input$cov_num_age<=79, "70-79", input$cov_cat_age_group)
  input$cov_cat_age_group <- ifelse(input$cov_num_age>=80 & input$cov_num_age<=89, "80-89", input$cov_cat_age_group)
  input$cov_cat_age_group <- ifelse(input$cov_num_age>=90, "90+", input$cov_cat_age_group)
  
  # Define consultation rate groups
  
  input$cov_cat_consulation_rate_group <- ""
  input$cov_cat_consulation_rate_group <- ifelse(input$cov_num_consulation_rate==0, "0", input$cov_cat_consulation_rate_group)
  input$cov_cat_consulation_rate_group <- ifelse(input$cov_num_consulation_rate>=1 & input$cov_num_consulation_rate<=5, "1 to 6", input$cov_cat_consulation_rate_group) #1-6
  input$cov_cat_consulation_rate_group <- ifelse(input$cov_num_consulation_rate>=6, "6+", input$cov_cat_consulation_rate_group)
  
  #Restrict COVID exposures to within study dates
  
  if (cohort_name == "prevax") {
    
    input <- input %>% mutate(exp_date_covid19_confirmed = replace(exp_date_covid19_confirmed, which(exp_date_covid19_confirmed>cohort_end_date_prevax | exp_date_covid19_confirmed<cohort_start_date_prevax), NA))
    
  } else if (cohort_name == "unvax" | cohort_name == "vax"){
    
    input <- input %>% mutate(exp_date_covid19_confirmed = replace(exp_date_covid19_confirmed, which(exp_date_covid19_confirmed>cohort_end_date_delta | exp_date_covid19_confirmed<cohort_start_date_delta), NA))
    
  }
  
  # Populate table 1 
  covar_names <- active_analyses %>% filter(outcome==group) #CHECK #outcome_group
  covar_names<-str_split(active_analyses$covariates, ";")[[1]]
  
  #categorical_cov <- colnames(input)[grep("cov_cat", colnames(input))]
  categorical_cov <- covar_names[grep("cov_cat", covar_names)]
  categorical_cov <- append(categorical_cov, c("cov_cat_age_group","cov_cat_consulation_rate_group"))
  
  #numerical_cov <- colnames(input)[grep("cov_num", colnames(input))]
  numerical_cov <- covar_names[grep("cov_num", covar_names)]
  #numerical_cov <- numerical_cov[!numerical_cov=="cov_num_age"]
  
  #binary_cov <- colnames(input)[grep("cov_bin", colnames(input))]
  binary_cov <- covar_names[grep("cov_bin", covar_names)]
  binary_cov_table <- crossing(covar_names[grep("cov_bin", covar_names)], c("TRUE","FALSE"))
  colnames(binary_cov_table) <- c("Covariate","Covariate_level")
  
  # Base table
  
  table1 <- input %>% 
    dplyr::select(c(categorical_cov,numerical_cov))
  
  table1 <- table1 %>% 
    mutate_if(is.character,as.factor)
  
  table1 <- table1 %>% 
    mutate_if(is.logical,as.factor)
  
  table1 <- as.data.frame(summary(table1,maxsum=50))
  
  table1 <- rename(table1, Covariate_level = Freq, Covariate = Var2)
  
  #table1 <- table1 %>% 
  #  filter(!str_detect(Covariate_level, "^FALSE"))
  
  table1  <- table1 %>% 
    dplyr::select("Covariate","Covariate_level")
  
  table1$Covariate <- gsub("\\s","",table1$Covariate) # Remove spaces
  
  table1$Covariate_level <-  sub('\\:.*', '', table1$Covariate_level) # Remove everything after :
  
  # table1 <- table1 %>%
  #   filter(!(Covariate == "cov_num_consulation_rate" & !Covariate_level=="Mean   ")) #%>%
  #   #filter(!(Covariate == "cov_num_tc_hdl_ratio" & !Covariate_level=="Mean   "))
  
  table1 <- table1 %>%
    filter(!(Covariate == "cov_num_age" & !Covariate_level=="Mean   ")) %>%
    filter(!(Covariate == "cov_num_consulation_rate" & !Covariate_level=="Mean   ")) #%>%
  # filter(!(Covariate == "cov_num_bmi" & !Covariate_level=="Mean   ")) %>%
  # filter(!(Covariate == "cov_num_tc_hdl_ratio" & !Covariate_level=="Mean   "))
  
  table1_count_all <- as.data.frame(matrix(nrow = 1, ncol = 2))
  colnames(table1_count_all) <- c("Covariate","Covariate_level")
  table1_count_all[1,] <- c("All","All")
  table1 <- rbind(table1_count_all,table1)
  table1 <- table1[!is.na(table1$Covariate_level),]
  table1 <- rbind(table1, binary_cov_table)
  
  for (j in 1:nrow(pop)) {
    
    population <- pop[j,]$name
    
    df <- subset(input, eval(parse(text = pop[j,]$condition)))
    
    # Count population size
    
    pop_summary <- data.frame(matrix(ncol=3))
    colnames(pop_summary) <- c("Covariate","Covariate_level",population)
    pop_summary[1,] <- c("All","All",nrow(df))
    
    # Categorical covariates
    
    cat_pop <- df %>% dplyr::select(categorical_cov)
    cat_pop <- cat_pop %>% mutate_if(is.character,as.factor)
    cat_summary <- as.data.frame(summary(cat_pop,maxsum=50))
    cat_summary[,population] <- cat_summary$Freq
    cat_summary <- rename(cat_summary, Covariate_level = Freq, Covariate = Var2)
    cat_summary <- cat_summary %>% 
      dplyr::select("Covariate","Covariate_level",population)
    
    # Numerical covariates
    
    num_pop <- df %>% dplyr::select(numerical_cov)
    num_summary <- as.data.frame(summary(num_pop))
    num_summary[,population] <- num_summary$Freq
    num_summary <- rename(num_summary, Covariate_level = Freq, Covariate = Var2)
    num_summary <- num_summary %>% dplyr::select("Covariate","Covariate_level",population)
    num_summary <- num_summary %>% filter(startsWith(num_summary$Covariate_level, "Mean")==T)
    
    # Binary covariates
    
    bin_pop <- df %>% dplyr::select(binary_cov)
    bin_pop <- bin_pop %>% mutate_if(is.logical,as.factor)
    bin_summary <- as.data.frame(summary(bin_pop))
    bin_summary[,population] <- bin_summary$Freq
    bin_summary <- rename(bin_summary, Covariate_level = Freq, Covariate = Var2)
    #bin_summary <- bin_summary %>% filter(str_detect(Covariate_level, "^TRUE"))
    bin_summary <- bin_summary%>% dplyr::select("Covariate","Covariate_level",population)
    bin_summary$Covariate_level <- gsub("\\s","",bin_summary$Covariate_level) #Remove spaces
    
    # Population summary
    
    pop_summary <- rbind(pop_summary,cat_summary,num_summary,bin_summary)
    
    # Tidy summary table
    
    pop_summary$Covariate <- gsub("\\s","",pop_summary$Covariate) #Remove spaces
    pop_summary$Covariate_level <- sub('\\:.*', '', pop_summary$Covariate_level) #Remove everything after :
    
    pop_summary[,population] <- gsub(".*:", "",pop_summary[,population])#Remove everything before:
    pop_summary <- pop_summary %>% drop_na(Covariate_level)#Remove rows with NA
    unique(pop_summary$Covariate_level)
    
    # Left join onto base table
    
    table1 <- left_join(table1,pop_summary, by=c("Covariate","Covariate_level"))
    
  }
  
  # PRINT MEAN AND SD FOR NUMERIC VARS
  
  print(summary(input[numeric_var_names]))
  print(sd(input$cov_num_age))
  print(sd(input$cov_num_consulation_rate))
  # print(sd(input$cov_num_bmi))
  # print(sd(input$cov_num_tc_hdl_ratio))
  
  # print(s)
  
  # Tidy table 1
  
  table1$Covariate <- gsub("cov_bin_", "History of ",table1$Covariate)
  table1$Covariate <- gsub("cov_\\D\\D\\D_", "",table1$Covariate)
  table1$Covariate <- gsub("_", " ",table1$Covariate)
  
  # Add in suppression controls for counts <=5 and then alter totals accordingly
  table1_suppressed <- table1[0,]
  
  for(i in unique(table1$Covariate[which(!startsWith(table1$Covariate_level, "Mean"))])){
    df<- table1 %>% filter(Covariate == i)
    df <- df %>% mutate(across(!c("Covariate","Covariate_level"),as.numeric))
    df$No_infection <- df$Whole_population - df$COVID_exposed
    
    if(any(df$COVID_hospitalised <= 5 | df$COVID_non_hospitalised <= 5 | is.na(df$COVID_hospitalised)| is.na(df$COVID_non_hospitalised))){
      df$COVID_hospitalised <- "[Redacted]"
      df$COVID_non_hospitalised <- "[Redacted]"
    }
    
    if(any(df$COVID_exposed <= 5 | df$No_infection <=5 | is.na(df$COVID_exposed) | is.na(df$No_infection))){
      df$COVID_exposed <- "[Redacted]"
    }
    
    if(any(df$Whole_population <= 5 | is.na(df$Whole_population))){
      df$Whole_population <- "[Redacted]"
    }
    
    df <- df %>% mutate(across(!c("Covariate","Covariate_level"),as.character))
    df$No_infection <- NULL
    
    if(i == "consulation rate group"){
      df <- rbind(df, table1 %>% filter(startsWith(Covariate_level, "Mean")))
    }
    
    table1_suppressed <- rbind(table1_suppressed,df)
    
  }
  #table1_suppressed[which(startsWith(table1_suppressed$Covariate_level, "Mean")),] <- table1[startsWith(table1$Covariate_level, "Mean"),]
  table1_suppressed <- table1_suppressed %>% filter(!str_detect(Covariate_level, "^FALSE"))
  
  # CAPITALISE COV COLUMN FOR AESTHETICS
  
  table1_suppressed$Covariate <- str_to_sentence(table1_suppressed$Covariate)
  
  # Save table 1
  write.csv(table1_suppressed, file = file.path("output/review/descriptives", paste0("Table1_",cohort_name, "_",covid_history,"_",group,".csv")) , row.names=F)#covid_history,"_",group, 
  
  print(paste0("Table 1 ran and saved succesfully for ", cohort_name, " ", group, " ", covid_history))
  
}

# Run function using specified commandArgs
# Only generate Table 1 for the main Diabetes analyses for the paper
# Probably won't include subgroup Table 1's.

# Run function using specified commandArgs

# if(cohort_name == "all"){
#   stage2("prevax", "with_covid_history")
#   stage2("prevax", "without_covid_history")
#   stage2("vax", "with_covid_history")
#   stage2("vax", "without_covid_history")
#   stage2("unvax", "with_covid_history")
#   stage2("unvax", "without_covid_history")
# }else{
#   stage2(cohort_name, "with_covid_history")
#   stage2(cohort_name, "without_covid_history")
# }

for(group in outcome_groups){#
  if(cohort_name == "all"){
    stage2("prevax", "with_covid_history", group)
    stage2("prevax", "without_covid_history", group)
    stage2("vax", "with_covid_history", group)
    stage2("vax", "without_covid_history", group)
    stage2("unvax", "with_covid_history", group)
    stage2("unvax", "without_covid_history", group)
  }else{
    stage2(cohort_name, "with_covid_history", group)
    stage2(cohort_name, "without_covid_history", group)
  }
  
}