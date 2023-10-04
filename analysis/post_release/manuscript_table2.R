# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(path_table2,
                      show_col_types = FALSE)

# Keep totals ------------------------------------------------------------------
print("Keep totals")

totals <- unique(df[df$analysis=="main",c("cohort","sample_size")])

totals <- tidyr::pivot_wider(totals,
                             names_from = "cohort",
                             values_from = c("sample_size"))

colnames(totals) <- paste0("event_personyears_",colnames(totals))

totals$outcome_label <- "N"

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[df$analysis %in% c("main","sub_covid_hospitalised","sub_covid_nonhospitalised"),]

df$events <- ifelse(df$analysis=="main", df$unexposed_events, df$exposed_events)
df$person_days <- ifelse(df$analysis=="main", df$unexposed_person_days, df$exposed_person_days)

df <- df[,c("cohort","analysis","outcome","events","person_days")]

# Add plot labels --------------------------------------------------------------
print("Add plot labels")

plot_labels <- readr::read_csv("lib/plot_labels.csv",
                               show_col_types = FALSE)

df$outcome <- gsub("out_date_","",df$outcome)
df <- merge(df, plot_labels, by.x = "outcome", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "outcome_label" = "label")

df <- merge(df, plot_labels, by.x = "analysis", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "covid19_severity" = "label")
df$covid19_severity <- ifelse(df$covid19_severity=="All COVID-19","No COVID-19",df$covid19_severity)
df$covid19_severity <- factor(df$covid19_severity, levels = c("No COVID-19","Hospitalised COVID-19","Non-hospitalised COVID-19"))

# Add other columns ------------------------------------------------------------
print("Add other columns")

df$event_personyears <- paste0(df$events,"/", round((df$person_days/365.25)))
df$incidencerate <- round(df$events/((df$person_days/365.25)/100000))

# Pivot table ------------------------------------------------------------------
print("Pivot table")

df <- df[,c("cohort","outcome_label","covid19_severity","event_personyears","incidencerate")]

df <- tidyr::pivot_wider(df, 
                         names_from = "cohort",
                         values_from = c("event_personyears","incidencerate"))

# Add totals to table ----------------------------------------------------------
print("Add totals to table")

df <- plyr::rbind.fill(totals, df)

# Order outcomes ---------------------------------------------------------------
print("Order outcomes")

df$outcome_label <- factor(df$outcome_label,
                           levels = c("N",
                                      "Alzheimer disease",
                                      "Any dementia",
                                      "Cognitive impairment",
                                      "Migraine",
                                      "Motor neurone disease",
                                      "Multiple sclerosis",
                                      "Other dementias",
                                      "Parkinson disease",
                                      "Rem sleep disorder",
                                      "Restless leg syndrome",
                                      "Unspecified dementias",
                                      "Vascular dementia"))

# Tidy table -------------------------------------------------------------------
print("Tidy table")

df <- df[order(df$outcome_label,df$covid19_severity),
         c("outcome_label","covid19_severity",
           paste0(c("event_personyears","incidencerate"),"_prevax"),
           paste0(c("event_personyears","incidencerate"),"_vax"),
           paste0(c("event_personyears","incidencerate"),"_unvax"))]

df <- dplyr::rename(df,
                    "Outcome" = "outcome_label",
                    "COVID-19 severity" = "covid19_severity")

# Save table -------------------------------------------------------------------
print("Save table")

readr::write_csv(df, "output/post_release/table2.csv", na = "-")