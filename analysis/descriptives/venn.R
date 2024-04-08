# Load libraries ---------------------------------------------------------------
print('Load libraries')

library(data.table)
library(readr)
library(dplyr)
library(stringr)

# Specify redaction threshold --------------------------------------------------

threshold <- 6

# Source common functions ------------------------------------------------------
print('Source common functions')

source("analysis/utility.R")

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  cohort <- "prevax"
} else {
  cohort <- args[[1]]
}

# Identify outcomes ------------------------------------------------------------
print('Identify outcomes')

active_analyses <- readr::read_rds("lib/active_analyses.rds")

outcomes <- gsub("out_date_","",
                 unique(active_analyses[active_analyses$cohort==cohort &
                                          active_analyses$analysis=="main",]$outcome))

# Load Venn data ---------------------------------------------------------------
print('Load Venn data')

venn <- readr::read_rds(paste0("output/venn_",cohort,".rds"))

# Load any dementia model ------------------------------------------------------

model_input_any_dementia <- readr::read_rds(paste0("output/model_input-cohort_",cohort,"-main-any_dementia.rds"))
model_input_any_dementia <- model_input_any_dementia[!is.na(model_input_any_dementia$out_date),c("patient_id","out_date")]

# rename columns ---------------------------------------------------------------
print("Rename temporary outcomes columns")

venn <- venn %>%
  rename_with(~ str_replace(., "tmp_out_date_alzheimer_", "tmp_out_date_alzheimer_disease_")) %>%
  rename_with(~ str_replace(., "tmp_out_date_parkinson_", "tmp_out_date_parkinson_disease_")) %>%
  rename_with(~ str_replace(., "out_date_lewy_body_dementia", "tmp_out_date_lewy_body_dementia_snomed")) %>%
  rename_with(~ str_replace(., "out_date_cognitive_impairment_symptoms", "tmp_out_date_cognitive_impairment_symptoms_snomed")) %>%
  rename_with(~ str_replace(., "out_date_restless_leg_syndrome", "tmp_out_date_restless_leg_syndrome_snomed"))

# Create empty output table ----------------------------------------------------
print('Create empty output table')

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
                 error = character(),
                 stringsAsFactors = FALSE)

# Populate Venn table for each outcome -----------------------------------------
print('Populate Venn table for each outcome')

for (outcome in outcomes) {
  
  print(paste0("Outcome: ", outcome))
  
  # Load model input data ------------------------------------------------------
  print('Load model input data')
  
  model_input <- readr::read_rds(paste0("output/model_input-cohort_",cohort,"-main-",outcome,".rds"))  
  model_input <- model_input[!is.na(model_input$out_date),c("patient_id","out_date")]
  
  if (nrow(model_input)>0) {
    
    # Filter Venn data based on model input --------------------------------------
    print('Filter Venn data based on model input')
    
    tmp <- venn[venn$patient_id %in% model_input$patient_id,
                c("patient_id",colnames(venn)[grepl(outcome,colnames(venn))])]
    
    colnames(tmp) <- gsub(paste0("tmp_out_date_",outcome,"_"),"",colnames(tmp))
    
    # Identify and add missing columns -------------------------------------------
    print('Identify and add missing columns')
    
    complete <- data.frame(patient_id = tmp$patient_id,
                           snomed = as.Date(NA),
                           hes = as.Date(NA),
                           death = as.Date(NA))
    
    complete[,setdiff(colnames(tmp),"patient_id")] <- NULL
    notused <- NULL
    
    if (ncol(complete)>1) {
      tmp <- merge(tmp, complete, by = c("patient_id"))
      notused <- setdiff(colnames(complete),"patient_id")
    }
    
    # Calculate the number contributing to each source combination ---------------
    print('Calculate the number contributing to each source combination')
    
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
    
    # Record the number contributing to each source combination ------------------
    print('Record the number contributing to each source combination')
    
    df[nrow(df)+1,] <- c(outcome,
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
                         total = nrow(tmp),
                         error = "")
    
    # Replace source combinations with NA if not in study definition -------------
    print('Replace source combinations with NA if not in study definition')
    
    source_combos <- c("only_snomed","only_hes","only_death","snomed_hes","snomed_death","hes_death","snomed_hes_death",
                       "total_snomed","total_hes","total_death")
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
    
  } else {
    
    # Record empty outcome -----------------------------------------------------
    print('Record empty outcome')
    
    df[nrow(df)+1,] <- c(outcome,
                         only_snomed = NA,
                         only_hes = NA,
                         only_death = NA,
                         snomed_hes = NA,
                         snomed_death = NA,
                         hes_death = NA,
                         snomed_hes_death = NA,
                         total_snomed = NA,
                         total_hes = NA,
                         total_death = NA,
                         total = NA,
                         error = "No outcomes in model input")
    
    
  }
  
}

