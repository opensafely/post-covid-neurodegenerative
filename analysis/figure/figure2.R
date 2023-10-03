library(readr)
library(data.table)
library(tidyverse)
library(ggplot2)

# Define results directory
results_dir <- "../../"
output_dir <- "../../"

#################
#1- Get data
#################

#disregard<- str_to_title(c("", "", "", ""))
estimates <-read.csv(paste0(results_dir,"model_output.csv"))  %>%
  # Extract outcomes to plot
  #filter(!outcome %in% disregard) %>%
  filter(model=="mdl_max_adj")%>%
  #keep only rows with time points 
  filter(grepl("days\\d+", term))%>%
  # Modify outcome names
  mutate(outcome = str_remove(outcome, "out_date_")) %>%
  mutate(outcome = str_to_title(outcome))

estimates <- estimates %>% 
  dplyr::mutate_at(c("outcome_time_median","hr","conf_low","conf_high"), as.numeric)

##################
#2-Format
#################
estimates <- estimates %>% 
  mutate(colour_cohort = case_when(
    cohort == "prevax" ~ "#d2ac47",
    cohort == "vax" ~ "#58764c",
    cohort == "unvax" ~ "#0018a8",
    TRUE ~ ""
  ) %>% 
    factor(levels = c("#d2ac47", "#58764c", "#0018a8"))
  )


# Factor variables for ordering
estimates <- estimates %>%
  mutate(cohort = factor(cohort, levels = c("prevax", "vax", "unvax")),
  )

# Rename adjustment groups
levels(estimates$cohort) <- list("Pre-vaccination (Jan 1 2020 - Dec 14 2021)"="prevax", "Vaccinated (Jun 1 2021 - Dec 14 2021)"="vax","Unvaccinated (Jun 1 2021 - Dec 14 2021)"="unvax")



# Filter data for the desired analyses
estimates_sub <- estimates %>% filter(analysis %in% c("main", "sub_covid_hospitalised", "sub_covid_nonhospitalised"))

# Change names for labelling purpose
estimates_sub$analysis <- factor(estimates_sub$analysis,levels = c("main", "sub_covid_hospitalised","sub_covid_nonhospitalised"))
levels(estimates_sub$analysis) <- list("All COVID-19"="main", "Hospitalised COVID-19"="sub_covid_hospitalised","Non-hospitalised COVID-19"="sub_covid_nonhospitalised")
estimates_sub$grouping_name <- paste0(estimates_sub$analysis,"-", estimates_sub$outcome)

outcomes <- unique(estimates_sub$outcome)
factor_levels <- c()
prefixes <- c("All COVID-19-", "Hospitalised COVID-19-", "Non-hospitalised COVID-19-")
for (i in 1:length(outcomes)) {
  for (j in 1:length(prefixes)) {
    factor_levels <- c(factor_levels, paste0(prefixes[j], outcomes[i]))
  }
}
# Set factor levels 
estimates_sub$grouping_name <- factor(estimates_sub$grouping_name, levels = factor_levels)

