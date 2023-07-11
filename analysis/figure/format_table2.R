# CREATE COMBINED (3 COHORT) TABLE 2 FOR POST-COVID MANUSCRIPTS

###############################################
# 0. Load relevant libraries and read in data #
###############################################

library(readr)
library(dplyr)
library(data.table)
library(tidyverse)
library(flextable)
library(officer)
library(scales)
library(broman)
library(huxtable)

#Directories
results_dir <- "C:/Users/rs22981/GitHub/post-covid-neurodegenerative/output/" #change according to your repo
output_dir <- "C:/Users/rs22981/Opensafely/Table2_test/" #change according to your repo

results_dir <- "C:/Users/rs22981/Opensafely/Table2_test/"

###############################################
# 1. CLEAN TABLE 2 FUNCTION
###############################################

clean_table_2 <- function(df) {
  
  df <- df %>%
    mutate(outcome = str_remove(outcome, "out_date_")) %>% 
    mutate(outcome = str_to_title(outcome)) %>%
    select(outcome, analysis, unexposed_person_days, unexposed_events, exposed_person_days, exposed_events, total_person_days, total_events, day0_events, total_exposed, sample_size) %>%
    filter(analysis %in% c("sub_covid_hospitalised", "sub_covid_nonhospitalised"))
  
  df$outcome <- str_replace_all(df$outcome, "_", " ")
  
  #unexposed
  df_unexposed <- df %>% select(outcome, analysis, unexposed_person_days,	unexposed_events)
  df_unexposed$period <- "unexposed"
  df_unexposed <- df_unexposed %>% rename(event_count = unexposed_events,
                                         person_days = unexposed_person_days)
  
  #exposed
  df_exposed <- df %>% select(outcome, analysis, exposed_person_days,	exposed_events)
  df_exposed$period <- "exposed"
  df_exposed <- df_exposed %>% rename(event_count = exposed_events,
                                      person_days = exposed_person_days)
  
  #bind rows
  table2 <- rbind(df_unexposed, df_exposed)
  rm(df_unexposed, df_exposed)

  table2 <- table2 %>% mutate(across(c("event_count","person_days"), as.numeric))
  
  # Add in incidence rate
  table2[,"Incidence rate*"] <- add_commas(round((table2$event_count/(table2$person_days/365.25))*100000))
  table2[,"Event/person-years"] <- paste0(add_commas(table2$event_count), "/", add_commas(round((table2$person_days/365.25))))
  
  table2$period <- ifelse(table2$period == "unexposed", "No COVID-19", table2$period)
  table2$period <- ifelse(table2$period == "exposed" & table2$analysis == "sub_covid_hospitalised", "Hospitalised COVID-19", table2$period)
  table2$period <- ifelse(table2$period == "exposed" & table2$analysis == "sub_covid_nonhospitalised", "Non-hospitalised COVID-19", table2$period)
  
  table2[,c("analysis","person_days")] <- NULL
  table2 <- table2[!duplicated(table2),]

  # Re-order columns -----------------------------------------------------------
  table2 <- table2 %>% select("outcome","period","Event/person-years","Incidence rate*")

  return(table2)
  
}

# Read datasets before preprocessing
dataset_names <- c("prevax", "vax", "unvax")
#Load datasets as list
df_list_t2 <- lapply(dataset_names, function(name) read.csv(paste0(results_dir, "table2_", name, "_rounded.csv")))


#Apply clean table 1 function
table2 <- lapply(df_list_t2, clean_table_2) %>% 
  #Combine tables into 1
  bind_cols() %>%
  #remove repeated columns: Characteristics and sub-characteristics from vax and unvax
  select(-c(5:6, 9:10),)

# Add labels, re-order rows, a clean names -------------------------------------
table2 <- table2 %>%
  #rename all columns (part 1)
  rename_with(~ gsub("...", "", .x, fixed = T)) %>%
  #rename 2 columns(part 2)
  rename("Event/person-years" = "Event/person-years3",
         "Incidence rate*" = "Incidence rate*4")
#Reorder rows
table2$period2 <- factor(table2$period2, levels = c("No COVID-19",
                                                  "Hospitalised COVID-19",
                                                  "Non-hospitalised COVID-19"))
table2 <- table2[order(table2$outcome1, table2$period2),]
#Remove column names (according to CVD manuscript)
colnames(table2)[1:2] <- ""

#Format table for Word ---------------------------------------------------------
#Huxtable + flextable
table2_format <- table2 %>%
  as_huxtable() %>%
  #Rows will change according to each repo
  merge_repeated_rows(col = 1) %>%
  theme_article() %>%
  insert_row(c("Event", "COVID-19 severity", "Pre-vaccination cohort (N=18,210,937)", "", "Vaccinated cohort (N=13,572,399)", "", "Unvaccinated cohort (N=3,161,485)"), fill = "", after = 0) %>%
  set_top_border(1) %>%
  set_bold(1:2, 1:8, TRUE) %>%
  #Change type of events according to each repo
  set_caption("Table 2: Number neurodegenerative events in the pre-vaccination, vaccinated and unvaccinated cohorts, with person-years of follow-up, by COVID-19 severity. *Incidence rates are per 100,000 person-years") 

#Save table 2 
quick_docx(table2_format, file = paste0(output_dir, "table2_formatted.docx"))

#Note
#While using word: apply table2 format from CVD manuscript.
