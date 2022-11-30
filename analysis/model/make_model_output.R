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
                        N_total = NA,
                        N_exposed = NA,
                        N_events = NA,
                        person_time_total = NA,
                        outcome_time_median = NA,
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
  
  df <- rbind(df,tmp)
}


# Add details from active analyses ---------------------------------------------
print('Add details from active analyses')

df[,c("exposure","outcome")] <- NULL

df <- merge(df, 
            active_analyses[,c("name","cohort","outcome","analysis")], 
            by = "name", all.x = TRUE)

df$outcome <- gsub("out_date_","",df$outcome)

# Apply disclosure control -----------------------------------------------------
print('Apply disclosure control')

## Set disclosure threshold

disclosure_threshold <- 5

## Apply controls to estimates

redact <- df[df$error=="",] %>%
  dplyr::group_by(name) %>%
  dplyr::mutate(min_total = min(N_total, na.rm = TRUE),
                min_exposed = min(N_total, na.rm = TRUE),
                min_events = min(N_events, na.rm = TRUE)) %>%
  dplyr::ungroup() %>%
  dplyr::select(name, min_total, min_exposed, min_events) %>%
  dplyr::distinct()

redact$action <- (redact$min_total <= disclosure_threshold) |
  (redact$min_exposed <= disclosure_threshold) |
  (redact$min_events <= disclosure_threshold)

df$lnhr <- ifelse(df$name %in% redact[redact$action==TRUE,]$name,"[redact]",df$lnhr)
df$se_lnhr <- ifelse(df$name %in% redact[redact$action==TRUE,]$name,"[redact]",df$se_lnhr)
df$conf_low <- ifelse(df$name %in% redact[redact$action==TRUE,]$name,"[redact]",df$conf_low)
df$conf_high <- ifelse(df$name %in% redact[redact$action==TRUE,]$name,"[redact]",df$conf_high)
df$N_total <- ifelse(df$name %in% redact[redact$action==TRUE,]$name,"[redact]",df$N_total)
df$N_exposed <- ifelse(df$name %in% redact[redact$action==TRUE,]$name,"[redact]",df$N_exposed)
df$N_events <- ifelse(df$name %in% redact[redact$action==TRUE,]$name,"[redact]",df$N_events)
df$person_time_total <- ifelse(df$name %in% redact[redact$action==TRUE,]$name,"[redact]",df$person_time_total)
df$outcome_time_median <- ifelse(df$name %in% redact[redact$action==TRUE,]$name,"[redact]",df$outcome_time_median)

# Save model output ------------------------------------------------------------
print('Save model output')

df <- df[,c("name","cohort","outcome","analysis","error","model","term",
            "lnhr","se_lnhr","hr","conf_low","conf_high",
            "N_total","N_exposed","N_events","person_time_total",
            "outcome_time_median","surv_formula")]

readr::write_csv(df, "output/model_output.csv")
