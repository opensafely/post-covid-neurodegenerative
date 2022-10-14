## =============================================================================
#Based on script in vaccinated repo
## =============================================================================


###############################################
# 0. Load relevant libraries and read in data #
###############################################

#Load libraries using pacman
pacman::p_load(dplyr,tictoc,readr,stringr,tidyr,ggplot2,jsonlite,here,arrow)

#clear memory
rm(list=ls())

# Get dataset for either the vaccinated or electively unvaccinated subcohort
# Specify command arguments ----------------------------------------------------

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  # use for interactive testing
  cohort_name <- "all"
  
} else {
  cohort_name <- args[[1]]
}

fs::dir_create(here::here("output", "not-for-review"))
fs::dir_create(here::here("output", "review", "descriptives"))

#json file containing vax study dates
study_dates <- fromJSON("output/study_dates.json")
#vaccinattion program start date
vax_start_date<-as.Date(study_dates$vax1_earliest, format="%Y-%m-%d")

#reference date for mixed vaccine products
mixed_vax_threshold<-as.Date("2021-05-07")
#read date variables from json file
start_date_delta = as.Date(study_dates$delta_date, format="%Y-%m-%d")
end_date_delta = as.Date(study_dates$omicron_date, format="%Y-%m-%d") 

stage1 <- function(cohort_name){

    input <- read_rds(file.path("output", paste0("input_",cohort_name,".rds")))
    print(paste0(cohort_name,  " ", nrow(input), " rows in the input file"))
    
#Rename the index_date_vax/unvax/prevax to index_date   
    input<- input %>%
     rename(index_date=!!sym(paste0("index_date_",cohort_name))) %>%
      rename(end_date = !!sym(paste0("end_date_",cohort_name)))
    
   
      
    # NOTE: no censoring of end date for death/event at this stage
                           
    ######################################################
    # 1. Prepare all variables (re-factoring, re-typing) # 
    ######################################################
    
    # Handle missing values
    
    input$cov_cat_smoking_status <- replace(input$cov_cat_smoking_status, is.na(input$cov_cat_smoking_status),"M")
    input <- input %>% mutate(cov_cat_region = as.character(cov_cat_region)) %>%
                    mutate(cov_cat_region = replace_na(cov_cat_region, "Missing")) %>%
                    mutate(cov_cat_region = as.factor(cov_cat_region))
    
    # For categorical factors, specify references
    
    cat_factors <- colnames(input)[grepl("_cat_",colnames(input))]
    input[,cat_factors] <- lapply(input[,cat_factors], function(x) factor(x, ordered = FALSE))
    
    ## sub_cat_covid19_hospital
    input$sub_cat_covid19_hospital <- ordered(input$sub_cat_covid19_hospital, levels = c("non_hospitalised","hospitalised","no_infection"))
  
    ## cov_cat_ethnicity
    levels(input$cov_cat_ethnicity) <- list("Missing" = "0", "White" = "1", "Mixed" = "2", "South Asian" = "3", "Black" = "4", "Other" = "5")
    input$cov_cat_ethnicity <- ordered(input$cov_cat_ethnicity, levels = c("White","Mixed","South Asian","Black","Other","Missing"))
    
    ## cov_cat_deprivation
    levels(input$cov_cat_deprivation)[levels(input$cov_cat_deprivation)==1 | levels(input$cov_cat_deprivation)==2] <-"1-2 (most deprived)"
    levels(input$cov_cat_deprivation)[levels(input$cov_cat_deprivation)==3 | levels(input$cov_cat_deprivation)==4] <-"3-4"
    levels(input$cov_cat_deprivation)[levels(input$cov_cat_deprivation)==5 | levels(input$cov_cat_deprivation)==6] <-"5-6"
    levels(input$cov_cat_deprivation)[levels(input$cov_cat_deprivation)==7 | levels(input$cov_cat_deprivation)==8] <-"7-8"
    levels(input$cov_cat_deprivation)[levels(input$cov_cat_deprivation)==9 | levels(input$cov_cat_deprivation)==10] <-"9-10 (least deprived)"
    input$cov_cat_deprivation <- ordered(input$cov_cat_deprivation, levels = c("1-2 (most deprived)","3-4","5-6","7-8","9-10 (least deprived)"))
      
    ## cov_cat_region
    input$cov_cat_region <- relevel(input$cov_cat_region, ref = "East")
    
    ## cov_cat_smoking_status
    levels(input$cov_cat_smoking_status) <- list("Ever smoker" = "E", "Missing" = "M", "Never smoker" = "N", "Current smoker" = "S")
    input$cov_cat_smoking_status <- ordered(input$cov_cat_smoking_status, levels = c("Never smoker","Ever smoker","Current smoker","Missing"))
    
    ## cov_cat_bmi
    
    input$cov_cat_bmi_groups <- ordered(input$cov_cat_bmi_groups, levels = c("Healthy_weight", "Underweight", "Overweight", "Obese", "Missing"))
    
    ## cov_cat_sex
    levels(input$cov_cat_sex) <- list("Female" = "F", "Male" = "M")
    input$cov_cat_sex <- relevel(input$cov_cat_sex, ref = "Female")
    
    ## vax_cat_jcvi_group
    input$vax_cat_jcvi_group <- ordered(input$vax_cat_jcvi_group, levels = c("12","11","10","09","08","07","06","05","04","03","02","01","99"))
    
    ## vax_cat_product_*
    vax_cat_product_factors <- colnames(input)[grepl("vax_cat_product_",colnames(input))]
    input[,vax_cat_product_factors] <- lapply(input[,vax_cat_product_factors], function(x) ordered(x, levels = c("Pfizer","AstraZeneca","Moderna")))
    
    ## Set reference level for binary covariates
    bin_factors <- colnames(input)[grepl("cov_bin_",colnames(input))]
    input[,bin_factors] <- lapply(input[,bin_factors], function(x) factor(x, levels = c("FALSE","TRUE")))
    
    
    #####################
    # 2. Apply QA rules #
    #####################
   
    #Rule 1: Year of birth is after year of death or patient only has year of death
    input$rule1=NA
    input$rule1=((input$qa_num_birth_year > (format(input$death_date, format="%Y")) & is.na(input$qa_num_birth_year)== FALSE & is.na(input$death_date) == FALSE)|(is.na(input$qa_num_birth_year)== TRUE & is.na(input$death_date) == FALSE))
    
    #Rule 2: Year of birth predates NHS established year or year of birth exceeds current date
    input$rule2=NA
    input$rule2=((input$qa_num_birth_year <1793 |(input$qa_num_birth_year >format(Sys.Date(),"%Y"))) & is.na(input$qa_num_birth_year) == FALSE)
    
    #Rule 3: Date of death is NULL or invalid (on or before 1/1/1900 or after current date)
    input$rule3=NA
    input$rule3=((input$death_date <=as.Date(study_dates$earliest_expec)|input$death_date > format(Sys.Date(),"%Y-%m-%d")) & is.na(input$death_date) == FALSE)
    
    #Rule 4: Pregnancy/birth codes for men
    input$rule4=NA
    input$rule4=(input$qa_bin_pregnancy == TRUE & input$cov_cat_sex=="Male")
    
    #Rule 5: HRT or COCP meds for men
    input$rule5=NA
    input$rule5=((input$cov_cat_sex=="Male" & input$cov_bin_hormone_replacement_therapy==TRUE)|(input$cov_cat_sex=="Male" & input$cov_bin_combined_oral_contraceptive_pill==TRUE))
    
    #Rule 6: Prostate cancer codes for women
    input$rule6=NA
    input$rule6=(input$qa_bin_prostate_cancer == TRUE & input$cov_cat_sex=="Female")
    
    #Remove rows that are TRUE for at least one rule
    input_QA=input%>%filter(rule1==FALSE & rule2==FALSE & rule3==FALSE & rule4==FALSE & rule5==FALSE & rule6==FALSE)
    input_QA=input_QA %>% select(-c(rule1,rule2,rule3,rule4,rule5,rule6))
    # View(input_QA)
    
    #Save QA'd input as .rds
    #saveRDS(QA_summary,file = "output/QA_input.rds")
    
    #QA summary
    QA_summary <- data.frame(rule = character(),
                             n_exclude = numeric())
    
    QA_summary[nrow(QA_summary)+1,] <- c("Rule 1: Year of birth is after year of death or patient only has year of death",
                                         nrow(input%>%filter(rule1==T)))
    
    QA_summary[nrow(QA_summary)+1,] <- c("Rule 2: Year of birth predates NHS established year or year of birth exceeds current date",
                                         nrow(input%>%filter(rule2==T)))
    
    QA_summary[nrow(QA_summary)+1,] <- c("Rule 3: Date of death is NULL or invalid (on or before 1/1/1900 or after current date)",
                                         nrow(input%>%filter(rule3==T)))
    
    QA_summary[nrow(QA_summary)+1,] <- c("Rule 4: Pregnancy/birth codes for men",
                                         nrow(input%>%filter(rule4==T)))
    
    QA_summary[nrow(QA_summary)+1,] <- c("Rule 5: HRT or COCP meds for men",
                                         nrow(input%>%filter(rule5==T)))
    
    QA_summary[nrow(QA_summary)+1,] <- c("Rule 6: Prostate cancer codes for women",
                                         nrow(input%>%filter(rule6==T)))
    
    QA_summary[nrow(QA_summary)+1,] <- c("Total excluded from QA",
                                         nrow(input)-nrow(input_QA))
    
    #Save Qa summary as .csv
    write.csv(QA_summary, file = file.path("output/review/descriptives", paste0("QA_summary_",cohort_name,  ".csv")) , row.names=F)
    
    # Remove QA variables from dataset
    input <- input_QA[ , !names(input_QA) %in% c("qa_num_birth_year", "qa_bin_pregnancy", "qa_bin_prostate_cancer")]
    
    print(paste0(cohort_name,  " ", nrow(input), " rows in the input file after QA"))
    
    #########################################
    # 3. Apply exclusion/inclusion criteria #
    #########################################
    # (Differentiate criteria for the two sub-cohorts)
    
    # Define the cohort flow
    cohort_flow <- data.frame(N = numeric(),
                              N_removed = numeric(),
                              Description = character(),
                              stringsAsFactors = FALSE)
    cohort_flow[nrow(cohort_flow)+1,] <- c(as.numeric(as.numeric(nrow(input)) + as.numeric(QA_summary[nrow(QA_summary),"n_exclude"])), 0, "Study defined sample size before QA checks")
    
    cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input), as.numeric(QA_summary[nrow(QA_summary),"n_exclude"]) ,"Study defined sample size after QA checks")
    
    #----------------------------------------------------------------#
    # 3.a. Apply the 6 common criteria applicable to both sub-cohort #
    #----------------------------------------------------------------#
    
    #Inclusion criteria 1: Alive on the first day of follow up
    input <- input %>% filter(index_date < death_date | is.na(death_date))
    cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 1 (Inclusion): Alive on the first day of follow up") # Feed into the cohort flow
   
    #Inclusion criteria 2: Known age between 18 and 110 on 01/06/2021 
    input <- subset(input, input$cov_num_age >= 18) # Subset input if age between 18 and 110 on 01/06/2021.
    cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 2a (Inclusion): Aged 18 and over on index date") # Feed into the cohort flow
    
    input <- subset(input, input$cov_num_age <= 110) # Subset input if age between 18 and 110 on 01/06/2021.
    cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 2b (Inclusion): Aged 110 and under on index date") # Feed into the cohort flow
    
    #Inclusion criteria 3: Known sex
    input <- input[!is.na(input$cov_cat_sex),] # removes NAs, if any
    cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 3 (Inclusion): Known sex")
    
    #Inclusion criteria 4: Known deprivation 
    input <- input[!is.na(input$cov_cat_deprivation),] # removes NAs, if any
    cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 4 (Inclusion): Known deprivation")
    
    #Inclusion criteria 5: Registered in an English GP with TPP software for at least 6 months prior to the study start date
    input <- subset(input, input$has_follow_up_previous_6months == TRUE)
    cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 5 (Inclusion): Registered in an English GP with TPP software for at least 6 months prior to the study start date")
    
    #Inclusion criteria 6: Not deregistered 
    input <- input %>%
      filter(is.na(dereg_date))
    #cohort_flow <- rbind(cohort_flow,c(nrow(input),as.numeric(cohort_flow[(nrow(input)-1),1]) - nrow(input)))
    cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 6 (Exclusion): Not deregistered from all support practices between index and end of study date")
    
    #Inclusion criteria 7: Known region
    input <- input %>% mutate(cov_cat_region = as.character(cov_cat_region)) %>%
      filter(cov_cat_region != "Missing")%>%
      mutate(cov_cat_region = as.factor(cov_cat_region))
    
    input$cov_cat_region <- relevel(input$cov_cat_region, ref = "East")
    cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 7 (Inclusion): Known region")
    
    # A simple check if factor reference level has changed
    describe_vars <- tidyselect::vars_select(names(input), contains(c('_cat_', 'cov_bin','cov_cat','qa_bin','exp_cat','vax_cat', 'step'), ignore.case = TRUE))
    meta_data_factors <- lapply(input[,c(describe_vars)], table)
    
    
    
    #-------------------------------------------------#
    # 3.b. Apply criteria specific to each sub-cohort #
    #-------------------------------------------------#
    
    if (cohort_name == "vax") {
        
      #Exclusion criteria 8: Do not have a record of two vaccination doses prior to the study end date
      input$vax_gap <- input$vax_date_covid_2 - input$vax_date_covid_1 #Determine the vaccination gap in days : gap is NA if any vaccine date is missing
      input <- input[!is.na(input$vax_gap),] # Subset the fully vaccinated group
      cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 8 (Exclusion): No record of two vaccination doses prior to the study end date") # Feed into the cohort flow
      
      #Exclusion criteria 9: Received a vaccination prior to 08-12-2020 (i.e., the start of the vaccination program)
      input <- subset(input, input$vax_date_covid_1 >= vax_start_date&input$vax_date_covid_2 >= vax_start_date)
      cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 9 (Exclusion): Recorded vaccination prior to the start date of vaccination program")
      
      #Exclusion criteria 10: Received a second dose vaccination before their first dose vaccination
      input <- subset(input, input$vax_gap >= 0) # Keep those with positive vaccination gap
      cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 10 (Exclusion): Second dose vaccination recorded before the first dose vaccination")
      
      #Exclusion criteria 11: Received a second dose vaccination less than three weeks after their first dose
      input <- subset(input, input$vax_gap >= 21) # Keep those with at least 3 weeks vaccination gap
      cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 11 (Exclusion): Second dose vaccination recorded less than three weeks after the first dose")
      
      #Exclusion criteria 12: Mixed vaccine products received before 07-05-2021
      # Trick to run the mixed vaccine code on dummy data with limited levels -> To ensure that the levels are the same in vax_cat_product variables
      
      input <- input %>%
        mutate(AZ_date = ifelse(vax_date_AstraZeneca_1 < mixed_vax_threshold, 1,
                                ifelse(vax_date_AstraZeneca_2 < mixed_vax_threshold, 1,
                                       ifelse(vax_date_AstraZeneca_3 < mixed_vax_threshold, 1, 0)))) %>%
        mutate(Moderna_date = ifelse(vax_date_Moderna_1 < mixed_vax_threshold, 1,
                                ifelse(vax_date_Moderna_2 < mixed_vax_threshold, 1,
                                       ifelse(vax_date_Moderna_3 < mixed_vax_threshold, 1, 0)))) %>%
        mutate(Pfizer_date = ifelse(vax_date_Pfizer_1 < mixed_vax_threshold, 1,
                                ifelse(vax_date_Pfizer_2 < mixed_vax_threshold, 1,
                                       ifelse(vax_date_Pfizer_3 < mixed_vax_threshold, 1, 0)))) %>%
        rowwise() %>%
        mutate(vax_mixed = sum(across(c("AZ_date", "Moderna_date", "Pfizer_date")), na.rm = T)) %>%
        dplyr::filter(vax_mixed < 2)
      
  
      cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 12 (Exclusion): Received mixed vaccine products before 07-05-2021")
      
      #Inclusions criteria 13: Index date is before cohort end date - will remove anyone who is not fully vaccinated by the cohort end date
      input <- input %>% filter (!is.na(index_date) & index_date <= end_date & index_date >= start_date_delta)
      cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 13 (Inclusion): Patient index date is within the study start and end dates i.e patient is fully vaccinated before the study end date")
      
      
    } else if (cohort_name == "unvax"){
     
      
      #Exclusion criteria 8: Have a record of one or more vaccination prior index date
      # i.e. Have a record of a first vaccination prior index date (no more vax 2 and 3 variables available in this dataset)
      #a.Determine the vaccination status on index start date
      input$prior_vax1 <- ifelse(input$vax_date_covid_1 <= input$index_date, 1,0)
      input$prior_vax1[is.na(input$prior_vax1)] <- 0
      
      input <- subset(input, input$prior_vax1 == 0) #Exclude people with prior vaccination
      cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[9,1]) - nrow(input), "Criteria 8 (Exclusion): Have a record of a first vaccination prior index date")
      
      #Exclusion criteria 9: Missing JCVI group
      input <- subset(input, vax_cat_jcvi_group == "01" | vax_cat_jcvi_group == "02" | vax_cat_jcvi_group == "03" | vax_cat_jcvi_group == "04" |
                        vax_cat_jcvi_group == "05" | vax_cat_jcvi_group == "06" | vax_cat_jcvi_group == "07" | vax_cat_jcvi_group == "08" |
                        vax_cat_jcvi_group == "09" | vax_cat_jcvi_group == "10" | vax_cat_jcvi_group == "11" | vax_cat_jcvi_group == "12")
      cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 9 (Exclusion): Missing or unknown JCVI group")
      
      #Inclusions criteria 10: Index date is before cohort end date - will remove anyone whose eligibility date + 84 days is after study end date (only those with unknown JCVI group)
      input <- input %>% filter (!is.na(index_date) & index_date <= end_date & index_date >= start_date_delta)
      cohort_flow[nrow(cohort_flow)+1,] <- c(nrow(input),as.numeric(cohort_flow[nrow(cohort_flow),"N"]) - nrow(input), "Criteria 10 (Inclusion): Patient index date is within the study start and end dates i.e patients eligibility date + 84 days is before the study end date")
      
    }
    
    print(paste0(cohort_name, " " , nrow(input), " rows in the input file after cohort specificinclusion criteria"))
    
    
    
    print(paste0(cohort_name, " ", nrow(input), " rows in the input file after common inclusion criteria"))
    #-------------------------------------------------#
    # 3.c. Apply outcome specific exclusions criteria
    #-------------------------------------------------#
     ####INSERT OUTCOME SPECIFIC EXCLUSION HERE#######    


    
    # NB: write.csv is not feasible to output list with uneven length
    sink(file = file.path("output/not-for-review", paste0("meta_data_factors_",cohort_name, ".csv")))
    print(meta_data_factors)
    sink()
    #----------------------#
    # 3.d. Create csv file #
    #----------------------#
    write.csv(cohort_flow, file = file.path("output/review/descriptives", paste0("Cohort_flow_",cohort_name, ".csv")) , row.names=F)
    
    #--------------------------#
    # 3.e. Generate histograms #
    #--------------------------#
    # generate histograms for numerical variables
    
    numeric_vars <- input %>% dplyr::select(contains("_num"))
    numeric_title <- colnames(numeric_vars)
    
    svglite::svglite(file = file.path("output/not-for-review/", paste0("numeric_histograms_", cohort_name, "_",  ".svg")), width = 15, height = 8)
    g <- ggplot(gather(numeric_vars), aes(value)) + 
      geom_histogram(bins = 10) + 
      facet_wrap(~key, scales = 'free_x')
    print(g)
    dev.off()

    #-------------------------------------#
    # 4. Create the final stage 1 dataset #
    #-------------------------------------#
    
    # Remove inclusion/exclusion variables from dataset
    input <- input[ , !names(input) %in% c("start_alive", "vax_gap", "vax_mixed", "vax_prior_unknown", "prior_vax1")]
    
    saveRDS(input, file = file.path("output", paste0("input_",cohort_name, "_stage1",".rds")))

}

# Run function using outcome group


if (cohort_name == "all") {
  stage1("prevax")
  stage1("vax")
  stage1("unvax")
} else{
  stage1(cohort_name)
}

