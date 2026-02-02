# Load model output --------------------------------------------------------------------
print("Load model output")

# release <- "C:\\Users\\pp24053\\OneDrive - University of Bristol\\Documents - grp-EHR\\Projects\\post-covid-events\\post-covid-neurodegenerative\\release", # Specify path to release directory

# List all CSV files matching the pattern
file_list <- list.files(
  path = paste0(release, "20260129_noday0\\"),
  pattern = "^model_output-.*-midpoint6\\.csv$",
  full.names = TRUE
)

# Read and combine all CSV files into one data frame
df <- file_list %>%
  lapply(read_csv, show_col_types = FALSE) %>%
  bind_rows()

# Find analyses with <12 midpoint6 events at any timepoint
low_event_list <- unique(na.omit(df[df$N_events_midpoint6 < 12, ]$name)) # find list

df_filtered <- df[!(df$name %in% low_event_list), ] # apply reduction

# Save list of removed files
sink('output/post_release/removed_models_low_events.txt')
print(low_event_list)
sink() #close external connection to file


# Save dataset
readr::write_csv(
  df_filtered,
  "output/post_release/plot_model_output.csv"
)
