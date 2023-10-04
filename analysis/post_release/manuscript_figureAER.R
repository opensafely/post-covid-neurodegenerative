# Load data --------------------------------------------------------------------
print('Load data')

df <- read.csv("output/post_release/lifetables_compiled.csv")

# Filter data ------------------------------------------------------------------
print("Filter data")

# Neurodegenerative outcomes
#4
# df <- df[df$outcome %in% c("alzheimer_disease", "any_dementia", "cognitive_impairment", "migraine", "multiple_sclerosis", "rem_sleep_disorder","unspecified_dementias"),]

# df <- df[df$outcome %in% c("alzheimer_disease"),]

# df <- df[df$outcome %in% c(""other_dementias", "parkinson_disease", "restless_leg_syndrome", "vascular_dementia"),]

# df <- df[df$outcome %in% c("motor_neurone_disease"),]

# df <- df[df$outcome %in% c("alzheimer_disease", "any_dementia", "cognitive_impairment", "migraine", "motor_neurone_disease", "multiple_sclerosis",
#                            "other_dementias", "parkinson_disease", "rem_sleep_disorder", "restless_leg_syndrome", "unspecified_dementias", "vascular_dementia"),]

# Format aer_age ---------------------------------------------------------------
print("Format aer_age")

df$aer_age <- factor(df$aer_age,
                     levels = c("18_39",
                                "40_59",
                                "60_79",
                                "80_110",
                                "overall"),
                     labels = c("Age group: 18-39",
                                "Age group: 40-59",
                                "Age group: 60-79",
                                "Age group: 80-110",
                                "Combined"))

# Format aer_sex ---------------------------------------------------------------
print("Format aer_sex")

df$aer_sex <- factor(df$aer_sex,
                     levels = c("Female",
                                "Male",
                                "overall"),
                     labels = c("Sex: Female",
                                "Sex: Male",
                                "Combined"))

# Add plot labels --------------------------------------------------------------
print("Add plot labels")

plot_labels <- readr::read_csv("lib/plot_labels.csv",
                               show_col_types = FALSE)

df <- merge(df, plot_labels, by.x = "outcome", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "outcome_label" = "label")

df <- merge(df, plot_labels, by.x = "cohort", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "cohort_label" = "label")

# Order cohorts ----------------------------------------------------------------
print("Order cohorts")

df$cohort_label <- factor(df$cohort_label,
                          levels = c("Pre-vaccination (Jan 1 2020 - Dec 14 2021)", # "Pre-vaccination (Jan 1 2020 - Dec 14 2021)"
                                     "Vaccinated (Jun 1 2021 - Dec 14 2021)",
                                     "Unvaccinated (Jun 1 2021 - Dec 14 2021)"))

# Plot data --------------------------------------------------------------------
print("Plot data")

ggplot2::ggplot(data = df[df$days<197,], 
                mapping = ggplot2::aes(x = days/7, 
                                       y = cumulative_difference_absolute_excess_risk*100, 
                                       color = aer_age, linetype = aer_sex)) +
  ggplot2::geom_line() +
  ggplot2::scale_x_continuous(lim = c(0,28), breaks = seq(0,28,4), labels = seq(0,28,4)) +
  ggplot2::scale_color_manual(values = c("#006d2c",
                                         "#31a354",
                                         "#74c476",
                                         "#bae4b3",
                                         "#000000"), 
                              labels = levels(df$aer_age)) +
  ggplot2::scale_linetype_manual(values = c("solid",
                                            "longdash",
                                            "solid"), 
                                 labels = levels(df$aer_sex))+
  ggplot2::labs(x = "Weeks since COVID-19 diagnosis", y = "Cumulative difference in absolute risk  (%)") +
  ggplot2::guides(fill=ggplot2::guide_legend(ncol = 6, byrow = TRUE)) +
  ggplot2::theme_minimal() +
  ggplot2::theme(panel.grid.major.x = ggplot2::element_blank(),
                 panel.grid.minor = ggplot2::element_blank(),
                 panel.spacing.x = ggplot2::unit(0.5, "lines"),
                 panel.spacing.y = ggplot2::unit(0, "lines"),
                 legend.key = ggplot2::element_rect(colour = NA, fill = NA),
                 legend.title = ggplot2::element_blank(),
                 legend.position="bottom",
                 plot.background = ggplot2::element_rect(fill = "white", colour = "white"),
                 plot.title = ggplot2::element_text(hjust = 0.5),
                 text = ggplot2::element_text(size=13)) +
  ggplot2::facet_wrap(outcome_label ~ cohort_label, scales = "free_x")

# Save plot --------------------------------------------------------------------
print("Save plot")

ggplot2::ggsave(paste0("output/post_release/figureAER.png"), 
                height = 210, width = 297, unit = "mm", dpi = 600, scale = 1)