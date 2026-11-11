#-------------------------------------------------------------------------------
# TABLE 7: Islamic rule and education in 2011
#-------------------------------------------------------------------------------

source("replications/setup.R")

# Same RD setup as Table 2, but with outcomes from 2011
# high school share 15-19 and 15-29, and share never married 15-19.
# Controls are the same as in Table 2 (..ctrl).

# Outcomes in the paper's column order: women, men, women, men, ...
outcomes  <- c("ahischshr15_19f", "ahischshr15_19m",
               "ahischshr15_29f", "ahischshr15_29m",
               "nevm15_19f",      "nevm15_19m")
col_names <- c("HS 15-19 W", "HS 15-19 M", "HS 15-29 W",
               "HS 15-29 M", "Unmarried 15-19 W", "Unmarried 15-19 M")

# Same towns in every column: drop missing outcomes and controls together
df_t7 <- df |>
  drop_na(all_of(outcomes), i94, iwm94, pcode,
          vshr_islam1994, partycount, lpop1994, ageshr19, ageshr60, sexr, shhs,
          merkezi, merkezp, subbuyuk, buyuk)
nrow(df_t7)    # paper: 2338

# IK bandwidths, one per outcome. Unrounded, so the N matches the paper
h_ik <- c(ahischshr15_19f = 0.2385, ahischshr15_19m = 0.1993,
          ahischshr15_29f = 0.26255, ahischshr15_29m = 0.2270,
          nevm15_19f      = 0.2801, nevm15_19m      = 0.2711)

# One data set per outcome, with its own y and bandwidth
samples <- lapply(outcomes, function(v) df_t7 |> mutate(y = df_t7[[v]], h = h_ik[v]))
names(samples) <- outcomes

# One column for five regressions
table7_col <- function(dat) {
  list(
    # Panel A: OLS on all towns, without and with controls
    A1 = feols(y ~ i94,          data = dat, cluster = ~pcode),
    A2 = feols(y ~ i94 + ..ctrl, data = dat, cluster = ~pcode),
    
    # Panel B: local linear RD with controls, at h, h/2 and 2h
    B1 = feols(y ~ i94 + iwm94 + i94:iwm94 + ..ctrl,
               data = dat, subset = ~ abs(iwm94) < h,     cluster = ~pcode),
    B2 = feols(y ~ i94 + iwm94 + i94:iwm94 + ..ctrl,
               data = dat, subset = ~ abs(iwm94) < h / 2, cluster = ~pcode),
    B3 = feols(y ~ i94 + iwm94 + i94:iwm94 + ..ctrl,
               data = dat, subset = ~ abs(iwm94) < h * 2, cluster = ~pcode)
  )
}

# Run the five regressions for each of the six outcomes, 30 regressions in total
models <- lapply(samples, table7_col)

# Check cell against the paper
coeftable(models$ahischshr15_19f$B1)["i94", ]


# Helpers that build the table rows. mod picks the model (A1, A2, B1, B2 or B3),
# and each helper returns one value per outcome, so one row across the six columns
# Coefficient with stars, and SE on the row below
coef_rows <- function(mod) {
  rbind(paste0(f3(sapply(models, function(m) coef(m[[mod]])["i94"])),
               stars(sapply(models, function(m) pvalue(m[[mod]])["i94"]))),
        paste0("(", f3(sapply(models, function(m) se(m[[mod]])["i94"])), ")"))
}

# Outcome mean in the estimation sample
mean_row <- function(mod) f3(sapply(models, function(m) fitstat(m[[mod]], "my")[[1]]))

# Number of observations
n_row    <- function(mod) formatC(sapply(models, function(m) nobs(m[[mod]])),
                                  format = "d", big.mark = ",")

# Bandwidth, + 1e-9 so 0.2385 rounds up to 0.239 as in the paper
bw_row   <- function(bw) f3(bw + 1e-9)


# Fixing the table layout
to_tibble <- function(labels, rows) {
  colnames(rows) <- col_names
  tibble(label = labels, as_tibble(rows))
}

blank_row <- function(txt) {
  cells <- matrix("", nrow = 1, ncol = 6, dimnames = list(NULL, col_names))
  tibble(label = txt, as_tibble(cells))
}

# Panel A: OLS on all towns
panel_A <- to_tibble(
  c("Outcome mean", "Model 1: unconditional", "", "Model 2: conditional", "",
    "Observations", "Bandwidth"),
  rbind(mean_row("A1"), coef_rows("A1"), coef_rows("A2"),
        n_row("A1"), bw_row(rep(1, 6))))

# Panel B: local linear RD with controls at h, h/2 and 2h
panel_B <- to_tibble(
  c("Outcome mean", "Model 1: h", "", "Model 2: h/2", "", "Model 3: 2h", "",
    "Observations, Model 1", "Observations, Model 2", "Observations, Model 3",
    "Bandwidth, Model 1", "Bandwidth, Model 2", "Bandwidth, Model 3"),
  rbind(mean_row("B1"), coef_rows("B1"), coef_rows("B2"), coef_rows("B3"),
        n_row("B1"), n_row("B2"), n_row("B3"),
        bw_row(h_ik), bw_row(h_ik / 2), bw_row(h_ik * 2)))

table7_paper <- bind_rows(
  blank_row("Panel A: Global OLS"),
  panel_A,
  blank_row("Panel B: Local linear RD"),
  panel_B
)
print(table7_paper, n = Inf, width = Inf)


# Saving the table as csv and word
write.csv(table7_paper, "output/tables/table7.csv", row.names = FALSE)

ft <- flextable(table7_paper) |>
  set_header_labels(label = "") |>
  theme_booktabs() |>
  add_footer_lines(paste(
    "Notes: Outcomes from 2011: share with high school education aged 15-19 and 15-29, and",
    "share never married aged 15-19, for women (W) and men (M). Panel A: OLS on all",
    "municipalities, without (Model 1) and with (Model 2) covariates. Panel B: local linear RD",
    "with covariates at the IK bandwidth h, h/2 and 2h. Covariates are those of Table 2,",
    "including province fixed effects. Standard errors clustered by province in parentheses.",
    "*** p<0.01, ** p<0.05, * p<0.10.")) |>
  align(j = 2:7, align = "center", part = "all") |>
  bold(i = ~ label %in% c("Panel A: Global OLS", "Panel B: Local linear RD"), j = 1) |>
  font(fontname = "Times New Roman", part = "all") |>
  fontsize(size = 9, part = "all") |>
  padding(padding.top = 1, padding.bottom = 1, part = "body") |>
  autofit()
save_as_docx(ft, path = "output/tables/table7.docx")