# Load packages ----------------------------------------------------------------
print('Load packages')

library(magrittr)
library(data.table)

# Source functions -------------------------------------------------------------
print('Source functions')

source("analysis/model/fn-check_vitals.R")

# Make directory ---------------------------------------------------------------
print('Make directory')

fs::dir_create(here::here("output", "model_input"))

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  # name <- "all" # prepare datasets for all active analyses 
  name <- "cohort_prevax-main" # prepare datasets for all active analyses whose name contains X
  # name <- "vax-depression-main;vax-depression-sub_covid_hospitalised;vax-depression-sub_covid_nonhospitalised" # prepare datasets for specific active analyses
} else {
  name <- args[[1]]
}

# Load active analyses ---------------------------------------------------------
print('Load active analyses')

active_analyses <- readr::read_rds("lib/active_analyses.rds")

# Identify model inputs to be prepared -----------------------------------------
print('Identify model inputs to be prepared')

if (name=="all") {
  prepare <- active_analyses$name
} else if(grepl(";",name)) {
  prepare <- stringr::str_split(as.vector(name), ";")[[1]]
} else {
  prepare <- active_analyses[grepl(name,active_analyses$name),]$name
}

# Filter active_analyses to model inputs to be prepared ------------------------
print('Filter active_analyses to model inputs to be prepared')

active_analyses <- active_analyses[active_analyses$name %in% prepare,]

