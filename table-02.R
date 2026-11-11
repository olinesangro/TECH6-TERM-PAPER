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

table2_paper <- bind_rows(
  blank_row("Panel A: Women"),
  panel_rows(panel_women, bw_used(h_ik["women"], h_ik["enr_women"])),
  blank_row("Panel B: Men"),
  panel_rows(panel_men,   bw_used(h_ik["men"],   h_ik["enr_men"])),
  tibble(label = "Panel C: p-value, women = men", as_tibble(panelC_row))
)
print(table2_paper, n = Inf, width = Inf)


# Saving the table as csv, then as a word-format to change later
write.csv(table2_paper, "output/tables/table2.csv", row.names = FALSE)

ft <- flextable(table2_paper) |>
  set_header_labels(label = "") |>
  theme_booktabs() |>
  add_footer_lines(paste(
    "Notes: Outcome is the share of 15-20 year olds with high school education in 2000",
    "(col 9: share of 15-30 year olds enrolled). Covariates: Islamic vote share, number of",
    "parties, log population, population shares below 19 and above 60, gender ratio, household",
    "size, municipality type dummies and province fixed effects. Standard errors clustered by",
    "province in parentheses. Panel C: SUR p-values for equal effects for women and men.",
    "*** p<0.01, ** p<0.05, * p<0.10.")) |>
  align(j = 2:10, align = "center", part = "all") |>
  bold(i = ~ label %in% c("Panel A: Women", "Panel B: Men"), j = 1) |>
  font(fontname = "Times New Roman", part = "all") |>
  fontsize(size = 9, part = "all") |>
  padding(padding.top = 1, padding.bottom = 1, part = "body") |>
  autofit()

save_as_docx(ft, path = "output/tables/table2.docx")