# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(path_model_output,
                      show_col_types = FALSE)

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[grepl("day",df$term) & 
           df$model=="mdl_max_adj",
         c("cohort","analysis","outcome","outcome_time_median","term","hr","conf_low","conf_high")]

df <- df[df$term!="days_pre",]

# Neurodegenerative outcomes
# df <- df[df$outcome %in% c("any_dementia", "cognitive_impairment", "migraine", "parkinson_disease"),]

# df <- df[df$outcome %in% c("alzheimer_disease", "multiple_sclerosis"),]

df <- df[df$outcome %in% c("motor_neurone_disease"),]

# df <- df[df$outcome %in% c("other_dementias", "restless_leg_syndrome", "unspecified_dementias"),]

# All
# df <- df[df$outcome %in% c("alzheimer_disease", "any_dementia", "cognitive_impairment", "migraine", "motor_neurone_disease", "multiple_sclerosis",
#                            "other_dementias", "parkinson_disease", "rem_sleep_disorder", "restless_leg_syndrome", "unspecified_dementias", "vascular_dementia"),]

# Make columns numeric ---------------------------------------------------------
print("Make columns numeric")

df <- df %>% 
  dplyr::mutate_at(c("outcome_time_median","hr","conf_low","conf_high"), as.numeric)


# Add plot labels ---------------------------------------------------------
print("Add plot labels")

plot_labels <- readr::read_csv("lib/plot_labels.csv",
                               show_col_types = FALSE)

df <- merge(df, plot_labels, by.x = "outcome", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "outcome_label" = "label")

df <- merge(df, plot_labels, by.x = "analysis", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "analysis_label" = "label")

# Iterate over plots -----------------------------------------------------------
print("Iterate over plots")

for (i in c("hospitalised","sub_history","sub_age","sub_sex","sub_ethnicity","sub_covid_history","day0")){
  
  message(paste0(i))
  
  # Restrict to plot data ------------------------------------------------------
  print("Restrict to plot data")
  
  if (i %in% c("hospitalised","sub_covid_history")) {
    df_plot <- df[(df$analysis=="main" | grepl(i,df$analysis)),]
  } else {
    df_plot <- df[grepl(i,df$analysis),]
  }
  
  # Update labels --------------------------------------------------------------
  
  if (i=="sub_covid_history") {
    print("Update labels")
    df_plot$analysis_label <- ifelse(df_plot$analysis_label=="All COVID-19",
                                     "No history of COVID-19",df_plot$analysis_label)
    df_plot <- df_plot[df_plot$cohort!="prevax",]
  }
  
  # Calculate number of facet cols ---------------------------------------------
  print("Calculate number of facet col")
  
  facet_cols <- length(unique(df_plot$analysis))
  
  # Plot data --------------------------------------------------------------------
  print("Plot data")
  
  
  p <- ggplot2::ggplot(data = df_plot,
                       mapping = ggplot2::aes(x = outcome_time_median, y = hr, color = cohort)) +
    ggplot2::geom_hline(mapping = ggplot2::aes(yintercept = 1), colour = "#A9A9A9") +
    ggplot2::geom_point(position = ggplot2::position_dodge(width = 0)) +
    ggplot2::geom_errorbar(mapping = ggplot2::aes(ymin = conf_low, 
                                                  ymax = conf_high,  
                                                  width = 0), 
                           position = ggplot2::position_dodge(width = 0)) +
    ggplot2::geom_line(position = ggplot2::position_dodge(width = 0)) +
    ggplot2::scale_y_continuous(lim = c(0.5,64), breaks = c(0.5,1,2,4,8,16,32,64), trans = "log") +
    ggplot2::scale_x_continuous(lim = c(0,511), breaks = seq(0,511,56), labels = seq(0,511,56)/7) +
    ggplot2::scale_color_manual(breaks = c("prevax", "vax", "unvax"),
                                labels = c("Pre-vaccination (Jan 1 2020 - Dec 14 2021)",
                                           "Vaccinated (Jun 1 2021 - Dec 14 2021)",
                                           "Unvaccinated (Jun 1 2021 - Dec 14 2021)"),
                                values = c("#d2ac47", "#58764c", "#0018a8")) +
    ggplot2::labs(x = "\nWeeks since COVID-19 diagnosis", y = "Hazard ratio and 95% confidence interval\n") +
    
    ggplot2::theme_minimal() +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank(),
                   panel.spacing.x = ggplot2::unit(0.5, "lines"),
                   panel.spacing.y = ggplot2::unit(0, "lines"),
                   legend.key = ggplot2::element_rect(colour = NA, fill = NA),
                   legend.title = ggplot2::element_blank(),
                   legend.position="bottom",
                   plot.background = ggplot2::element_rect(fill = "white", colour = "white"))
  
  if (facet_cols==1) {
    p + ggplot2::facet_wrap(outcome_label~., ncol = facet_cols) +
      ggplot2::guides(color=ggplot2::guide_legend(ncol = 1, byrow = TRUE)) 
    plot_width = 297*0.5
  } else if (i %in% c("sub_covid_history","sub_sex")) {
    p + ggplot2::facet_wrap(outcome_label~forcats::fct_rev(analysis_label), ncol = facet_cols)+ 
      ggplot2::guides(color=ggplot2::guide_legend(ncol = 1, byrow = TRUE))
    plot_width = 297*0.7
  } else {
    p + ggplot2::facet_wrap(outcome_label~analysis_label, ncol = facet_cols) +
      ggplot2::guides(color=ggplot2::guide_legend(nrow = 1, byrow = TRUE))
    plot_width = 297
  }
  
  # Save plot ------------------------------------------------------------------
  print("Save plot")

  ggplot2::ggsave(paste0("output/post_release/figure_",gsub("sub_","",i),".png"),
                  height = 210, width = plot_width,
                  unit = "mm", dpi = 600, scale = 0.8)
}