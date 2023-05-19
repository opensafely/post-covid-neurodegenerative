# CREATE COMBINED (3 COHORT) TABLE 1A FOR POST-COVID MANUSCRIPTS

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

#Directories
results_dir <- "C:/Users/rs22981/Opensafely/Neuro/Release/20230408_tables/" #change according to your repo
output_dir <- "C:/Users/rs22981/Opensafely/Neuro/Release/20230408_tables/" #change according to your repo

###############################################
# 1. CLEAN TABLE 1 FUNCTION
###############################################

clean_table_1 <- function(df) {
  df <- df %>%
    rename('N (%)' = "N....", 'COVID-19 diagnoses' = "COVID.19.diagnoses") %>%
    separate(`N (%)`, into = c('N', '(%)'), sep = ' ') %>%
    mutate(`COVID-19 diagnoses` = scales::comma(`COVID-19 diagnoses`),
           N = scales::comma(as.numeric(N)),
           `(%)` = replace_na(`(%)`, "")) %>%
    unite(col = "N (%)", c("N", "(%)"), sep = " ") 
}

#Load files
table1_prevax <- read.csv(paste0(results_dir,"table1_prevax_rounded.csv"))
table1_unvax <- read.csv(paste0(results_dir,"table1_unvax_rounded.csv")) 
table1_vax <- read.csv(paste0(results_dir,"table1_vax_rounded.csv"))

#Apply clean table 1 function
table1_prevax_format <- clean_table_1(table1_prevax)
head(table1_prevax_format)
table1_vax_format <- clean_table_1(table1_vax)
table1_unvax_format <- clean_table_1(table1_unvax)

#Remove columns (Characteristic, Subcharacteristic) from vax and unvax
table1_vax_format <- table1_vax_format %>%
  select(-c(Characteristic,Subcharacteristic))
table1_unvax_format <- table1_unvax_format %>%
  select(-c(Characteristic,Subcharacteristic))

#Combine tables into 1
table1 <- bind_cols(list(table1_prevax_format, table1_vax_format, table1_unvax_format))

#Format table for Word
table1_format <- table1 %>%
  flextable::flextable() %>% theme_vanilla() %>% #theme could be removed
  padding(padding = 0, part = "all") %>% 
  merge_v(~ Characteristic) %>%
  add_header_row(values = c("", "", "Pre-vaccination cohort (Jan 1 2020 to Dec 14 2021)", "", "Vaccinated cohort (June 1 to Dec 14 2021)", "", "Unvaccinated cohort (June 1 to Dec 14 2021)", "")) %>%
  set_caption(as_paragraph(as_chunk("Table 1: Patient characteristics in the pre-vaccination, vaccinated and unvaccinated cohorts.", props = fp_text_default(bold = TRUE))),
              align_with_table = F) %>%
  set_header_labels("Subcharacteristic" = "", 'N (%)...3' = 'N (%)', 'COVID-19 diagnoses...4' = 'COVID-19 diagnoses', 'N (%)...5' = 'N (%)', 'COVID-19 diagnoses...6' = 'COVID-19 diagnoses', 
                    'N (%)...7' = 'N (%)', 'COVID-19 diagnoses...8' = 'COVID-19 diagnoses') %>%
  bold(j = 1, bold = TRUE, part = "body") %>%
  align(j = c(3:8), align = "right", part = "body") %>%
  fontsize(size = 9)

# Set table 1 properties 
sect_properties <- prop_section(
  page_size = page_size(
    orient = "landscape",
    width = 8.3, height = 11.7
  ),
  type = "continuous",
  page_margins = page_mar()
)

#Save table 1
save_as_docx(table1_format, path = paste0(output_dir, "table1_formatted.docx"), pr_section = sect_properties)

#Notes 
#While using word:
#1. Change margins to narrow.
#2. Merge vertically Characteristics and Sub characteristics with the upper cell, respectively.
#3. Merge horizontally Pre-vaccination, vaccionation and unvaccinated with the right cell, respectivelly.
#4. IF theme_vanilla is not used, you will need to add borders between each covariate, or remove unnecessary lines.
#5. Change font, CVD uses "Calibri".
