#--------------------------------------------------------------
# TABLE 1: Descriptive Statistics
#--------------------------------------------------------------
source("replications/setup.R")

nrow(df_matched)

# Readable row labels, in the same order as vars from the setup-file
labels <- c("Female high school share, age 15–20",
            "Male high school share, age 15–20",
            "Islamic mayor in 1994",
            "Islamic vote share 1994",
            "Number of parties receiving votes 1994",
            "Log population 1994",
            "Population share below 19",
            "Population share above 60",
            "Gender ratio (male/female)",
            "Household size",
            "District center",
            "Province center",
            "Sub-metro center")

# The two groups we compare
islamic <- df_matched |> filter(i94 == 1)   
secular <- df_matched |> filter(i94 == 0)   

# sapply() runs mean/sd on every column in vars
table1 <- tibble(
  variable     = vars,
  label        = labels,
  all_mean     = sapply(df_matched[vars], mean),
  all_sd       = sapply(df_matched[vars], sd),
  islamic_mean = sapply(islamic[vars], mean),
  islamic_sd   = sapply(islamic[vars], sd),
  secular_mean = sapply(secular[vars], mean),
  secular_sd   = sapply(secular[vars], sd)
)


# Calculate the difference of Islamic - Secular
# Classical SEs as in the paper
diff_test <- function(x, d) {
  x1 <- x[d == 1]; x0 <- x[d == 0]
  n1 <- length(x1); n0 <- length(x0)
  diff <- mean(x1) - mean(x0)
  # Two-sample t-test by hand. Pooled variance for both groups, SE and p-value
  s2 <- ((n1 - 1) * var(x1) + (n0 - 1) * var(x0)) / (n1 + n0 - 2)
  se <- sqrt(s2 * (1 / n1 + 1 / n0))
  p  <- if (se > 0) 2 * pt(-abs(diff / se), df = n1 + n0 - 2) else NA
  c(diff = diff, se = se, p = p)
}

balance <- t(sapply(vars, function(v) diff_test(df_matched[[v]], df_matched$i94)))

table1 <- table1 |>
  mutate(diff = balance[, "diff"],
         se   = balance[, "se"],
         p    = balance[, "p"])



# Fixing the paper layout
# Odd rows with means, and the difference with stars
mean_rows <- table1 |>
  transmute(row     = 2 * row_number() - 1,
            label,
            all     = f3(all_mean),
            islamic = f3(islamic_mean),
            secular = f3(secular_mean),
            diff    = paste0(f3(diff), stars(p)))

# Even rows with SDs, and the SE of the difference
# The SE is left blank when it is zero (the Islamic mayor row)
sd_rows <- table1 |>
  transmute(row     = 2 * row_number(),
            label   = "",
            all     = paste0("(", f3(all_sd), ")"),
            islamic = paste0("(", f3(islamic_sd), ")"),
            secular = paste0("(", f3(secular_sd), ")"),
            diff    = if_else(se > 0, paste0("(", f3(se), ")"), ""))

# Shows the number of towns in each group
obs_row <- tibble(row     = 2 * nrow(table1) + 1,
                  label   = "Observations",
                  all     = formatC(nrow(df_matched), format = "d", big.mark = ","),
                  islamic = formatC(nrow(islamic),    format = "d", big.mark = ","),
                  secular = formatC(nrow(secular),    format = "d", big.mark = ","),
                  diff    = "")

# Group headings. The half-numbers place each heading
# just above the first row of its group
group_names <- c("Outcomes", "Treatment", "Covariates")
group_rows <- tibble(row     = c(0.5, 4.5, 6.5),
                     label   = group_names,
                     all = "", islamic = "", secular = "", diff = "")

# Stack the pieces, sort so each mean sits above its SD
table1_paper <- bind_rows(group_rows, mean_rows, sd_rows, obs_row) |>
  arrange(row) |>
  select(-row)

print(table1_paper, n = Inf, width = Inf)


# Notes describing the sample and the two stars that differ
notes <- paste(
  "Notes: Sample of", formatC(nrow(df_matched), format = "d", big.mark = ","),
  "municipalities with a 1994 mayoral election result and non-missing values on",
  "all variables in the table. Columns (1)–(3) report means with standard",
  "deviations in parentheses. Column (4) reports the difference in means",
  "(Islamic − secular) with classical standard errors in parentheses. Stars",
  "are based on these standard errors and differ from the original table for",
  "number of parties (** in Meyersson, 2014) and district center (no star in the",
  "original). *** p<0.01, ** p<0.05, * p<0.10."
)

# Saving the table, as a csv file, and making it into a word format,
# so we can make prefered table changes later on.
write.csv(table1_paper, "output/tables/table1.csv", row.names = FALSE)

ft <- flextable(table1_paper) |>
  set_header_labels(label   = "",
                    all     = "All",
                    islamic = "Islamic mayor",
                    secular = "Secular mayor",
                    diff    = "Difference") |>
  # Column numbers under the column names
  add_header_row(values = c("", "(1)", "(2)", "(3)", "(4)"),
                 colwidths = rep(1, 5), top = FALSE) |>
  add_footer_lines(notes) |>
  # Title above the table, plain bold Times New Roman
  set_caption(
    caption = as_paragraph(as_chunk(
      "Table 1: Descriptive statistics",
      props = fp_text_default(font.family = "Times New Roman",
                              font.size = 10, bold = TRUE))),
    fp_p = officer::fp_par(text.align = "left", padding.bottom = 4),
    align_with_table = FALSE) |>
  theme_booktabs() |>
  # Thin line under the column names
  hline(i = 1, j = 2:5, border = fp_border_default(width = 0.5), part = "header") |>
  align(j = 2:5, align = "center", part = "all") |>
  # Fonts are set after the footer is added, so the notes get Times New Roman
  font(fontname = "Times New Roman", part = "all") |>
  fontsize(size = 9, part = "all") |>
  fontsize(size = 8, part = "footer") |>
  italic(i = ~ label %in% group_names, j = 1, part = "body") |>
  padding(padding.top = 1, padding.bottom = 1, part = "body") |>
  # Tight header rows, as in Table 7
  padding(padding.top = 1, padding.bottom = 1, part = "header") |>
  autofit()
save_as_docx(ft, path = "output/tables/table1.docx")
