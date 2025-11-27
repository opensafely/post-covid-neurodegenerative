# Load model output --------------------------------------------------------------------
print("Load model output")

# release <- "C:\\Users\\pp24053\\OneDrive - University of Bristol\\Documents - grp-EHR\\Projects\\post-covid-events\\post-covid-neurodegenerative\\release", # Specify path to release directory

# List all CSV files matching the pattern
file_list <- list.files(
  path = paste0(release, "20251125_noday0\\"),
  pattern = "^model_output-.*-midpoint6\\.csv$",
  full.names = TRUE
)

# Read and combine all CSV files into one data frame
df <- file_list %>%
  lapply(read_csv, show_col_types = FALSE) %>%
  bind_rows()

readr::write_csv(
  df,
  "output/post_release/plot_model_output.csv"
)
