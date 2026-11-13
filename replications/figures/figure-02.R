#--------------------------------------------------------------
# FIGURE 2A: Global Histogram
#--------------------------------------------------------------

source("replications/setup.R")

binwidth_a <- diff(range(df$iwm94, na.rm = TRUE)) / 99

fig2a <- ggplot(df, aes(x=iwm94)) + 
  geom_histogram(aes(y = after_stat(count / sum(count) * 100)), binwidth = binwidth_a, boundary =  min(df$iwm94, na.rm = TRUE), closed = "right",
                 fill = "grey70", color = "black") +
  geom_vline(xintercept = 0, linetype = "dotted") +
  theme_bw() +
  theme(panel.grid = element_blank()) +
  theme(axis.text.y = element_text(angle = 90, size = 10),
        axis.text.x = element_text(size = 10)) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, by = 0.5), labels = scales::label_number(drop0trailing=TRUE)) +
  scale_y_continuous(limits = c(0, 5.3), breaks = seq(0, 5, by = 1), expand = c(0, 0), labels = scales::label_number(drop0trailing=TRUE)) + 
  labs(title = "(a) Global histogram",
       x = "Islamic win margin",
       y = "Percent")

# Save the figure in the output folder
ggsave("output/figures/figure2a.png", plot = fig2a, width = 8, height = 6, dpi = 300)

#--------------------------------------------------------------
# FIGURE 2B: Density Test
#--------------------------------------------------------------
df_fig2b <- df |>
  filter(!is.na(hischshr1520f), !is.na(iwm94)) |>
  filter(abs(iwm94) < 0.6)

iwm94_clean <- df_fig2b$iwm94[!is.na(df_fig2b$iwm94)]

dens_test <- rddensity(iwm94_clean, c = 0)

binwidth_b <- 2 * sd(iwm94_clean) * length(iwm94_clean)^(-1/2)

bin_start <- floor(min(iwm94_clean) / binwidth_b)
bin_end   <- ceiling(max(iwm94_clean) / binwidth_b)

full_bins <- tibble(bin_idx = bin_start:bin_end) |>
  mutate(bin = bin_idx * binwidth_b)

# Count observations per bin, join onto full grid, zero-fill empty bins
  binned <- tibble(iwm94 = iwm94_clean) |>
  mutate(bin_idx = floor(iwm94 / binwidth_b)) |>
  count(bin_idx) |>
  right_join(full_bins, by = "bin_idx") |>
  replace_na(list(n = 0)) |>
  mutate(
    dens = n / (length(iwm94_clean) * binwidth_b),
    side = if_else(bin < 0, "left", "right")
  )

# Plotting the dots and fitting a smoothed curve through the dots, per side, as well as the CI
fig2b <- ggplot(binned, aes(x = bin, y = dens, group = side)) +
    geom_point(color = "grey50", shape = 16, size = 3) +
    geom_smooth(method = "loess", se = FALSE, span = 0.9, color = "black", linewidth = 0.7) +
    stat_smooth(method = "loess", se = TRUE, span = 0.9, geom = "ribbon",
                aes(ymin = after_stat(ymin), ymax = after_stat(ymax)),
                fill = NA, color = "grey50", linetype = "dashed") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey") +
    theme_bw() +
    theme(panel.grid = element_blank(),
          axis.text.y = element_text(angle = 90, hjust = 0.5, size = 10),
          axis.text.x = element_text(size = 10)) +
    scale_x_continuous(limits = c(-0.5, 0.5), breaks = seq(-0.5, 0.5, by = 0.5), expand = c(0.02, 0), labels = scales::label_number(drop0trailing=TRUE)) +
    scale_y_continuous(limits = c(0, 3), breaks = seq(0, 2.5, by = 1.25), labels = scales::label_number(accuracy = 0.01, drop0trailing=TRUE)) + 
    labs(title = "(b) Density test",
         x = "Islamic win margin 1994",
         y = "Density")

# Adding the caption with the discontinuity estimate and the standard error
est_diff <- round(dens_test$hat$diff, 3)
se_diff  <- round(dens_test$sd_jk$diff, 3)

fig2b <- fig2b +
  labs(caption = paste0("Discontinuity est. = ", est_diff, ", s.e. = ", se_diff)) +
  theme(plot.caption = element_text(hjust = 0, size = 9))

# Save the figure in the output folder
ggsave("output/figures/figure2b.png", plot = fig2b, width = 8, height = 6, dpi = 300)