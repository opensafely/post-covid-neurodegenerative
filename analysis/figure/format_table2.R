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

#Directories
results_dir <- "C:/Users/rs22981/GitHub/post-covid-neurodegenerative/output/" #change according to your repo
output_dir <- "C:/Users/rs22981/Opensafely/Table2_test/" #change according to your repo

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

#Load files
table2_prevax <- read.csv(paste0(results_dir,"table2_prevax_rounded.csv")) 
table2_unvax <- read.csv(paste0(results_dir,"table2_unvax_rounded.csv")) 
table2_vax <- read.csv(paste0(results_dir,"table2_vax_rounded.csv")) 

#Apply clean table 2 function --------------------------------------------------
table2_prevax_format <- clean_table_2(table2_prevax)
table2_vax_format <- clean_table_2(table2_vax)
table2_unvax_format <- clean_table_2(table2_unvax)

#Remove columns (period, outcom) from vax and unvax tables ---------------------
table2_vax_format <- table2_vax_format %>%
  select(-c(period, outcome))
table2_unvax_format <- table2_unvax_format %>%
  select(-c(period, outcome))

#Combine tables by columns -----------------------------------------------------
table2 <- bind_cols(list(table2_prevax_format, table2_vax_format, table2_unvax_format))

# Add labels, re-order rows, a clean names -------------------------------------

table2$period <- factor(table2$period, levels = c("No COVID-19",
                                                  "Hospitalised COVID-19",
                                                  "Non-hospitalised COVID-19"))
table2 <- table2[order(table2$outcome, table2$period),]

table2 <- table2 %>%
  rename_with(~ gsub("...", "", .x, fixed = T))

#Format table for Word ---------------------------------------------------------
table2_format <- table2 %>%
  flextable::flextable() %>% theme_vanilla() %>% #theme could be removed
  padding(padding = 0, part = "all") %>% 
  merge_v(~ outcome) %>%
  add_header_row(values = c("", "", "Pre-vaccination cohort (Jan 1 2020 to Dec 14 2021)", "", "Vaccinated cohort (June 1 to Dec 14 2021)", "", "Unvaccinated cohort (June 1 to Dec 14 2021)", "")) %>%
  set_caption(as_paragraph(as_chunk("Table 2. Number of arterial thrombotic, venous thrombotic, and other cardiovascular events in the pre-vaccination, vaccinated and unvaccinated cohorts, with person-years of follow-up, by COVID-19 severity. *Incidence rates are per 100,000 person-years", 
    props = fp_text_default(bold = TRUE))), align_with_table = F) %>%
  set_header_labels("outcome" = "Event", 'period' = 'COVID-19 severity', 
                    'Event/person-years3' = 'Event/person-years', 'Incidence rate*4' = 'Incidence rate*',
                    'Event/person-years5' = 'Event/person-years', 'Incidence rate*6' = 'Incidence rate*', 
                    'Event/person-years7' = 'Event/person-years', 'Incidence rate*8' = 'Incidence rate*') %>%
  bold(j = 1, bold = TRUE, part = "body") %>%
  align(j = c(3:8), align = "right", part = "body") %>%
  fontsize(size = 10)

# Set table 2 properties 
sect_properties <- prop_section(
  page_size = page_size(
    orient = "landscape",
    width = 8.3, height = 11.7
  ),
  type = "continuous",
  page_margins = page_mar()
)

#Save table 2
save_as_docx(table2_format, path = paste0(output_dir, "table2_formatted.docx"), pr_section = sect_properties)
#write.csv(table2, paste0(output_dir,"table2.csv"),row.names = F)

#Notes 
#While using word:
#1. Change margins to narrow.
#2. Merge horizontally Pre-vaccination, vaccionation and unvaccinated with the right cell, respectivelly.
#3. IF theme_vanilla is not used, you will need to add borders between each covariate, or remove unnecessary lines.
#4. Change font, CVD uses "Calibri".