# remove any_dementia outcome --------------------------------------------------

df <- df[!grepl("any_dementia", df$outcome),]
df_any <- df[grepl("any_dementia", df$outcome),]

# Filter columns of interest ---------------------------------------------------

venn_any <- venn %>%
  select_if(grepl("patient_id|tmp_out_date_alzheimer|tmp_out_date_other_dementias|tmp_out_date_unspecified_dementias|tmp_out_date_vascular_dementia|tmp_out_date_lewy_body|out_date_any_dementia", 
                  names(.))) %>%
  rename_at(vars(matches("tmp_out_date_")), ~ str_remove(., "tmp_out_date_"))

# Filter venn any dementia based on model input any dementia -------------------

tmp_any <- venn_any[venn_any$patient_id %in% model_input_any_dementia$patient_id,]

# Calculate the number contributing to each source combination -----------------

tmp_any$snomed_contributing <- !is.na(tmp_any$alzheimer_disease_snomed) & is.na(tmp_any$alzheimer_disease_hes) & 
  is.na(tmp_any$alzheimer_disease_death) |
  !is.na(tmp_any$vascular_dementia_snomed) & is.na(tmp_any$vascular_dementia_hes) & 
  is.na(tmp_any$vascular_dementia_death) |
  !is.na(tmp_any$other_dementias_snomed) & is.na(tmp_any$other_dementias_hes) & 
  is.na(tmp_any$other_dementias_death) |
  !is.na(tmp_any$unspecified_dementias_snomed) & is.na(tmp_any$unspecified_dementias_hes) & 
  is.na(tmp_any$unspecified_dementias_death) |
  !is.na(tmp_any$lewy_body_dementia_snomed)

tmp_any$hes_contributing <- is.na(tmp_any$alzheimer_disease_snomed) & !is.na(tmp_any$alzheimer_disease_hes) & 
  is.na(tmp_any$alzheimer_disease_death) |
  is.na(tmp_any$vascular_dementia_snomed) & !is.na(tmp_any$vascular_dementia_hes) & 
  is.na(tmp_any$vascular_dementia_death) |
  is.na(tmp_any$other_dementias_snomed) & !is.na(tmp_any$other_dementias_hes) & 
  is.na(tmp_any$other_dementias_death) |
  is.na(tmp_any$unspecified_dementias_snomed) & !is.na(tmp_any$unspecified_dementias_hes) & 
  is.na(tmp_any$unspecified_dementias_death) |
  is.na(tmp_any$lewy_body_dementia_snomed)

tmp_any$death_contributing <- is.na(tmp_any$alzheimer_disease_snomed) & is.na(tmp_any$alzheimer_disease_hes) & 
  !is.na(tmp_any$alzheimer_disease_death) |
  is.na(tmp_any$vascular_dementia_snomed) & is.na(tmp_any$vascular_dementia_hes) & 
  !is.na(tmp_any$vascular_dementia_death) |
  is.na(tmp_any$other_dementias_snomed) & is.na(tmp_any$other_dementias_hes) & 
  !is.na(tmp_any$other_dementias_death) |
  is.na(tmp_any$unspecified_dementias_snomed) & is.na(tmp_any$unspecified_dementias_hes) & 
  !is.na(tmp_any$unspecified_dementias_death) |
  is.na(tmp_any$lewy_body_dementia_snomed)

tmp_any$snomed_hes_contributing <- !is.na(tmp_any$alzheimer_disease_snomed) & !is.na(tmp_any$alzheimer_disease_hes) & 
  is.na(tmp_any$alzheimer_disease_death) |
  !is.na(tmp_any$vascular_dementia_snomed) & !is.na(tmp_any$vascular_dementia_hes) & 
  is.na(tmp_any$vascular_dementia_death) |
  !is.na(tmp_any$other_dementias_snomed) & !is.na(tmp_any$other_dementias_hes) & 
  is.na(tmp_any$other_dementias_death) |
  !is.na(tmp_any$unspecified_dementias_snomed) & !is.na(tmp_any$unspecified_dementias_hes) & 
  is.na(tmp_any$unspecified_dementias_death) |
  !is.na(tmp_any$lewy_body_dementia_snomed)

