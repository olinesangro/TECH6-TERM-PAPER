#--------------------------------------------------------------
# TABLE 1: Descriptive Statistics
#--------------------------------------------------------------
source("replications/setup.R")

nrow(df_matched)

# Readable row labels, in the same order as vars from the setup-file
labels <- c("Female high school share, age 15-20",
            "Male high school share, age 15-20",
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
islamic <- df_matched |> filter(i94 == 1)    # Islamic mayor in 1994
secular <- df_matched |> filter(i94 == 0)    # secular mayor

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
sd_rows <- table1 |>
  transmute(row     = 2 * row_number(),
            label   = "",
            all     = paste0("(", f3(all_sd), ")"),
            islamic = paste0("(", f3(islamic_sd), ")"),
            secular = paste0("(", f3(secular_sd), ")"),
            diff    = paste0("(", f3(se), ")"))

# Shows the number of towns in each group
obs_row <- tibble(row     = 2 * nrow(table1) + 1,
                  label   = "Observations",
                  all     = formatC(nrow(df_matched), format = "d", big.mark = ","),
                  islamic = formatC(nrow(islamic),    format = "d", big.mark = ","),
                  secular = formatC(nrow(secular),    format = "d", big.mark = ","),
                  diff    = "")

# Stack the three pieces, sort so each mean sits above its SD
table1_paper <- bind_rows(mean_rows, sd_rows, obs_row) |>
  arrange(row) |>
  select(-row)

print(table1_paper, n = Inf, width = Inf)


# Saving the table, as a csv file, and making it into a word format, 
# so we can make prefered table changes later on. 
write.csv(table1_paper, "output/tables/table1.csv", row.names = FALSE)

ft <- flextable(table1_paper) |>
  set_header_labels(label   = "",
                    all     = "All",
                    islamic = "Islamic mayor",
                    secular = "Secular mayor",
                    diff    = "Difference") |>
  theme_booktabs() |>                                         
  align(j = 2:5, align = "center", part = "all") |>           
  font(fontname = "Times New Roman", part = "all") |>
  fontsize(size = 9, part = "all") |>
  padding(padding.top = 1, padding.bottom = 1, part = "body") |>   # tighter rows
  add_footer_lines(paste(
    "Notes: Columns 1-3 report means with standard deviations in parentheses.",
    "Column 4 reports the difference in means (Islamic - secular) with classical",
    "standard errors in parentheses. *** p<0.01, ** p<0.05, * p<0.10.")) |>
  autofit()
save_as_docx(ft, path = "output/tables/table1.docx")