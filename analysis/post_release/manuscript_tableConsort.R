# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(path_consort,
                      show_col_types = FALSE)

# Filter data ------------------------------------------------------------------
print("Filter data")

df$removed <- NULL

# Pivot table ------------------------------------------------------------------
print("Pivot table")

df <- df %>%
  dplyr::group_by(Description,cohort) %>%
  dplyr::mutate(N = min(N)) %>%
  dplyr::ungroup() %>%
  unique()

df <- tidyr::pivot_wider(df, 
                         names_from = "cohort",
                         values_from = c("N"))

# Save table -------------------------------------------------------------------
print("Save table")

readr::write_csv(df, "output/post_release/tableConsort.csv", na = "-")