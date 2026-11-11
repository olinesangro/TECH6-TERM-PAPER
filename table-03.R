#-------------------------------------------------------------------------------
# TABLE 3: RD estimates across bandwidths and polynomial orders
#-------------------------------------------------------------------------------
source("replications/setup.R")

# Same RD setup as Table 2: iwm94 is the win margin, i94 the Islamic mayor dummy,
# outcome is the high school share 15-20 for women and men.
# Controls are the same as in Table 2 (..ctrl), since that is what matches the paper

# Samples
samples <- list(women = df_matched |> mutate(y = hischshr1520f),
                men   = df_matched |> mutate(y = hischshr1520m))

# One cell is one RD regression
fmls <- list(
  None      = y ~ i94 + ..ctrl,
  Linear    = y ~ i94 + iwm94 + i94:iwm94 + ..ctrl,
  Quadratic = y ~ i94 + iwm94 + i94:iwm94 +
    I(iwm94^2) + i94:I(iwm94^2) + ..ctrl,
  Cubic     = y ~ i94 + iwm94 + i94:iwm94 +
    I(iwm94^2) + i94:I(iwm94^2) +
    I(iwm94^3) + i94:I(iwm94^3) + ..ctrl,
  Quartic   = y ~ i94 + iwm94 + i94:iwm94 +
    I(iwm94^2) + i94:I(iwm94^2) +
    I(iwm94^3) + i94:I(iwm94^3) +
    I(iwm94^4) + i94:I(iwm94^4) + ..ctrl
)

# Keep towns inside the bandwidth and divide the margin by h, so it goes from -1 to 1.
# Otherwise x^3 and x^4 get tiny in small windows and fixest drops them.
# This does not change the estimate at the cutoff. fmls[[p + 1]] since p starts at 0
rd_cell <- function(dat, p, h) {
  dat <- dat |> filter(abs(iwm94) < h) |> mutate(iwm94 = iwm94 / h)
  feols(fmls[[p + 1]], data = dat, cluster = ~pcode)
}

# Should be the same as Table 2, column (4): 0.028
coef(rd_cell(samples$women, p = 1, h = 0.2398))["i94"]


# All 50 regressions, men and women, on 5 polynomial orders, and bandwidths
bandwidths <- c(1, 0.5, 0.25, 0.1, 0.05)
orders     <- c("None", "Linear", "Quadratic", "Cubic", "Quartic")

# One row per regression, every combination of gender, order and bandwidth
specs <- expand_grid(sex = c("women", "men"),
                     p   = 0:4,
                     h   = bandwidths)
models <- lapply(seq_len(nrow(specs)), function(i)
  rd_cell(samples[[specs$sex[i]]], specs$p[i], specs$h[i]))

# variables dropped as collinear, should all be 0
sapply(models, function(fit) length(fit$collin.var))

# Add estimate, SE, p-value and N from each model to its row in specs
results <- specs |>
  mutate(est  = sapply(models, function(fit) coef(fit)["i94"]),
         se   = sapply(models, function(fit) se(fit)["i94"]),
         pval = sapply(models, function(fit) pvalue(fit)["i94"]),
         n    = sapply(models, nobs))

print(results, n = Inf)


# Compare with the paper (same order as specs)
paper_t3 <- specs |>
  mutate(est_paper = c(
    # Women
    0.012, 0.015, 0.018, 0.025, 0.018,    # None
    0.014, 0.021, 0.025, 0.028, 0.039,    # Linear
    0.027, 0.030, 0.033, 0.032, 0.051,    # Quadratic
    0.031, 0.026, 0.036, 0.057, 0.054,    # Cubic
    0.030, 0.032, 0.044, 0.067, 0.028,    # Quartic
    # Men
    0.009, 0.011, 0.012, 0.015, 0.010,    # None
    0.010, 0.014, 0.012, 0.011, 0.017,    # Linear
    0.016, 0.016, 0.019, 0.024, 0.048,    # Quadratic
    0.017, 0.016, 0.025, 0.038, 0.048,    # Cubic
    0.017, 0.028, 0.026, 0.071, 0.035     # Quartic
  ))

compare <- results |>
  left_join(paper_t3, by = c("sex", "p", "h")) |>
  mutate(diff = round(est, 3) - est_paper)

# The cells that dont match should be empty
compare |> filter(abs(diff) > 0.001)


# Fixing the table layout
panel_rows <- function(s) {
  r <- results |> filter(sex == s)
  # estimate with stars, then (SE), for each order
  rows <- lapply(0:4, function(k) {
    rk <- r |> filter(p == k) |> arrange(desc(h))
    rbind(paste0(f3(rk$est), stars(rk$pval)),
          paste0("(", f3(rk$se), ")"))
  })
  obs  <- r |> filter(p == 0) |> arrange(desc(h))   
  rows <- rbind(do.call(rbind, rows),
                formatC(obs$n, format = "d", big.mark = ","))
  colnames(rows) <- paste0("h = ", bandwidths)
  tibble(label = c(c(rbind(orders, "")), "Observations"),
         as_tibble(rows))
}

blank_row <- function(txt) {
  cells <- matrix("", nrow = 1, ncol = length(bandwidths),
                  dimnames = list(NULL, paste0("h = ", bandwidths)))
  tibble(label = txt, as_tibble(cells))
}

table3_paper <- bind_rows(
  blank_row("Panel A: Women"),
  panel_rows("women"),
  blank_row("Panel B: Men"),
  panel_rows("men")
)
print(table3_paper, n = Inf, width = Inf)


# Saving the table as csv and word-format
write.csv(table3_paper, "output/tables/table3.csv", row.names = FALSE)

ft <- flextable(table3_paper) |>
  set_header_labels(label = "") |>
  theme_booktabs() |>
  add_footer_lines(paste(
    "Notes: Outcome is the share of 15-20 year olds with high school education in 2000.",
    "Each cell is a separate RD regression with the given bandwidth and order of the",
    "control function in the win margin, estimated separately on each side of the cutoff.",
    "All regressions include the covariates and province fixed effects from Table 2.",
    "Standard errors clustered by province in parentheses. *** p<0.01, ** p<0.05, * p<0.10.")) |>
  align(j = 2:6, align = "center", part = "all") |>
  bold(i = ~ label %in% c("Panel A: Women", "Panel B: Men"), j = 1) |>
  font(fontname = "Times New Roman", part = "all") |>
  fontsize(size = 9, part = "all") |>
  padding(padding.top = 1, padding.bottom = 1, part = "body") |>
  autofit()
save_as_docx(ft, path = "output/tables/table3.docx")