# Modified from https://github.com/opensafely/waning-ve-2dose-1year/blob/main/analysis/dummy_data_vax.R
# And https://github.com/opensafely/post-covid-vaccinated/blob/main/analysis/modify_dummy_vax_data.R

# Set seed ---------------------------------------------------------------------
set.seed(1)

# Change first jab date so that they have roughly correct distribution  
df_vax<- df %>%
  mutate(
    vax_date_Pfizer_1 = as.Date(vax_date_eligible) + days(round(rnorm(nrow(.), mean = 10, sd = 3))),
    vax_date_AstraZeneca_1 = as.Date(vax_date_eligible) + days(round(rnorm(nrow(.), mean = 10, sd = 3))),
    vax_date_Moderna_1 = as.Date(vax_date_eligible) + days(round(rnorm(nrow(.), mean = 10, sd = 3)))
  ) %>%
  #Pick one vaccine type
  mutate(
    vaccine_1_type = sample(
      x = c("Pfizer", "AstraZeneca", "Moderna",  "None"),
      size = nrow(.),
      replace = TRUE,
      prob = c(0.4, 0.4, 0.05, 0.1)
    ),
    # jabs missingness probabilities 
    missing_pfizer_2 = rbernoulli(nrow(.), p=0.05),
    missing_az_2 = rbernoulli(nrow(.), p=0.05),
    missing_moderna_2 = rbernoulli(nrow(.), p=0.05),
    missing_pfizer_3 = rbernoulli(nrow(.), p=0.9),
    missing_az_3 = rbernoulli(nrow(.), p=0.9),
    missing_moderna_3 = rbernoulli(nrow(.), p=0.9)
  )%>%
  #Set first jab date according to type and set others to NA 
  mutate(across(vax_date_Pfizer_1,
                ~if_else(
                  vaccine_1_type %in% "Pfizer",
                  .x,
                  NA_Date_))) %>%
  mutate(across(vax_date_AstraZeneca_1,
                ~if_else(
                  vaccine_1_type %in% "AstraZeneca",
                  .x,
                  NA_Date_))) %>%
  mutate(across(vax_date_Moderna_1,
                ~if_else(
                  vaccine_1_type %in% "Moderna",
                  .x,
                  NA_Date_))) %>%
  
  mutate(across(matches("vax_date\\w+_1"),
                ~ if_else(
                  vaccine_1_type %in% "None",
                  NA_Date_,
                  .x
                ))) %>%
  
  #Change date for the second jab
  mutate(
    vax_date_Pfizer_2 = vax_date_Pfizer_1 + days(round(rnorm(nrow(.), mean = 10*7, sd = 3))),
    vax_date_AstraZeneca_2 = vax_date_AstraZeneca_1 + days(round(rnorm(nrow(.), mean = 10*7, sd = 3))),
    vax_date_Moderna_2 = vax_date_Moderna_1  + days(round(rnorm(nrow(.), mean = 10*7, sd = 3))),
  ) %>%
  
  # Set 2nd vaccine type
  mutate(vaccine_2_type =  ifelse(runif(nrow(df),0,1)>0.95 & vaccine_1_type!="None",
                                  sample(
                                    x = c("Pfizer", "AstraZeneca", "Moderna",  "None"),
                                    size = nrow(.),
                                    replace = TRUE,
                                    prob = c(0.4, 0.4, 0.05, 0.1)
                                  ),
                                  vaccine_1_type)
  ) %>%
  
  #Set second jab date according to type and set others to NA 
  
  mutate(across(vax_date_Pfizer_2,
                ~if_else(
                  vaccine_2_type %in% "Pfizer",
                  .x,
                  NA_Date_))) %>%
  mutate(across(vax_date_AstraZeneca_2,
                ~if_else(
                  vaccine_2_type %in% "AstraZeneca",
                  .x,
                  NA_Date_))) %>%
  mutate(across(vax_date_Moderna_2,
                ~if_else(
                  vaccine_1_type %in% "Moderna",
                  .x,
                  NA_Date_))) %>%
  
  mutate(across(matches("vax_date\\w+_2"),
                ~ if_else(
                  vaccine_2_type %in% "None",
                  NA_Date_,
                  .x
                ))) %>%
  
  # Set to NA if jab is missing
  mutate(across(vax_date_Pfizer_2,
                ~if_else(
                  missing_pfizer_2,
                  NA_Date_,
                  .x))) %>%
  mutate(across(vax_date_AstraZeneca_2,
                ~if_else(
                  missing_az_2,
                  NA_Date_,
                  .x))) %>%
  mutate(across(vax_date_Moderna_2,
                ~if_else(
                  missing_moderna_2,
                  NA_Date_,
                  .x))) %>%
  
  #Set 3rd jab type
  mutate(vaccine_3_type =  ifelse( vaccine_2_type!="None",
                                   sample(
                                     x = c("Pfizer", "AstraZeneca" ,"Moderna",  "None"),
                                     size = nrow(.),
                                     replace = TRUE,
                                     prob = c(0.6, 0.1, 0.3, 0.1)
                                   ),vaccine_2_type
  )
  ) %>%
  
  #Change 3rd jab date
  mutate(
    vax_date_Pfizer_3 = vax_date_Pfizer_2 + days(round(rnorm(nrow(.), mean = 6*4*7, sd = 7))),
    vax_date_AstraZeneca_3 = vax_date_AstraZeneca_2 + days(round(rnorm(nrow(.), mean = 6*4*7, sd = 7))),
    vax_date_Moderna_3 = vax_date_Moderna_2 + days(round(rnorm(nrow(.), mean = 6*4*7, sd = 7))),
  ) %>%
  
  #Set 3rd jab date according to type and set others to NA 
  
  mutate(across(vax_date_Pfizer_3,
                ~if_else(
                  vaccine_3_type %in% "Pfizer",
                  .x,
                  NA_Date_))) %>%
  mutate(across(vax_date_AstraZeneca_3,
                ~if_else(
                  vaccine_3_type %in% "AstraZeneca",
                  .x,
                  NA_Date_))) %>%
  mutate(across(vax_date_Moderna_3,
                ~if_else(
                  vaccine_1_type %in% "Moderna",
                  .x,
                  NA_Date_))) %>%
  
  mutate(across(matches("vax_date\\w+_3"),
                ~ if_else(
                  vaccine_3_type %in% "None",
                  NA_Date_,
                  .x
                ))) %>%
  # Set to NA if jab is missing
  mutate(across(vax_date_Pfizer_3,
                ~if_else(
                  missing_pfizer_3,
                  NA_Date_,
                  .x))) %>%
  mutate(across(vax_date_AstraZeneca_3,
                ~if_else(
                  missing_az_3,
                  NA_Date_,
                  .x))) %>%
  mutate(across(vax_date_Moderna_3,
                ~if_else(
                  missing_moderna_3,
                  NA_Date_,
                  .x)))%>%
  
  select(-starts_with("missing"),-matches("vaccine_\\d_type"))