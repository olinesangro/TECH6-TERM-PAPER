# ------------------------------------------------------------------------
# TABLE 2: Islamic mayor and high school education
# ------------------------------------------------------------------------

source("replications/setup.R")

# running variable: iwm94 (cutoff 0), treatment: i94
# outcomes: high school share 15-20 (women/men), enrollment 15-30 in col 9

# IK bandwidths from the paper. Printed rounded as 0.240 / 0.323,
# these values give the same N as the paper
h_ik <- c(women     = 0.2398, men     = 0.32296,
          enr_women = 0.205,  enr_men = 0.230)

# Women and men in one data set, each with own outcome and bandwidth
stack <- bind_rows(
  df_matched |> mutate(fem = 1, y = hischshr1520f, y_enr = studshr1530f,
                       h = h_ik["women"], h_enr = h_ik["enr_women"]),
  df_matched |> mutate(fem = 0, y = hischshr1520m, y_enr = studshr1530m,
                       h = h_ik["men"],   h_enr = h_ik["enr_men"])
)
women <- stack |> filter(fem == 1)
men   <- stack |> filter(fem == 0)


# Panels A and B of the table, repeating the same 9 regressions for women and men
table2_panel <- function(dat) {
  list(
    # OLS, all towns
    "(1)" = feols(y ~ i94,          data = dat, cluster = ~pcode),
    "(2)" = feols(y ~ i94 + ..ctrl, data = dat, cluster = ~pcode),
    
    # Local linear RD
    "(3)" = feols(y ~ i94 + iwm94 + i94:iwm94,
                  data = dat, subset = ~ abs(iwm94) < h, cluster = ~pcode),
    "(4)" = feols(y ~ i94 + iwm94 + i94:iwm94 + ..ctrl,
                  data = dat, subset = ~ abs(iwm94) < h, cluster = ~pcode),
    
    # Half and double bandwidth
    "(5)" = feols(y ~ i94 + iwm94 + i94:iwm94 + ..ctrl,
                  data = dat, subset = ~ abs(iwm94) < h / 2, cluster = ~pcode),
    "(6)" = feols(y ~ i94 + iwm94 + i94:iwm94 + ..ctrl,
                  data = dat, subset = ~ abs(iwm94) < h * 2, cluster = ~pcode),
    
    # Quadratic and cubic
    "(7)" = feols(y ~ i94 + iwm94 + i94:iwm94 +
                    I(iwm94^2) + i94:I(iwm94^2) + ..ctrl,
                  data = dat, subset = ~ abs(iwm94) < h, cluster = ~pcode),
    "(8)" = feols(y ~ i94 + iwm94 + i94:iwm94 +
                    I(iwm94^2) + i94:I(iwm94^2) +
                    I(iwm94^3) + i94:I(iwm94^3) + ..ctrl,
                  data = dat, subset = ~ abs(iwm94) < h, cluster = ~pcode),
    
    # Enrollment
    "(9)" = feols(y_enr ~ i94 + iwm94 + i94:iwm94 + ..ctrl,
                  data = dat, subset = ~ abs(iwm94) < h_enr, cluster = ~pcode)
  )
}

panel_women <- table2_panel(women)
panel_men   <- table2_panel(men)

coeftable(panel_women[["(4)"]])["i94", ]


# Panel C, is the effect different for women and men, one regression for both genders
# where every coefficient can differ by gender
# fem:i94 = effect for women minus effect for men, its p-value tests if they are equal
gender <- list(
  "(1)" = feols(y ~ fem * (i94),
                data = stack, cluster = ~pcode),
  "(2)" = feols(y ~ fem * (i94 + ..ctrl),
                data = stack, cluster = ~pcode),
  "(3)" = feols(y ~ fem * (i94 + iwm94 + i94:iwm94),
                data = stack, subset = ~ abs(iwm94) < h, cluster = ~pcode),
  "(4)" = feols(y ~ fem * (i94 + iwm94 + i94:iwm94 + ..ctrl),
                data = stack, subset = ~ abs(iwm94) < h, cluster = ~pcode),
  "(5)" = feols(y ~ fem * (i94 + iwm94 + i94:iwm94 + ..ctrl),
                data = stack, subset = ~ abs(iwm94) < h / 2, cluster = ~pcode),
  "(6)" = feols(y ~ fem * (i94 + iwm94 + i94:iwm94 + ..ctrl),
                data = stack, subset = ~ abs(iwm94) < h * 2, cluster = ~pcode),
  "(7)" = feols(y ~ fem * (i94 + iwm94 + i94:iwm94 +
                             I(iwm94^2) + i94:I(iwm94^2) + ..ctrl),
                data = stack, subset = ~ abs(iwm94) < h, cluster = ~pcode),
  "(8)" = feols(y ~ fem * (i94 + iwm94 + i94:iwm94 +
                             I(iwm94^2) + i94:I(iwm94^2) +
                             I(iwm94^3) + i94:I(iwm94^3) + ..ctrl),
                data = stack, subset = ~ abs(iwm94) < h, cluster = ~pcode),
  "(9)" = feols(y_enr ~ fem * (i94 + iwm94 + i94:iwm94 + ..ctrl),
                data = stack, subset = ~ abs(iwm94) < h_enr, cluster = ~pcode)
)

