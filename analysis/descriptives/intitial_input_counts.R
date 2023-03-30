library(data.table)
library(dplyr)

#read datasets 
# prevax<-fread("output/input_prevax.csv.gz")
# vax<-fread("output/input_vax.csv.gz")
# unvax<-fread("output/input_unvax.csv.gz")

#after preprocessing data 
prevax<-readr::read_rds("output/input_prevax.rds")
vax<-readr::read_rds("output/input_vax.rds")
unvax<-readr::read_rds("output/input_unvax.rds")


#count non na outcome and covars events 
count_input<-function(df){
  out_cov_df<-df%>% 
    select(matches("^(out_date|cov_bin)"))
  sapply(out_cov_df, function(x) sum(!is.na(x) ))
  
}

# create a list of data frames
df_list <- list(prevax, vax, unvax)
count_list <- lapply(df_list, count_input)

count_df <- t(data.frame(do.call(rbind, count_list)))

colnames(count_df) <- c("prevax", "vax", "unvax")
write.table(count_df,quote=F,row.names=T,col.names=T,"output/study_counts_prepro.txt")

#summary data 
describe_data <- function(data) {
  file_name <- paste0("output/describe_prepro_", deparse(substitute(data)), ".txt")
  sink(file_name)
  print(Hmisc::describe(data))
  sink()
  message(paste0("Description of ", deparse(substitute(data)), " written to ", file_name, " successfully!"))
}

describe_data(prevax)
describe_data(vax)
describe_data(unvax)