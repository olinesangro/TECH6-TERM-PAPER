#--------------------------------------------------------------
# FIGURE 2A: Global Histogram
#--------------------------------------------------------------

source("replications/setup.R")

fig2a <- ggplot(df_matched, aes(x=iwm94)) + 
  geom_histogram(aes(y = after_stat(count / sum(count) * 100)), binwidth = 0.02, boundary = 0, closed = "right",
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
dens94 <- rddensity(df_matched$iwm94, c = 0)
x_iwm <- df_matched$iwm94[!is.na(df_matched$iwm94)]
summary(dens94)

# Preparing the dots
binwidth_b <- 0.0083

full_bins <- tibble(bin = round(seq(floor(min(x_iwm)/binwidth_b)*binwidth_b + binwidth_b/2,
                                    ceiling(max(x_iwm)/binwidth_b)*binwidth_b - binwidth_b/2,
                                    by = binwidth_b), 6))

dots_df <- tibble(iwm94 = x_iwm) |>
  mutate(bin = round(floor(iwm94 / binwidth_b) * binwidth_b + binwidth_b / 2, 6)) |>
  count(bin) |>
  right_join(full_bins, by = "bin") |>
  mutate(n = replace_na(n, 0),
         side = if_else(bin < 0, "left", "right"),
         density = n / (length(x_iwm) * binwidth_b))

# Plotting the dots and fitting a smoothed curve through the dots, per side, as well as the CI
fig2b <- ggplot(dots_df, aes(x = bin, y = density, group = side)) +
  geom_point(color = "grey50", shape = 16, size =3) +
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
  scale_y_continuous(limits = c(0, 2.8), breaks = seq(0, 2.5, by = 1.25), labels = scales::label_number(accuracy = 0.01, drop0trailing=TRUE)) + 
  labs(title = "(b) Density test",
       x = "Islamic win margin 1994",
       y = "Density")

# Adding the caption with the discontinuity estimate and the standard error
est_diff <- round(dens94$hat$diff, 3)
se_diff  <- round(dens94$sd_jk$diff, 3)

fig2b <- fig2b +
  labs(caption = paste0("Discontinuity est. = ", est_diff, ", s.e. = ", se_diff)) +
  theme(plot.caption = element_text(hjust = 0, size = 9))

# Save the figure in the output folder
ggsave("output/figures/figure2b.png", plot = fig2b, width = 8, height = 6, dpi = 300)