# Checking if it is the same number
coef(gender[["(4)"]])["fem:i94"]
coef(panel_women[["(4)"]])["i94"] - coef(panel_men[["(4)"]])["i94"]

# Paper uses SUR, same SE as fixest but without the small-sample correction
# So removing the correction and use the normal distribution. 
sur_pvalue <- function(fit) {
  n  <- nobs(fit)
  K  <- length(coef(fit))
  se_sur <- se(fit)["fem:i94"] * sqrt((n - K) / (n - 1))
  2 * pnorm(-abs(coef(fit)["fem:i94"] / se_sur))
}
panelC <- sapply(gender, sur_pvalue)
round(panelC, 3)

# rdrobust check, col (3) with uniform kernel
#summary(rdrobust(women$y, women$iwm94, c = 0, h = h_ik["women"],
#                 kernel = "uniform", cluster = women$pcode))


# Fixing the table layout
bw_used <- function(h, h_enr) c(1, 1, h, h, h / 2, h * 2, h, h, h_enr)

panel_rows <- function(models, bw) {
  rows <- rbind(
    paste0(f3(sapply(models, function(fit) coef(fit)["i94"])),
           stars(sapply(models, function(fit) pvalue(fit)["i94"]))),
    paste0("(", f3(sapply(models, function(fit) se(fit)["i94"])), ")"),
    f3(sapply(models, function(fit) fitstat(fit, "my")[[1]])),
    formatC(sapply(models, nobs), format = "d", big.mark = ","),
    sprintf("%.2f", sapply(models, function(fit) r2(fit, "r2"))),
    f3(bw),
    c("None", "None", "Linear", "Linear", "Linear", "Linear", "Quadratic", "Cubic", "Linear"),
    c("No", "Yes", "No", "Yes", "Yes", "Yes", "Yes", "Yes", "Yes")
  )
  colnames(rows) <- names(models)
  tibble(label = c("Islamic mayor in 1994", "", "Outcome mean", "Observations",
                   "R-squared", "Bandwidth", "Control function", "Covariates"),
         as_tibble(rows))
}

blank_row <- function(txt) {
  cells <- matrix("", nrow = 1, ncol = 9, dimnames = list(NULL, names(panel_women)))
  tibble(label = txt, as_tibble(cells))
}

panelC_row <- matrix(f3(panelC), nrow = 1, dimnames = list(NULL, names(panel_women)))

# Panel C gets its own heading row
panel_names <- c("Panel A: Women", "Panel B: Men",
                 "Panel C: Difference women − men")

table2_paper <- bind_rows(
  blank_row(panel_names[1]),
  panel_rows(panel_women, bw_used(h_ik["women"], h_ik["enr_women"])),
  blank_row(panel_names[2]),
  panel_rows(panel_men,   bw_used(h_ik["men"],   h_ik["enr_men"])),
  blank_row(panel_names[3]),
  tibble(label = "p-value, women = men", as_tibble(panelC_row))
)
print(table2_paper, n = Inf, width = Inf)


# Notes on the table, where the bandwidths come
# from, and a Panel C description that matches how we computed it
notes <- paste(
  "Notes: The outcome is the share of 15–20 year olds with high school education",
  "in 2000 (column (9): share of 15–30 year olds enrolled in education).",
  "Columns (1)–(2) are OLS on all municipalities; columns (3)–(9) are RD",
  "estimates with a separate control function on each side of the cutoff.",
  "Bandwidths in columns (3), (4) and (7)–(9) are the Imbens–Kalyanaraman",
  "bandwidths reported in the paper; columns (5) and (6) halve and double them.",
  "Covariates: Islamic vote share, number of parties, log population, population",
  "shares below 19 and above 60, gender ratio, household size, municipality type",
  "dummies and province fixed effects. Standard errors clustered by province in",
  "parentheses. Panel C: p-values for equal effects for women and men, computed as",
  "in the paper's SUR test. *** p<0.01, ** p<0.05, * p<0.10."
)

# Saving the table as csv
write.csv(table2_paper, "output/tables/table2.csv", row.names = FALSE)

#Formatting the tabel into a word-format, so changes can be made later on
ft <- flextable(table2_paper) |>
  set_header_labels(label = "") |>
  # Header rows showing method (OLS/RD) and outcome above the
  # column numbers. Each top = TRUE row goes above the previous one.
  add_header_row(values = c("", "OLS", "RD"),
                 colwidths = c(1, 2, 7), top = TRUE) |>
  add_header_row(values = c("", "High school share, 15–20", "Enrolled, 15–30"),
                 colwidths = c(1, 8, 1), top = TRUE) |>
  # Title above the table, as in Table 1
  set_caption(caption = "Table 2: Islamic mayor in 1994 and high school education in 2000") |>
  theme_booktabs() |>
  add_footer_lines(notes) |>
  align(j = 2:10, align = "center", part = "all") |>
  bold(i = ~ label %in% panel_names, j = 1) |>
  font(fontname = "Times New Roman", part = "all") |>
  fontsize(size = 9, part = "all") |>
  # Notes one size smaller, as in Table 1
  fontsize(size = 8, part = "footer") |>
  padding(padding.top = 1, padding.bottom = 1, part = "body") |>
  # Extra space above Panel B and Panel C headings
  padding(i = ~ label %in% panel_names[2:3], padding.top = 8, part = "body") |>
  autofit()

save_as_docx(ft, path = "output/tables/table2.docx")