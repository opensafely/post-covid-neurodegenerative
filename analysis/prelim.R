#Load libraries using pacman
pacman::p_load(dplyr,tictoc,purrr,lubridate,glue,tidyverse,jsonlite,here,arrow)

#json file containing vax study dates
study_dates <- fromJSON("output/study_dates.json")
delta_date <- as.Date(study_dates$delta_date, format="%Y-%m-%d")
delta_end_date <- as.Date(study_dates$omicron_date, format="%Y-%m-%d")
all_eligible_date <- as.Date(study_dates$all_eligible,format="%Y-%m-%d")
# efficacy offset = 14 days (vaccination date + 14 days is generally considered the date at which someone starts receiving their protection from vaccine)
efficacy_offset <- 14 
# eligibility offset = 84 days (12 weeks ( 7*12), which is generally considered ample time to get vaccinated post eligibility)
eligibility_offset <- 84

#Read in the output of study_definition_prelim and add dates variables
prelim_data <- arrow::read_feather("output/input_prelim.feather") 
prelim_data <- prelim_data %>%
  mutate(across(c(contains("_date")), 
                ~ floor_date(
                  as.Date(., format="%Y-%m-%d"),
                  unit = "days"))) %>%
  mutate(vax_date_covid_2_offset = vax_date_covid_2 + days(efficacy_offset),
         vax_date_eligible_offset = vax_date_eligible + days(eligibility_offset),
         index_prevax = as.Date(study_dates$pandemic_start)) %>% 
  rowwise() %>%             
  mutate(index_vax = max(c(vax_date_covid_2_offset, delta_date), na.rm=T),
         index_unvax =  max(c(vax_date_eligible_offset, delta_date), na.rm=T),
         end_vax = min(c(death_date, delta_end_date), na.rm=T),
         end_unvax = min(c(death_date, delta_end_date), na.rm=T),
         end_prevax = min(c(vax_date_eligible,death_date, vax_date_covid_1, all_eligible_date), na.rm=T)) 


#Write data to csv file 
write_csv(prelim_data, "output/index_dates.csv")