# Set labels 
# labels <- c(
#   `All COVID-19-Acute_pancreatitis` = "All COVID-19
#   ",
#   `Hospitalised COVID-19-Acute_pancreatitis` = "Hospitalised COVID-19
#   Acute pancreatitis",
#   `Non-hospitalised COVID-19-Acute_pancreatitis` = "Non-hospitalised COVID-19
#   ",
#   `All COVID-19-Appendicitis` = "",
#   `Hospitalised COVID-19-Appendicitis` = "Appendicitis",
#   `Non-hospitalised COVID-19-Appendicitis` = "",
#   
#   `All COVID-19-Gallstones_disease` = "",
#   `Hospitalised COVID-19-Gallstones_disease` = "Gallstones disease",
#   `Non-hospitalised COVID-19-Gallstones_disease` = "",
#   
#   `All COVID-19-Gastro_oesophageal_reflux_disease` = "",
#   `Hospitalised COVID-19-Gastro_oesophageal_reflux_disease` = "Gastro oesophageal reflux",
#   `Non-hospitalised COVID-19-Gastro_oesophageal_reflux_disease` = "",
#   
#   `All COVID-19-Ibs` = "",
#   `Hospitalised COVID-19-Ibs` = "Ibs",
#   `Non-hospitalised COVID-19-Ibs` = "",
#   
#   `All COVID-19-Lower_gi_bleeding` = "",
#   `Hospitalised COVID-19-Lower_gi_bleeding` = "Lower gi bleeding",
#   `Non-hospitalised COVID-19-Lower_gi_bleeding` = "",
#   
#   `All COVID-19-Nonvariceal_gi_bleeding` = "",
#   `Hospitalised COVID-19-Nonvariceal_gi_bleeding` = "Nonvariceal gi bleeding",
#   `Non-hospitalised COVID-19-Nonvariceal_gi_bleeding` = "",
#   
#   `All COVID-19-Peptic_ulcer` = "",
#   `Hospitalised COVID-19-Peptic_ulcer` = "Peptic ulcer",
#   `Non-hospitalised COVID-19-Peptic_ulcer` = "",
#   
#   `All COVID-19-Upper_gi_bleeding` = "",
#   `Hospitalised COVID-19-Upper_gi_bleeding` = "Upper gi bleeding",
#   `Non-hospitalised COVID-19-Upper_gi_bleeding` = ""
# )

# Function to plot 
plot_estimates <- function(df, name) {
  pd <- position_dodge(width = 0.5)
  
  p <- ggplot(df, aes(x = outcome_time_median, y = hr, color = colour_cohort)) +
    geom_line() +
    geom_point(size = 2, position = pd) +
    geom_hline(mapping = aes(yintercept = 1), colour = "#A9A9A9") +
    geom_errorbar(
      size = 1.2,
      mapping = aes(
        ymin = ifelse(conf_low < 0.25, 0.25, conf_low),
        ymax = ifelse(conf_high > 64, 64, conf_high),
        width = 0
      ),
      position = pd
    ) +
    scale_color_manual(values = levels(df$colour_cohort), labels = levels(df$cohort)) +
    guides(color = guide_legend(nrow = 3)) +
    guides(fill = ggplot2::guide_legend(ncol = 1, byrow = TRUE)) +
    # facet_wrap(outcome ~ analysis, ncol = 3, scales = "free_x", strip.position = "top") +
    theme_minimal() +
    labs(x = "\nWeeks since COVID-19 diagnosis", y = "Hazard ratio and 95% confidence interval") +
    #scale_x_continuous(breaks = seq(0, max(df$outcome_time_median)/7, 4)) +  # display labels at 4-week intervals
    scale_x_continuous(lim = c(0,511), breaks = seq(0,511,56), labels = seq(0,511,56)/7) +
    scale_y_continuous(lim = c(0.5,64), breaks = c(0.5,1,2,4,8,16,32,64), trans = "log") +
    #scale_y_continuous(lim = c(0.25,32), breaks = c(0.25,0.5,1,2,4,8,16,32), trans = "log")+ 
    theme(panel.grid.major.x = ggplot2::element_blank(),
          panel.grid.minor = element_blank(),
          panel.spacing.x = ggplot2::unit(0.5, "lines"),
          panel.spacing.y = ggplot2::unit(0, "lines"),
          legend.key = element_rect(colour = NA, fill = NA),
          legend.title = element_blank(),
          legend.position="bottom",
          plot.background = element_rect(fill = "white", colour = "white"),
          text=element_text(size=13),
          strip.text = element_text(face = "bold",size=12)) +
    
    facet_wrap(grouping_name~.,labeller=as_labeller(labels), ncol=3)    
  
  # Add annotations
  
  ggsave(paste0(output_dir, "Figure2_", name, ".png"),
         height = 500, width = 400, unit = "mm", scale = 1)
  
  return(p)
}

# Plotting for the three analyses
plot_estimates(estimates_sub, "main_sub_covid_hosp_nonhosp")