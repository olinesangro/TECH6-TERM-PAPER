#-------------------------------------------------------------------------------
# TABLE 3: RD estimates across bandwidths and polynomial orders
#-------------------------------------------------------------------------------

source("replications/setup.R")

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
# This does not change the estimate at the cutoff.
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

# Notes say which coefficient is shown, that N is the same for
# women and men, and use en dashes
notes <- paste(
  "Notes: Each cell reports the coefficient on Islamic mayor in 1994 from a separate",
  "RD regression of the share of 15–20 year olds with high school education in 2000.",
  "Columns vary the bandwidth h and rows vary the order of the control function in the",
  "win margin, estimated separately on each side of the cutoff. All regressions include",
  "the covariates and province fixed effects from Table 2. Because the bandwidths are",
  "fixed, the number of observations is the same for women and men. Standard errors",
  "clustered by province in parentheses. *** p<0.01, ** p<0.05, * p<0.10."
)

ft <- flextable(table3_paper) |>
  # The label column says what the rows are
  set_header_labels(label = "Control function") |>
  # Spanner over the bandwidth columns
  add_header_row(values = c("", "Bandwidth"),
                 colwidths = c(1, length(bandwidths)), top = TRUE) |>
  # Title above the table, as in Tables 1 and 2
  set_caption(caption = "Table 3: Robustness to bandwidth and control function") |>
  theme_booktabs() |>
  add_footer_lines(notes) |>
  align(j = 2:6, align = "center", part = "all") |>
  bold(i = ~ label %in% c("Panel A: Women", "Panel B: Men"), j = 1) |>
  font(fontname = "Times New Roman", part = "all") |>
  fontsize(size = 9, part = "all") |>
  # Notes one size smaller,
  fontsize(size = 8, part = "footer") |>
  padding(padding.top = 1, padding.bottom = 1, part = "body") |>
  # Extra space above Panel B and above each Observations row
  padding(i = ~ label %in% c("Panel B: Men", "Observations"),
          padding.top = 6, part = "body") |>
  autofit()
save_as_docx(ft, path = "output/tables/table3.docx")