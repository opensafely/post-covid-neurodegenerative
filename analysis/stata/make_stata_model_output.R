# Load packages ----------------------------------------------------------------
print('Load packages')

library(magrittr)

# Specify redaction threshold --------------------------------------------------
print('Specify redaction threshold')

threshold <- 6

# Source common functions ------------------------------------------------------
print('Source common functions')

source("analysis/utility.R")

# List files to be combined ----------------------------------------------------
print('List files to be combined')

files <- list.files(path = "output/", pattern = "stata_model_output-.*\\.txt")

# Create empty master data frame -----------------------------------------------
print('Create empty master data frame')

df <- NULL

# Append each file to master data frame ----------------------------------------
print('Append each file to master data frame')

for (f in files) {
  
  print(paste0("File: ",f))
  
  # Load data ------------------------------------------------------------------
  print('Load data')
  
  stata_model_output <- readr::read_tsv(file = paste0("output/",f), skip = 2,
                                        col_names = c("term",
                                                      "b_min","se_min","t_min","lci_min","uci_min","p_min",
                                                      "b_max","se_max","t_max","lci_max","uci_max","p_max"))
  
  # Make variables numeric -----------------------------------------------------
  print('Make variables numeric')
  
  stata_model_output <- stata_model_output %>% 
    dplyr::mutate_at(setdiff(colnames(stata_model_output), "term"), as.numeric)
  
  # Extract other details ------------------------------------------------------
  print('Extract other details')
  
  tmp <- stata_model_output[stata_model_output$term %in% c("N_sub","risk"),
                            c("term","b_min","b_max")]
  
  # Transform data -------------------------------------------------------------
  print('Transform data')
  
  stata_model_output <- stata_model_output[(grepl("cov",stata_model_output$term) | 
                                              grepl("age",stata_model_output$term) |
                                              grepl("days",stata_model_output$term)), ]
  
  stata_model_output <- tidyr::pivot_longer(stata_model_output, cols = setdiff(colnames(stata_model_output), "term"))
  
  stata_model_output <- tidyr::separate(stata_model_output, col = "name", into = c("stat","model"))
  
  stata_model_output <- tidyr::pivot_wider(stata_model_output, id_cols = c("term","model"),names_from = "stat")
  
  stata_model_output <- stata_model_output[!is.na(stata_model_output$b),]
  
  # Add name -------------------------------------------------------------------
  print('Add name')
  
  stata_model_output$name <- gsub(".txt","",gsub("stata_model_output-","",f))
  
  # Add median fup -------------------------------------------------------------
  print('Add median fup')
  
  median_fup <- readr::read_csv(file = paste0("output/",gsub("_model_output","_fup",gsub(".txt",".csv",f))))
  
  median_fup <- dplyr::rename(median_fup,
                              "outcome_time_median" = "median_tte",
                              "N_events" = "events")
  
  stata_model_output <- merge(stata_model_output, 
                              median_fup, 
                              by = "term", 
                              all.x = TRUE)
  
  # Rename columns -------------------------------------------------------------
  print('Rename columns')
  
  stata_model_output <- dplyr::rename(stata_model_output,
                                      "lnhr" = "b",
                                      "se_lnhr" = "se")
  
  stata_model_output$model <- ifelse(stata_model_output$model=="max","mdl_max_adj",stata_model_output$model)
  stata_model_output$model <- ifelse(stata_model_output$model=="min","mdl_age_sex",stata_model_output$model)
  
  # Add other details ----------------------------------------------------------
  print('Add other details')
  
  tmp <- tidyr::pivot_longer(tmp, cols = setdiff(colnames(tmp), "term"), names_to = "model")
  
  tmp$model <- ifelse(tmp$model=="b_max","mdl_max_adj",tmp$model)
  tmp$model <- ifelse(tmp$model=="b_min","mdl_age_sex",tmp$model)
  
  tmp$term <- ifelse(tmp$term=="N_sub","N_total",tmp$term)
  tmp$term <- ifelse(tmp$term=="risk","person_time_total",tmp$term)
  
  tmp <- tidyr::pivot_wider(tmp, names_from = "term")
  stata_model_output <- merge(stata_model_output, tmp, by = "model", all.x = TRUE)
  
  # Merge to master data frame -------------------------------------------------
  print('Merge to master data frame')
  
  df <- rbind(df, stata_model_output)
  
}

# Add missing columns --------------------------------------------------------
print('Add missing columns')

df <- tidyr::separate(df, 
                      col = "name", 
                      into = c("cohort","analysis","outcome"), 
                      sep = "-", remove = FALSE)

df$cohort <- gsub("cohort_","",df$cohort)
df$hr <- exp(df$lnhr)
df$conf_low <- exp(df$lci)
df$conf_high <- exp(df$uci)
df$N_exposed <- NA
df$error <- ""
df$strata_warning <- ""
df$surv_formula <- ""

# Save model output ------------------------------------------------------------
print('Save model output')

df <- df[,c("name","cohort","outcome","analysis","error","model","term",
            "lnhr","se_lnhr","hr","conf_low","conf_high",
            "N_total","N_exposed","N_events","person_time_total",
            "outcome_time_median","strata_warning","surv_formula")]

readr::write_csv(df, "output/stata_model_output.csv")

# Perform redaction ------------------------------------------------------------
print('Perform redaction')

df[,c("N_total","N_exposed","N_events")] <- lapply(df[,c("N_total","N_exposed","N_events")],
                                                   FUN=function(y){roundmid_any(as.numeric(y), to=threshold)})
# Rename rounded columns -------------------------------------------------------
df<- df%>% 
  dplyr::rename(
    N_total_midpoint6 = N_total,
    N_exposed_midpoint6 = N_exposed,
    N_events_midpoint6 = N_events
  )
# Save model output ------------------------------------------------------------
print('Save model output')

readr::write_csv(df, "output/stata_model_output_midpoint6.csv")