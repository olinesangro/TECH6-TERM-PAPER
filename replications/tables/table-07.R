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
# Columns are now named (1)-(6). The outcome and women/men
# are shown in two header rows added further down
col_names <- paste0("(", 1:6, ")")

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
# Each model gets a centred heading row, followed by its coefficient, SE, bandwidth
# and observations

to_tibble <- function(labels, rows) {
  colnames(rows) <- col_names
  tibble(label = labels, as_tibble(rows))
}

# An empty row across the six columns
blank6 <- rep("", 6)  

panel_names <- c("Panel A: Global OLS",
                 "Panel B: Conditional local linear RD")
model_names <- c("Model 1. Unconditional estimates",
                 "Model 2. Conditional estimates",
                 "Model 1. Bandwidth = ĥ",
                 "Model 2. Bandwidth = ĥ/2",
                 "Model 3. Bandwidth = 2ĥ")

# Panel A: OLS on all towns. Bandwidth and N are shown once, after Model 2
panel_A <- to_tibble(
  c(panel_names[1], "Outcome mean",
    model_names[1], "Islamic mayor in 1994", "",
    model_names[2], "Islamic mayor in 1994", "",
    "Bandwidth", "Observations"),
  rbind(blank6, mean_row("A1"),
        blank6, coef_rows("A1"),
        blank6, coef_rows("A2"),
        bw_row(rep(1, 6)), n_row("A1")))

# One RD model: heading, coefficient, SE, bandwidth and observations
rd_block <- function(title, mod, bw) {
  to_tibble(c(title, "Islamic mayor in 1994", "", "Bandwidth", "Observations"),
            rbind(blank6, coef_rows(mod), bw_row(bw), n_row(mod)))
}

# Panel B: local linear RD with controls at h, h/2 and 2h
panel_B <- bind_rows(
  to_tibble(c(panel_names[2], "Outcome mean"), rbind(blank6, mean_row("B1"))),
  rd_block(model_names[3], "B1", h_ik),
  rd_block(model_names[4], "B2", h_ik / 2),
  rd_block(model_names[5], "B3", h_ik * 2)
)

table7_paper <- bind_rows(panel_A, panel_B)
print(table7_paper, n = Inf, width = Inf)


# Saving the table as csv and word
write.csv(table7_paper, "output/tables/table7.csv", row.names = FALSE)

# Notes: same content as the paper's notes, with en dashes and the
# Model 1 / Model 2 order stated correctly
notes <- paste(
  "Notes: Outcomes are from the 2011 population register. In columns (1)–(4) the",
  "outcome is the share with completed high school among 15–19 year olds",
  "(columns (1)–(2)) and 15–29 year olds (columns (3)–(4)); in columns",
  "(5)–(6) it is the share of 15–19 year olds who are unmarried. Panel A reports",
  "OLS estimates on all municipalities without (Model 1) and with (Model 2) covariates.",
  "Panel B reports local linear RD estimates with covariates at the",
  "Imbens–Kalyanaraman bandwidth ĥ reported in the paper, and at ĥ/2 and",
  "2ĥ, computed from its unrounded value. Outcome means in Panel B are within ĥ.",
  "Covariates are those of Table 2, including province fixed effects. Standard errors",
  "clustered by province in parentheses. *** p<0.01, ** p<0.05, * p<0.10."
)

heading_rows <- which(table7_paper$label %in% c(panel_names, model_names))
model_rows   <- which(table7_paper$label %in% model_names)

ft <- flextable(table7_paper) |>
  set_header_labels(label = "") |>
  # Header rows as in the paper: Outcome / Age cohort / Gender, then (1)-(6).
  # Each top = TRUE row goes above the previous one, so Gender comes first
  add_header_row(values = c("Gender", rep(c("Women", "Men"), 3)),
                 colwidths = rep(1, 7), top = TRUE) |>
  add_header_row(values = c("Age cohort", "15–19", "15–29", "15–19"),
                 colwidths = c(1, 2, 2, 2), top = TRUE) |>
  add_header_row(values = c("Outcome", "High school", "Unmarried"),
                 colwidths = c(1, 4, 2), top = TRUE) |>
  # Title above the table, plain bold Times New Roman, left-aligned
  set_caption(
    caption = as_paragraph(as_chunk(
      "Table 7: RD treatment effects of Islamic rule on education in 2011",
      props = fp_text_default(font.family = "Times New Roman",
                              font.size = 10, bold = TRUE))),
    fp_p = officer::fp_par(text.align = "left", padding.bottom = 4),
    align_with_table = FALSE) |>
  theme_booktabs() |>
  # Thin lines under "High school / Unmarried" and under the age cohorts
  hline(i = 1:2, j = 2:7, border = fp_border_default(width = 0.5), part = "header") |>
  add_footer_lines(notes) |>
  align(j = 2:7, align = "center", part = "all") |>
  align(j = 1, align = "right", part = "header") |>
  font(fontname = "Times New Roman", part = "all") |>
  fontsize(size = 9, part = "all") |>
  fontsize(size = 8, part = "footer") |>
  padding(padding.top = 1, padding.bottom = 1, part = "all") |>
  # Space above each panel and model heading
  padding(i = heading_rows, padding.top = 6, part = "body")

# Panel and model headings: one cell across the whole table, centred.
# Model headings in italics, as in the paper
for (r in heading_rows) ft <- merge_at(ft, i = r, j = 1:7, part = "body")
ft <- ft |>
  align(i = heading_rows, j = 1, align = "center", part = "body") |>
  italic(i = model_rows, j = 1, part = "body") |>
  autofit()

save_as_docx(ft, path = "output/tables/table7.docx")