for (i in 1:nrow(active_analyses)) {
  
  # Load data --------------------------------------------------------------------
  print(paste0("Load data for ",active_analyses$name[i]))
  
  input <- readr::read_rds(paste0("output/input_",active_analyses$cohort[i],"_stage1.rds"))
  
  # Restrict to required variables -----------------------------------------------
  print('Restrict to required variables')
  
  #history_components <- colnames(input)[grepl("cov_bin_recent",colnames(input)) | grepl("cov_bin_history",colnames(input))]
  
  input <- input[,unique(c("patient_id",
                           "index_date",
                           "end_date_exposure",
                           "end_date_outcome",
                           active_analyses$exposure[i], 
                           active_analyses$outcome[i],
                           unlist(strsplit(active_analyses$strata[i], split = ";")),
                           unlist(strsplit(active_analyses$covariate_other[i], split = ";")),#[!grepl("_priorhistory_",unlist(strsplit(active_analyses$covariate_other[i], split = ";")))],
                           "sub_cat_covid19_hospital",
                           "sub_bin_covid19_confirmed_history",
                           "cov_cat_sex",
                           "cov_num_age",
                           "cov_cat_ethnicity"))]#,
  #history_components))]
  
  # Remove outcomes outside of follow-up time ------------------------------------
  print('Remove outcomes outside of follow-up time')
  
  input <- dplyr::rename(input, 
                         "out_date" = active_analyses$outcome[i],
                         "exp_date" = active_analyses$exposure[i])
  
  input <- input %>% 
    dplyr::mutate(out_date = replace(out_date, which(out_date>end_date_outcome | out_date<index_date), NA),
                  exp_date =  replace(exp_date, which(exp_date>end_date_exposure | exp_date<index_date), NA),
                  sub_cat_covid19_hospital = replace(sub_cat_covid19_hospital, which(is.na(exp_date)),"no_infection"))
  
  # Update end date to be outcome date where applicable ------------------------
  print('Update end date to be outcome date where applicable')
  
  input <- input %>% 
    dplyr::rowwise() %>% 
    dplyr::mutate(end_date_outcome = min(end_date_outcome, out_date, na.rm = TRUE))
  
  # Make model input: main -------------------------------------------------------
  
  if (active_analyses$analysis[i]=="main") {
    
    print('Make model input: main')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_covid_hospitalised -------------------------------------
  
  if (active_analyses$analysis[i]=="sub_covid_hospitalised") {
    
    print('Make model input: sub_covid_hospitalised')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE,]
    
    df <- df %>% 
      dplyr::mutate(end_date_outcome = replace(end_date_outcome, which(sub_cat_covid19_hospital=="non_hospitalised"), exp_date-1),
                    exp_date = replace(exp_date, which(sub_cat_covid19_hospital=="non_hospitalised"), NA),
                    out_date = replace(out_date, which(out_date>end_date_outcome), NA))
    
    df <- df[df$end_date_outcome>=df$index_date,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_covid_nonhospitalised ----------------------------------
  
  if (active_analyses$analysis[i]=="sub_covid_nonhospitalised") {
    
    print('Make model input: sub_covid_nonhospitalised')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE,]
    
    df <- df %>% 
      dplyr::mutate(end_date_outcome = replace(end_date_outcome, which(sub_cat_covid19_hospital=="hospitalised"), exp_date-1),
                    exp_date = replace(exp_date, which(sub_cat_covid19_hospital=="hospitalised"), NA),
                    out_date = replace(out_date, which(out_date>end_date_outcome), NA))
    
    df <- df[df$end_date_outcome>=df$index_date,]
    df$index_date <- as.Date(df$index_date)
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_covid_history ------------------------------------------
  
  if (active_analyses$analysis[i]=="sub_covid_history") {
    
    print('Make model input: sub_covid_history')
    
    df <- input[input$sub_bin_covid19_confirmed_history==TRUE,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_sex_female ---------------------------------------------
  
  
  if (active_analyses$analysis[i]=="sub_sex_female") {
    
    print('Make model input: sub_sex_female')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_sex=="Female",]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_sex")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_sex_male -----------------------------------------------
  
  if (active_analyses$analysis[i]=="sub_sex_male") {
    
    print('Make model input: sub_sex_male')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_sex=="Male",]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_sex")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_age_18_39 ----------------------------------------------
  
  if (active_analyses$analysis[i]=="sub_age_18_39") {
    
    print('Make model input: sub_age_18_39')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_num_age>=18 &
                  input$cov_num_age<40,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_age_40_59 ----------------------------------------------
  
  if (active_analyses$analysis[i]=="sub_age_40_59") {
    
    print('Make model input: sub_age_40_59')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_num_age>=40 &
                  input$cov_num_age<60,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_age_60_79 ----------------------------------------------
  
  if (active_analyses$analysis[i]=="sub_age_60_79") {
    
    print('Make model input: sub_age_60_79')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_num_age>=60 &
                  input$cov_num_age<80,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_age_80_110 ---------------------------------------------
  
  if (active_analyses$analysis[i]=="sub_age_80_110") {
    
    print('Make model input: sub_age_80_110')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_num_age>=80 &
                  input$cov_num_age<111,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_ethnicity_white --------------------------------------
  
  if (active_analyses$analysis[i]=="sub_ethnicity_white") {
    
    print('Make model input: sub_ethnicity_white')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_ethnicity=="White",]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_ethnicity_black --------------------------------------
  
  if (active_analyses$analysis[i]=="sub_ethnicity_black") {
    
    print('Make model input: sub_ethnicity_black')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_ethnicity=="Black",]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_ethnicity_mixed ----------------------------------------
  
  if (active_analyses$analysis[i]=="sub_ethnicity_mixed") {
    
    print('Make model input: sub_ethnicity_mixed')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_ethnicity=="Mixed",]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_ethnicity")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_ethnicity_asian --------------------------------------
  
  if (active_analyses$analysis[i]=="sub_ethnicity_asian") {
    
    print('Make model input: sub_ethnicity_asian')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_ethnicity=="South Asian",]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_ethnicity")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_ethnicity_other ----------------------------------------
  
  if (active_analyses$analysis[i]=="sub_ethnicity_other") {
    
    print('Make model input: sub_ethnicity_other')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_ethnicity=="Other",]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_ethnicity")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_male_age_18_39 -----------------------------------------
  
  if (active_analyses$analysis[i]=="sub_male_age_18_39") {
    
    print('Make model input: sub_male_age_18_39')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_sex=="Male" & 
                  input$cov_num_age>=18 &
                  input$cov_num_age<40,]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_sex")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_male_age_40_59 -----------------------------------------
  
  if (active_analyses$analysis[i]=="sub_male_age_40_59") {
    
    print('Make model input: sub_male_age_40_59')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_sex=="Male" & 
                  input$cov_num_age>=40 &
                  input$cov_num_age<60,]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_sex")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_male_age_60_79 -----------------------------------------
  
  if (active_analyses$analysis[i]=="sub_male_age_60_79") {
    
    print('Make model input: sub_male_age_60_79')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_sex=="Male" & 
                  input$cov_num_age>=60 &
                  input$cov_num_age<80,]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_sex")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_male_age_80_110 ----------------------------------------
  
  if (active_analyses$analysis[i]=="sub_male_age_80_110") {
    
    print('Make model input: sub_male_age_80_110')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_sex=="Male" & 
                  input$cov_num_age>=80 &
                  input$cov_num_age<111,]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_sex")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_female_age_18_39 ---------------------------------------
  
  if (active_analyses$analysis[i]=="sub_female_age_18_39") {
    
    print('Make model input: sub_female_age_18_39')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_sex=="Female" & 
                  input$cov_num_age>=18 &
                  input$cov_num_age<40,]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_sex")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_female_age_40_59 ---------------------------------------
  
  if (active_analyses$analysis[i]=="sub_male_age_40_59") {
    
    print('Make model input: sub_female_age_40_59')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_sex=="Female" & 
                  input$cov_num_age>=40 &
                  input$cov_num_age<60,]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_sex")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_female_age_60_79 ---------------------------------------
  
  if (active_analyses$analysis[i]=="sub_female_age_60_79") {
    
    print('Make model input: sub_female_age_60_79')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_sex=="Female" & 
                  input$cov_num_age>=60 &
                  input$cov_num_age<80,]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_sex")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_female_age_80_110 --------------------------------------
  
  if (active_analyses$analysis[i]=="sub_female_age_80_110") {
    
    print('Make model input: sub_female_age_80_110')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_sex=="Female" & 
                  input$cov_num_age>=80 &
                  input$cov_num_age<111,]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_sex")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
}