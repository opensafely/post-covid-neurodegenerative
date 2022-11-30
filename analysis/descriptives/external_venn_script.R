## =============================================================================
## Purpose:  Create venn diagrams outside of OpenSAFELY environment using check number dataframe (CSV)
## 
## Author:   Kurt Taylor
## Updated by: Jose Ignacio Cuitun Coronado
## Reviewer: 
##
## Date:     27th May 2022
##
## Data:     Post covid projects
##
## Content:  to create a Venn diagram for each outcome outlining overlap in 
##           reporting from different data sources
## Output:   Venn diagrams in SVG files
## =============================================================================

# Load libraries ----------------------------------------------------------

# library 
library(VennDiagram)
library(dplyr)
library(gridExtra)

# Read file ---------------------------------------------------------------

df <- read.csv("output/review/venn-diagrams/venn_diagram_number_check_prevax.csv")

active_analyses <- readr::read_rds("lib/active_analyses.rds")

# list of outcomes to loop over 
outcomes <- df$outcome

# Create Venn for each outcome --------------------------------------------

for(i in outcomes) {
  
  df <- read.csv("output/review/venn-diagrams/venn_diagram_number_check_prevax.csv")
  
  # calculate totals columns
  df <- df %>%
    mutate(total_snomed = rowSums(select(., contains('snomed'))),
           total_hes = rowSums(select(., contains('hes'))),
           total_death = rowSums(select(., contains('death')))) %>%
    mutate(total = rowSums(select(., contains('total'))))
  
  df <- subset(df, outcome == i)
  
  cols.num <- c("only_snomed", "only_hes", "only_death", "snomed_hes", "snomed_death", "hes_death","snomed_hes_death", "total_snomed",
                "total_hes","total_death","total" )
  df[cols.num] <- sapply(df[cols.num],as.numeric)
  
  # create Venn diagram with three sets
  svglite::svglite(file = paste0("output/review/venn-diagrams/venn_diagram_NEWTEST_",gsub("out_date_","",i),".svg"))
  grid.newpage()
  g <- draw.triple.venn(area1=df$total_snomed, area2=df$total_hes, area3=df$total_death, 
                        n12=df$snomed_hes, n23=df$hes_death, n13=df$snomed_death, n123=df$snomed_hes_death, 
                        category=c("Primary care","Secondary care","Death records"),
                        col="white",fill=c("thistle","lightcyan","lemonchiffon"),
                        print.mode = c("raw", "percent"),
                        sigdigs = 3)
  
  g <- grid.arrange(gTree(children=g), top=textGrob(active_analyses[active_analyses$outcome_variable==i,]$outcome, gp = gpar(fontsize = 18, fontface="bold")))
  print(g)
  dev.off()
}

# END