tmp_any$hes_death_contributing <- is.na(tmp_any$alzheimer_disease_snomed) & !is.na(tmp_any$alzheimer_disease_hes) & 
  !is.na(tmp_any$alzheimer_disease_death) |
  is.na(tmp_any$vascular_dementia_snomed) & !is.na(tmp_any$vascular_dementia_hes) & 
  !is.na(tmp_any$vascular_dementia_death) |
  is.na(tmp_any$other_dementias_snomed) & !is.na(tmp_any$other_dementias_hes) & 
  !is.na(tmp_any$other_dementias_death) |
  is.na(tmp_any$unspecified_dementias_snomed) & !is.na(tmp_any$unspecified_dementias_hes) & 
  !is.na(tmp_any$unspecified_dementias_death) |
  is.na(tmp_any$lewy_body_dementia_snomed)

tmp_any$snomed_death_contributing <- !is.na(tmp_any$alzheimer_disease_snomed) & is.na(tmp_any$alzheimer_disease_hes) & 
  !is.na(tmp_any$alzheimer_disease_death) |
  !is.na(tmp_any$vascular_dementia_snomed) & is.na(tmp_any$vascular_dementia_hes) & 
  !is.na(tmp_any$vascular_dementia_death) |
  !is.na(tmp_any$other_dementias_snomed) & is.na(tmp_any$other_dementias_hes) & 
  !is.na(tmp_any$other_dementias_death) |
  !is.na(tmp_any$unspecified_dementias_snomed) & is.na(tmp_any$unspecified_dementias_hes) & 
  !is.na(tmp_any$unspecified_dementias_death) |
  !is.na(tmp_any$lewy_body_dementia_snomed)

tmp_any$snomed_hes_death_contributing <- !is.na(tmp_any$alzheimer_disease_snomed) & !is.na(tmp_any$alzheimer_disease_hes) & 
  !is.na(tmp_any$alzheimer_disease_death) |
  !is.na(tmp_any$vascular_dementia_snomed) & !is.na(tmp_any$vascular_dementia_hes) & 
  !is.na(tmp_any$vascular_dementia_death) |
  !is.na(tmp_any$other_dementias_snomed) & !is.na(tmp_any$other_dementias_hes) & 
  !is.na(tmp_any$other_dementias_death) |
  !is.na(tmp_any$unspecified_dementias_snomed) & !is.na(tmp_any$unspecified_dementias_hes) & 
  !is.na(tmp_any$unspecified_dementias_death) |
  !is.na(tmp_any$lewy_body_dementia_snomed)

# Record the number contributing to each source combination --------------------
print('Record the number contributing to each source combination')

outcome_any_dementia <- "any_dementia"

df_any[nrow(df_any)+1,] <- c(outcome_any_dementia,
                             only_snomed = nrow(tmp_any %>% filter(snomed_contributing==T)),
                             only_hes = nrow(tmp_any %>% filter(hes_contributing==T)),
                             only_death = nrow(tmp_any %>% filter(death_contributing==T)),
                             snomed_hes = nrow(tmp_any %>% filter(snomed_hes_contributing==T)),
                             snomed_death = nrow(tmp_any %>% filter(snomed_death_contributing==T)),
                             hes_death = nrow(tmp_any %>% filter(hes_death_contributing==T)),
                             snomed_hes_death = nrow(tmp_any %>% filter(snomed_hes_death_contributing==T)),
                             total_snomed = nrow(tmp_any %>% filter(!is.na(snomed_contributing))), 
                             total_hes = nrow(tmp_any %>% filter(!is.na(hes_contributing))), 
                             total_death = nrow(tmp_any %>% filter(!is.na(death_contributing))), 
                             total = nrow(tmp_any), 
                             error = "")


# bind data frames -------------------------------------------------------------
df <- rbind(df, df_any)

# remove temporary data frame --------------------------------------------------
rm(df_any, tmp_any, venn_any)

# Record cohort ----------------------------------------------------------------
print('Record cohort')

df$cohort <- cohort

# Save Venn data ---------------------------------------------------------------
print('Save Venn data')

write.csv(df, paste0("output/venn_",cohort,".csv"), row.names = FALSE)

# Perform redaction ------------------------------------------------------------
print('Perform redaction')

df[,setdiff(colnames(df),c("outcome"))] <- lapply(df[,setdiff(colnames(df),c("outcome"))],
                                                  FUN=function(y){roundmid_any(as.numeric(y), to=threshold)})

# Rename columns (output redaction) --------------------------------------------

colnames(df)[2:12] <- paste(colnames(df)[2:12], "midpoint6", sep = "_")
names(df)[names(df) == "total_midpoint6"] <- "total_midpoint6_derived"

# Save rounded Venn data -------------------------------------------------------
print('Save rounded Venn data')

write.csv(df, paste0("output/venn_",cohort,"_midpoint6.csv"), row.names = FALSE)