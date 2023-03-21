check_vitals <- function(df) {
  
  # Confirm patient ID is complete
  
  if (nrow(df)!=nrow(df[!is.na(df$patient_id),])) {
    stop("Patient ID is not present for everyone in the dataset")
  }
  
  # Confirm vital dates are present in dataset and have date format
  
  for (i in c("index_date","exp_date","end_date_exposure","end_date_outcome","out_date")) {
    if (!(i %in% colnames(df))) {
      stop(paste0(i," is not in dataset"))
    } else {
      if (sapply(df[,i], lubridate::is.Date)==FALSE) {
        stop(paste0(i," does not have a date format"))
      }
    }
  }
  
  # Confirm cov_cat_region is present in the dataset
  
  if (!("cov_cat_region" %in% colnames(df))) {
    stop("cov_cat_region is not in dataset")
  } 
  
  # Confirm cov_bin_* variables are two level factors
  
  for (i in colnames(df)[grepl("cov_bin_",colnames(df))]) {
    if (sapply(df[,i], is.factor)==FALSE) {
      stop(paste0(i," is not a factor"))
    } else {
      if (length(sapply(df[,i], levels))!=2) {
        stop(paste0(i," does not have two levels (levels = ",length(sapply(df[,i], levels)),")"))
      }
    }
  }
  
  # Confirm cov_cat_* variables are factors
  
  for (i in colnames(df)[grepl("cov_cat_",colnames(df))]) {
    if (sapply(df[,i], is.factor)==FALSE) {
      stop(paste0(i," is not a factor"))
    }
  }
  
}