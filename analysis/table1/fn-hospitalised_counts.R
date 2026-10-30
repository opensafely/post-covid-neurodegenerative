hospitalised_counts <- function(df) {
  columns <- setdiff(
    names(df),
    c("patient_id", "hospitalised", "nonhospitalised")
  )
  # Match aggregate.formula's complete-case handling of both response columns.
  keep <- !is.na(df$hospitalised) & !is.na(df$nonhospitalised)
  if (!any(keep)) {
    stop("No complete hospitalisation indicators to aggregate")
  }
  hospitalised <- df$hospitalised[keep]
  nonhospitalised <- df$nonhospitalised[keep]

  # pivot_longer() would allocate patients x characteristics rows, followed by
  # further copies inside aggregate(). Summarise each column first so only the
  # small count tables are combined. See docs/table1_hospitalised_memory.md.
  counts <- lapply(columns, function(column) {
    values <- as.character(df[[column]][keep])
    values[is.na(values) | values == "" | values == "unknown"] <- "Missing"
    group <- data.frame(
      subcharacteristic = values,
      hospitalised = hospitalised,
      nonhospitalised = nonhospitalised
    )
    group <- dplyr::group_by(group, subcharacteristic)
    summary <- dplyr::summarise(
      group,
      total = dplyr::n(),
      hospitalised = sum(hospitalised),
      nonhospitalised = sum(nonhospitalised),
      .groups = "drop"
    )
    data.frame(characteristic = column, summary)
  })
  as.data.frame(dplyr::bind_rows(counts))
}
