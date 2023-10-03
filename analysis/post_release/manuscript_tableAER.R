# Specify parameters -----------------------------------------------------------
print('Specify parameters')

perpeople <- 100000 # per X people

# Load data --------------------------------------------------------------------
print('Load data')

df <- read.csv("output/post_release/lifetables_compiled.csv")

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[df$aer_age=="overall" &
           df$aer_sex=="overall" &
           df$analysis=="main" & 
           df$days==196,]

# Add plot labels --------------------------------------------------------------
print("Add plot labels")

plot_labels <- readr::read_csv("lib/plot_labels.csv",
                               show_col_types = FALSE)

df <- merge(df, plot_labels, by.x = "outcome", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "outcome_label" = "label")

# Format data ------------------------------------------------------------------
print("Format data")

df$excess_risk <- round(df$cumulative_difference_absolute_excess_risk*perpeople)
df <- df[,c("outcome_label","cohort","excess_risk")]

# Pivot table ------------------------------------------------------------------
print("Pivot table")

df <- tidyr::pivot_wider(df, 
                         names_from = "cohort",
                         values_from = c("excess_risk"))

# Order outcomes ---------------------------------------------------------------
print("Order outcomes")

df$outcome_label <- factor(df$outcome_label,
                           levels = c(c("Alzheimer disease",
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
                                        "Vascular dementia")))
                           
# Tidy table -------------------------------------------------------------------
print("Tidy table")
                           
df <- df[order(df$outcome_label),
         c("outcome_label","prevax","vax","unvax")]
                           
# Save table -------------------------------------------------------------------
print("Save table")
                           
readr::write_csv(df, "output/post_release/tableAER.csv", na = "-")