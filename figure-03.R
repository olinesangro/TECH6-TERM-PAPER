#--------------------------------------------------------------
# FIGURE 3: Islamic win margin and Islamic vote share in 1994
#--------------------------------------------------------------

# Need patchwork package, so if it is not already installed, install it
if (!requireNamespace("patchwork", quietly = TRUE)) install.packages("patchwork")

source("replications/setup.R")

# Build the smoother
local_linear <- function(x, y, grid, bw) {
  out <- lapply(grid, function(g) {
    w <- pmax(0, 1 - abs(x - g) / bw)
    keep <- w > 0
    dat  <- tibble(xc = x[keep] - g, y = y[keep], w = w[keep])
    mod  <- lm_robust(y ~ xc, data = dat, weights = w)
    tibble(x = g, fit = coef(mod)[1], se = sqrt(vcov(mod)[1, 1]))
  })
  bind_rows(out)
}

# Building dots and smoother for one single covariate
build_panel <- function(var, label) {
  dat <- df_matched |> filter(!is.na(iwm94), !is.na(.data[[var]]))
  
  # Picking bandwidth, based on course's methods
  rd_fit  <- rdrobust(dat[[var]], dat$iwm94, c = 0)
  h_left  <- rd_fit$bws["h", "left"]
  h_right <- rd_fit$bws["h", "right"]
  
  dots <- dat |>
    mutate(bin = floor(iwm94 / 0.08) * 0.08 + 0.08 / 2) |>
    group_by(bin) |>
    summarise(y = mean(.data[[var]]), .groups = "drop") |>
    mutate(panel = label)
  
  left  <- dat |> filter(iwm94 < 0)
  right <- dat |> filter(iwm94 >= 0)
  
  grid_left  <- seq(max(min(left$iwm94),  -0.3), 0, length.out = 100)
  grid_right <- seq(0, min(max(right$iwm94), 0.3), length.out = 100)
  
  # Fitting dots on each side of the cutoff, not one line for all points
  fit_left  <- local_linear(left$iwm94,  left[[var]],  grid_left,  h_left)  |> mutate(side = "left")
  fit_right <- local_linear(right$iwm94, right[[var]], grid_right, h_right) |> mutate(side = "right")
  
  # Build CI
  fits <- bind_rows(fit_left, fit_right) |>
    mutate(lo = fit - 1.96 * se, hi = fit + 1.96 * se, panel = label)
  
  list(dots = dots, fits = fits)
}

# Run for all eight covariates, build panels and set y-axis titles
panels <- list(
  build_panel("vshr_islam1994", "Islamic vote share"),
  build_panel("ageshr60",       "Age 60+"),
  build_panel("ageshr19",       "Age 19-"),
  build_panel("lpop1994",       "Log Population"),
  build_panel("sexr",           "Gender"),
  build_panel("anyc",           "Any center municipality"),
  build_panel("partycount",     "Number of parties"),
  build_panel("shhs",           "Household size")
)

# Combining
dots_all <- bind_rows(lapply(panels, function(p) p$dots))
fits_all <- bind_rows(lapply(panels, function(p) p$fits))

# Set the y-axis ranges to match Meyersson's
axis_specs <- tibble::tribble(
  ~label,                     ~ymin, ~ymax, ~ystep, ~col,
  "Islamic vote share",        0,     0.6,   0.2,   "left",
  "Age 19-",                   0.35,  0.55,  0.10,  "left",
  "Gender",                    0.9,   1.2,   0.1,   "left",
  "Number of parties",         2,     8,     2,     "left",
  "Age 60+",                   0.05,  0.11,  0.02,  "right",
  "Log Population",            6,     10,    2,     "right",
  "Any center municipality",   0,     0.8,   0.2,   "right",
  "Household size",            4,     10,    2,     "right"
)

# Shared plot look
base_theme <- theme_bw(base_size = 12) +
  theme(panel.border = element_blank(),
        panel.grid   = element_blank(),
        axis.text    = element_text(size = 10),
        axis.line.y  = element_line(color = "black"),
        axis.line.x  = element_blank(),
        axis.ticks.x = element_blank(),
        plot.margin  = margin(t = 2, r = 4, b = 2, l = 4))

# Build one finished panel for a covariate
make_panel <- function(lbl, show_x) {
  spec <- axis_specs |> filter(label == lbl)
  d <- dots_all |> filter(panel == lbl)
  f <- fits_all |> filter(panel == lbl)
  
  p <- ggplot() +
    geom_point(data = d, aes(x = bin, y = y), shape = 16, size = 1.6, color = "grey40") +
    geom_line(data = f, aes(x = x, y = fit, group = side), linewidth = 0.4) +
    geom_line(data = f, aes(x = x, y = lo,  group = side), color = "grey60", linewidth = 0.4) +
    geom_line(data = f, aes(x = x, y = hi,  group = side), color = "grey60", linewidth = 0.4) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey70", linewidth = 0.3) +
    base_theme +
    scale_x_continuous(limits = c(-0.31, 0.31), breaks = seq(-0.25, 0.25, by = 0.25),
                       labels = scales::label_number(drop0trailing = TRUE)) +
    scale_y_continuous(limits = c(spec$ymin, spec$ymax),
                       breaks = seq(spec$ymin, spec$ymax, by = spec$ystep),
                       position = if (spec$col == "right") "right" else "left") +
    labs(x = NULL, y = lbl)
  
  # Only want x-axis on the bottom panels
  if (show_x) {
    p <- p + theme(axis.line.x  = element_line(color = "black"),
                   axis.ticks.x = element_line(color = "black")) +
      labs(x = "Islamic win margin")
  } else {
    p <- p + theme(axis.text.x = element_blank())
  }
  p
}

# Deciding which covariate panels go where and builds each panel, stacking them
left_order  <- c("Islamic vote share", "Age 19-", "Gender", "Number of parties")
right_order <- c("Age 60+", "Log Population", "Any center municipality", "Household size")

left_plots  <- lapply(seq_along(left_order),  function(i) make_panel(left_order[i],  i == length(left_order)))
right_plots <- lapply(seq_along(right_order), function(i) make_panel(right_order[i], i == length(right_order)))

left_col  <- wrap_plots(left_plots,  ncol = 1)
right_col <- wrap_plots(right_plots, ncol = 1)

# Places left and right column side by side
fig3 <- left_col | right_col

# Save the figure in the output folder
ggsave("output/figures/figure3.png", plot = fig3, width = 8, height = 8, dpi = 300)