# Define the plotting function --------------------------------------------------
plot_hr <- function(outcomes, outcome_group) {
  # Load data --------------------------------------------------------------------
  print("Load data")

  df <- readr::read_csv("output/plot_model_output.csv", show_col_types = FALSE)

  df <- df[!is.na(df$hr), ]

  # Filter data ------------------------------------------------------------------
  print("Filter data")

  df <- df[
    df$outcome %in%
      outcomes &
      df$model == "mdl_max_adj" &
      grepl("days", df$term),
    c(
      "cohort",
      "analysis",
      "outcome",
      "outcome_time_median",
      "term",
      "hr",
      "conf_low",
      "conf_high"
    )
  ]

  df <- df[!(df$term %in% c("days_pre", "days0_1")), ]
  df$preex <- sub(".*?(?=preex_)", "", df$analysis, perl = TRUE)
  df$analysis <- sub("_preex_.*", "", df$analysis, perl = TRUE)

  # Make columns numeric ---------------------------------------------------------
  print("Make columns numeric")

  df <- df %>%
    dplyr::mutate_at(
      c("outcome_time_median", "hr", "conf_low", "conf_high"),
      as.numeric
    )

  # Add plot labels ---------------------------------------------------------
  print("Add plot labels")

  plot_labels <- readr::read_csv("lib/plot_labels.csv", show_col_types = FALSE)

  df <- merge(
    df,
    plot_labels[, c("term", "label")],
    by.x = "outcome",
    by.y = "term",
    all.x = TRUE
  )
  df <- dplyr::rename(df, "outcome_label" = "label")

  df <- merge(
    df,
    plot_labels[, c("term", "label")],
    by.x = "preex",
    by.y = "term",
    all.x = TRUE
  )
  df <- dplyr::rename(df, "preex_label" = "label")

  df <- merge(
    df,
    plot_labels,
    by.x = "analysis",
    by.y = "term",
    all.x = TRUE
  )
  df <- dplyr::rename(df, "analysis_label" = "label")

  # Add facet labels -------------------------------------------------------------
  print("Add facet labels")

  df$facet_label <- ifelse(
    df$ref == 1,
    paste0(df$outcome_label, "\n\n", df$preex_label, "\n\n", df$analysis_label),
    df$analysis_label
  )

  # Iterate over plots -----------------------------------------------------------
  print("Iterate over plots")

  for (i in unique(df$analysis_group)) {
    message(paste0(i))

    # Restrict to plot data ------------------------------------------------------
    print("Restrict to plot data")

    df_plot <- df[df$analysis_group == i, ]

    # Update labels --------------------------------------------------------------

    if (grepl("history_exposure", i)) {
      print("Update labels")
      df_plot$analysis_label <- ifelse(
        df_plot$analysis_label == "All COVID-19",
        "No history of COVID-19",
        df_plot$analysis_label
      )
      df_plot <- df_plot[df_plot$cohort != "prevax", ]
    }

    # Calculate number of facet cols ---------------------------------------------
    print("Calculate number of facet col")

    facet_cols <- length(unique(df_plot$analysis))

    # Generate facet info --------------------------------------------------------
    print("Generate facet info")

    facet_info <- unique(df_plot[, c(
      "outcome",
      "analysis",
      "ref",
      "preex",
      "facet_label"
    )])
    facet_info <- facet_info[
      order(facet_info$outcome, facet_info$preex, facet_info$ref),
    ]
    facet_info$facet_order <- 1:nrow(facet_info)

    facet_info$facet_label2 <- ""
    for (j in 1:nrow(facet_info)) {
      facet_info[j, ]$facet_label2 <- paste0(
        facet_info[j, ]$facet_label,
        paste0(rep(" ", j), collapse = "")
      )
    }

    facet_info$facet_label2 <- factor(
      facet_info$facet_label2,
      levels = facet_info[order(facet_info$facet_order), ]$facet_label2
    )

    df_plot <- merge(df_plot, facet_info)

    # Plot data ------------------------------------------------------------------
    print("Plot data")

    p <- ggplot2::ggplot(
      data = df_plot,
      mapping = ggplot2::aes(x = outcome_time_median, y = hr, color = cohort)
    ) +
      ggplot2::geom_hline(
        mapping = ggplot2::aes(yintercept = 1),
        colour = "#A9A9A9"
      ) +
      ggplot2::geom_point(position = ggplot2::position_dodge(width = 0)) +
      ggplot2::geom_errorbar(
        mapping = ggplot2::aes(ymin = conf_low, ymax = conf_high, width = 0),
        position = ggplot2::position_dodge(width = 0)
      ) +
      ggplot2::geom_line(position = ggplot2::position_dodge(width = 0)) +
      ggplot2::scale_color_manual(
        breaks = c("prevax", "vax", "unvax"),
        labels = c(
          "Pre-vaccination (Jan 1 2020 - Dec 14 2021)",
          "Vaccinated (Jun 1 2021 - Dec 14 2021)",
          "Unvaccinated (Jun 1 2021 - Dec 14 2021)"
        ),
        values = c("#d2ac47", "#58764c", "#0018a8")
      ) +
      ggplot2::labs(
        x = "\nWeeks since COVID-19 diagnosis",
        y = "Hazard ratio and 95% confidence interval\n"
      ) +
      ggplot2::theme_minimal() +
      ggplot2::theme(
        panel.grid.major.x = ggplot2::element_blank(),
        panel.grid.minor = ggplot2::element_blank(),
        panel.spacing.x = ggplot2::unit(0.5, "lines"),
        panel.spacing.y = ggplot2::unit(0, "lines"),
        strip.text = ggplot2::element_text(hjust = 0, vjust = 0),
        legend.key = ggplot2::element_rect(colour = NA, fill = NA),
        legend.title = ggplot2::element_blank(),
        legend.position = "bottom",
        plot.background = ggplot2::element_rect(
          fill = "white",
          colour = "white"
        ),
        axis.text.x = ggplot2::element_text(angle = 50, vjust = 1, hjust = 1)
      )

    if (grepl("history_exposure", i)) {
      p +
        ggplot2::scale_y_continuous(
          lim = c(0.25, 20),
          breaks = c(0.25, 0.5, 1, 2, 4, 8, 16, 32),
          trans = "log"
        ) +
        ggplot2::scale_x_continuous(
          lim = c(0, 84),
          breaks = seq(0, 84, 14),
          labels = seq(0, 84, 14) / 7
        ) +
        ggplot2::facet_wrap(~ factor(facet_label2), ncol = facet_cols) +
        ggplot2::guides(color = ggplot2::guide_legend(ncol = 1, byrow = TRUE))
      plot_width <- 297 * 0.5
    } else if (facet_cols == 1) {
      p +
        ggplot2::scale_y_continuous(
          lim = c(0.25, 20),
          breaks = c(0.25, 0.5, 1, 2, 4, 8, 16, 32),
          trans = "log"
        ) +
        ggplot2::scale_x_continuous(
          lim = c(0, 1162),
          breaks = seq(0, 1162, 112),
          labels = seq(0, 1162, 112) / 7
        ) +
        ggplot2::facet_wrap(~ factor(facet_label2), ncol = facet_cols) +
        ggplot2::guides(color = ggplot2::guide_legend(nrow = 1, byrow = TRUE))
      plot_width <- 297 * 0.5
    } else if (facet_cols == 2) {
      p +
        ggplot2::scale_y_continuous(
          lim = c(0.25, 20),
          breaks = c(0.25, 0.5, 1, 2, 4, 8, 16, 32),
          trans = "log"
        ) +
        ggplot2::scale_x_continuous(
          lim = c(0, 1162),
          breaks = seq(0, 1162, 112),
          labels = seq(0, 1162, 112) / 7
        ) +
        ggplot2::facet_wrap(~ factor(facet_label2), ncol = facet_cols) +
        ggplot2::guides(color = ggplot2::guide_legend(ncol = 1, byrow = TRUE))
      plot_width <- 297 * 0.7
    } else {
      p +
        ggplot2::scale_y_continuous(
          lim = c(0.25, 20),
          breaks = c(0.25, 0.5, 1, 2, 4, 8, 16, 32),
          trans = "log"
        ) +
        ggplot2::scale_x_continuous(
          lim = c(0, 1162),
          breaks = seq(0, 1162, 112),
          labels = seq(0, 1162, 112) / 7
        ) +
        ggplot2::facet_wrap(~ factor(facet_label2), ncol = facet_cols) +
        ggplot2::guides(color = ggplot2::guide_legend(nrow = 1, byrow = TRUE))
      plot_width <- 297
    }

    # Save plot ------------------------------------------------------------------
    print("Save plot")

    ggplot2::ggsave(
      paste0("output/post_release/figure_", i, "_", outcome_group, ".png"),
      height = 210,
      width = plot_width,
      unit = "mm",
      dpi = 300,
      scale = 0.8
    )
  }
}

plot_hr("pneumonia", "pneumonia")
plot_hr(c("asthma", "copd"), "asthma_copd")
plot_hr("pf", "pf")
