# Load model output --------------------------------------------------------------------
print("Load model output")

# List all CSV files matching the pattern
file_list <- list.files(
  path = paste0(release, "20260429_noday0\\"), #DATAPAST2
  # path = paste0(release, "20250804_processed\\"), #DATAPAST1
  pattern = "^model_output-.*-midpoint6\\.csv$",
  full.names = TRUE
)

# Read and combine all CSV files into one data frame
df <- file_list %>%
  lapply(read_csv, show_col_types = FALSE) %>%
  bind_rows()

# Save dataset
readr::write_csv(
  df, #df_diltered
  "output/post_release/plot_model_output.csv"
)
