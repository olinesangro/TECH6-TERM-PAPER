#--------------------------------------------------------------
# FIGURE 4: Graphical illustration of RD design
#--------------------------------------------------------------

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

# Building dots and smoother for one single outcome
build_panel <- function(var, label) {
  dat <- df_matched |> filter(!is.na(iwm94), !is.na(.data[[var]]))
  
  # Picking bandwidth, based on course's methods
  rd_fit  <- rdrobust(dat[[var]], dat$iwm94, c = 0)
  h_left  <- rd_fit$bws["h", "left"]
  h_right <- rd_fit$bws["h", "right"]
  
  dots <- dat |>
    mutate(bin = floor(iwm94 / 0.04) * 0.04 + 0.04 / 2) |>
    group_by(bin) |>
    summarise(y = mean(.data[[var]]), .groups = "drop") |>
    mutate(panel = label)
  
  left  <- dat |> filter(iwm94 < 0)
  right <- dat |> filter(iwm94 >= 0)
  
  grid_left  <- seq(max(min(left$iwm94),  -0.5), 0, length.out = 100)
  grid_right <- seq(0, min(max(right$iwm94), 0.5), length.out = 100)
  
  # Fitting dots on each side of the cutoff, not one line for all points
  fit_left  <- local_linear(left$iwm94,  left[[var]],  grid_left,  h_left)  |> mutate(side = "left")
  fit_right <- local_linear(right$iwm94, right[[var]], grid_right, h_right) |> mutate(side = "right")
  
  # Build CI
  fits <- bind_rows(fit_left, fit_right) |>
    mutate(lo = fit - 1.96 * se, hi = fit + 1.96 * se, panel = label)
  
  list(dots = dots, fits = fits)
}

# Run for all four outcomes, build panels
panels <- list(
  build_panel("hischshr1520f",    "(a) Women in 2000"),
  build_panel("hischshr1520m",    "(b) Men in 2000"),
  build_panel("c90hischshr1520f", "(c) Women in 1990"),
  build_panel("c90hischshr1520m", "(d) Men in 1990")
)

# Combining
dots_all <- bind_rows(lapply(panels, function(p) p$dots))
fits_all <- bind_rows(lapply(panels, function(p) p$fits))

# Build one finished panel for an outcome
make_panel <- function(lbl, yside, show_ylab) {
  d <- dots_all |> filter(panel == lbl)
  f <- fits_all |> filter(panel == lbl)
  
  p <- ggplot() +
    geom_point(data = d, aes(x = bin, y = y), shape = 16, size = 2, color = "grey50") +
    geom_line(data = f, aes(x = x, y = fit, group = side), linewidth = 0.4) +
    geom_line(data = f, aes(x = x, y = lo,  group = side), color = "grey60", linewidth = 0.4) +
    geom_line(data = f, aes(x = x, y = hi,  group = side), color = "grey60", linewidth = 0.4) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.3) +
    coord_cartesian(ylim = c(-0.05, 0.25)) +
    scale_x_continuous(limits = c(-0.5, 0.5), breaks = seq(-0.5, 0.5, by = 0.25),
                       labels = scales::label_number(drop0trailing = TRUE)) +
    scale_y_continuous(breaks = seq(-0.05, 0.25, by = 0.05), position = yside,
                       labels = scales::label_number(drop0trailing = TRUE)) +
    theme_classic(base_size = 12) +
    theme(plot.title  = element_text(size = 11, hjust = 0),
          axis.line   = element_line(color = "black"),
          axis.text   = element_text(size = 9),
          axis.text.y = element_text(angle = 90, hjust = 0.5)) +
    labs(title = lbl, x = NULL, y = NULL)
  
  # theme_classic() to draw the y-axis line on the left by default and flips it
  # to the right for the right-column panels
  if (yside == "right") {
    p <- p + theme(axis.line.y.left = element_blank(), axis.line.y.right = element_line(color = "black"))
  }
  p
}

p_a <- make_panel("(a) Women in 2000", "left",  TRUE)
p_b <- make_panel("(b) Men in 2000",   "right", FALSE)
p_c <- make_panel("(c) Women in 1990", "left",  TRUE)
p_d <- make_panel("(d) Men in 1990",   "right", FALSE)

# One shared y-axis title
y_title <- wrap_elements(grid::textGrob("Share of 15-20-year-olds\nwith High School Degree",
                                        rot = 90, gp = grid::gpar(fontsize = 12)))
grid4 <- (p_a | p_b) / (p_c | p_d)

fig4 <- y_title + grid4 + plot_layout(widths = c(0.06, 1)) +
  plot_annotation(caption = "Islamic win margin 1994",
                  theme = theme(plot.caption = element_text(hjust = 0.5, size = 12, face = "plain")))

# Save the figure in the output folder
ggsave("output/figures/figure4.png", plot = fig4, width = 8, height = 8, dpi = 300)