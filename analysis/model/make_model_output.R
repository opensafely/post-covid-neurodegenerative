# Load packages ----------------------------------------------------------------
print('Load packages')

library(magrittr)

# Load active analyses ---------------------------------------------------------
print('Load active analyses')

active_analyses <- readr::read_rds("lib/active_analyses.rds")

# List available model outputs -------------------------------------------------
print('List available model outputs')

files <- list.files("output", pattern = "model_output-")

# Combine model outputs --------------------------------------------------------
print('Combine model outputs')

df <- NULL

for (i in files) {
  
  ## Load model output
  
  tmp <- readr::read_csv(paste0("output/",i))
  
  ## Handle errors
  
  if (colnames(tmp)[1] == "error") {
    
    dummy <- data.frame(model = "",
                        exposure = "",
                        outcome = gsub(".*-","",gsub(".csv","",i)),
                        term = "",
                        lnhr = NA,
                        se_lnhr = NA,
                        hr = NA,
                        conf_low = NA,
                        conf_high = NA,
                        N_total_midpoint6 = NA,
                        N_exposed_midpoint6 = NA,
                        N_events_midpoint6 = NA,
                        person_time_total = NA,
                        outcome_time_median = NA,
                        strata_warning = "",
                        surv_formula = "",
                        input = "",
                        error = tmp$error)
    
    tmp <- dummy
    
  } else {
    
    tmp$error <- ""
    
  }
  
  ## Add source file name
  
  tmp$name <- gsub("model_output-","",gsub(".csv","",i))
  
  ## Append to master dataframe
  
  #df <- rbind(df,tmp)
  df <- plyr::rbind.fill(df,tmp)
}


# Add details from active analyses ---------------------------------------------
print('Add details from active analyses')

df[,c("exposure","outcome")] <- NULL

df <- merge(df, 
            active_analyses[,c("name","cohort","outcome","analysis")], 
            by = "name", all.x = TRUE)

df$outcome <- gsub("out_date_","",df$outcome)

# Save model output ------------------------------------------------------------
print('Save model output')

df <- df[,c("name","cohort","outcome","analysis","error","model","term",
            "lnhr","se_lnhr","hr","conf_low","conf_high",
            "N_total","N_exposed","N_events","person_time_total",
            "outcome_time_median","strata_warning","surv_formula")]

readr::write_csv(df, "output/model_output.csv")


# Perform redaction ------------------------------------------------------------
print('Perform redaction')

df[,c("N_total","N_exposed","N_events")] <- lapply(df[,c("N_total","N_exposed","N_events")],
                                                                                 FUN=function(y){roundmid_any(as.numeric(y), to=threshold)})

# Rename columns (output redaction) --------------------------------------------

names(df)[names(df) == "N_total"] <- "N_total_midpoint6"
names(df)[names(df) == "N_exposed"] <- "N_exposed_midpoint6"
names(df)[names(df) == "N_events"] <- "N_events_midpoint6"

# Save model output ------------------------------------------------------------
print('Save model output')

readr::write_csv(df, "output/model_output_midpoint6.csv")