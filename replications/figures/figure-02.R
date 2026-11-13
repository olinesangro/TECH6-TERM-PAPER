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

# Preparing the dots
binwidth_b <- 2 * sd(iwm94_clean) * length(iwm94_clean)^(-1/2)

full_bins <- tibble(
  bin = seq(floor(min(iwm94_clean) / binwidth_b) * binwidth_b,
            ceiling(max(iwm94_clean) / binwidth_b) * binwidth_b,
            by = binwidth_b)
)

dots_df <- tibble(iwm94 = x_iwm) |>
  mutate(bin = round(floor(iwm94 / binwidth_b) * binwidth_b + binwidth_b / 2, 6)) |>
  count(bin) |>
  right_join(full_bins, by = "bin") |>
  mutate(n = replace_na(n, 0),
         side = if_else(bin < 0, "left", "right"),
         density = n / (length(x_iwm) * binwidth_b))

# count observations per bin, join onto full grid, zero-fill empty bins
  binned <- tibble(iwm94 = iwm94_clean) |>
  mutate(bin = floor(iwm94 / binwidth_b) * binwidth_b) |>
  count(bin) |>
  right_join(full_bins, by = "bin") |>
  replace_na(list(n = 0)) |>
  mutate(
    dens = n / (length(iwm94_clean) * binwidth_b),
    side = if_else(bin < 0, "left", "right")
  )

# Plotting the dots and fitting a smoothed curve through the dots, per side, as well as the CI
fig2b -> ggplot(binned, aes(x = bin, y = dens)) +
    geom_point() +
    geom_smooth(data = filter(binned, side == "left"),
                method = "loess", span = 0.9, se = TRUE) +
    geom_smooth(data = filter(binned, side == "right"),
                method = "loess", span = 0.9, se = TRUE) +
    geom_vline(xintercept = 0, linetype = "dashed") +
    labs(x = "Islamic win margin 1994", y = "Density")

fig2b

# Save the figure in the output folder
#ggsave("output/figures/figure2b.png", plot = fig2b, width = 8, height = 6, dpi = 300)