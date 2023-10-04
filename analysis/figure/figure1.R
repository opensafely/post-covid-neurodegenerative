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

estimates$outcome_label<- str_replace_all(estimates$outcome,"_"," ")
# labels 

####################
#3-Plotting function
####################
plot_estimates <- function(df) {
  pd <- position_dodge(width = 0.5)
  
  p <- ggplot(df, aes(x = outcome_time_median, y = hr, color = colour_cohort)) +
    geom_line() +
    geom_point(size = 2, position = pd) +
    geom_hline(mapping = aes(yintercept = 1), colour = "#A9A9A9") +
    geom_errorbar(size = 1.2,
                  mapping = aes(ymin = ifelse(conf_low < 0.25, 0.25, conf_low), 
                                ymax = ifelse(conf_high > 64, 64, conf_high),
                                width = 0),
                  position = pd) + 
    scale_color_manual(values = levels(df$colour_cohort), labels = levels(df$cohort)) +
    guides( color = guide_legend(nrow = 3)) +
    guides(fill=ggplot2::guide_legend(ncol = 1, byrow = TRUE) ) +
    facet_wrap(~outcome_label , ncol=2) +
    theme_minimal() +
    labs(x = "\nWeeks since COVID-19 diagnosis", y = "Hazard ratio and 95% confidence interval") +
    #scale_x_continuous(breaks = seq(0, max(df$outcome_time_median)/7, 4)) +  # display labels at 4-week intervals
    scale_x_continuous(lim = c(0,511), breaks = seq(0,511,56), labels = seq(0,511,56)/7) +
    scale_y_continuous(lim = c(0.5,64), breaks = c(0.5,1,2,4,8,16,32,64), trans = "log") +
    #scale_y_continuous(lim = c(0.25,32), breaks = c(0.25,0.5,1,2,4,8,16,32), trans = "log")+ 
    
    theme(panel.grid.major.x = element_blank(),
          panel.grid.minor = element_blank(),
          panel.spacing.x = unit(0.5, "lines"),
          panel.spacing.y = unit(0, "lines"),
          legend.key = element_rect(colour = NA, fill = NA),
          legend.title = element_blank(),
          legend.position = "bottom",
          plot.background = element_rect(fill = "white", colour = "white"),
          plot.margin = margin(1, 1, 1, 1, "cm"),
          text = element_text(size = 12),
          strip.text= element_text(size=12, face="bold")
    )
  ggsave(paste0(output_dir,"Figure_1_main.png"), height = 297, width = 210, unit = "mm", dpi = 600, scale = 1)
  
  return(p)
}

estimates_main <-estimates[estimates$analysis=="main",]
plot_estimates(estimates_main)