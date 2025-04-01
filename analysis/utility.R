# Rounding function for redaction ----

roundmid_any <- function(x, to = 1) {
  # like ceiling_any, but centers on (integer) midpoint of the rounding points
  ceiling(x / to) * to - (floor(to / 2) * (x != 0))
}

# Function to make display numbers ----

display <- function(x, to = 1) {
  ifelse(
    x >= 100,
    sprintf("%.0f", x),
    ifelse(x >= 10, sprintf("%.1f", x), sprintf("%.2f", x))
  )
}

# Function for describing data ----

describe_data <- function(df, name) {
  fs::dir_create(here::here("output/describe/"))
  sink(paste0("output/describe/", name, ".txt"))
  print(Hmisc::describe(df))
  sink()
  message(paste0("output/describe/", name, ".txt written successfully."))
}
