#-------------------------------------------------------------------------------
# EXTENSION 1: MATCHING
#-------------------------------------------------------------------------------
source("replications/setup.R")

df_ext <- df |>
  zap_labels() |>
  filter(!is.na(iwm94), !is.na(hischshr1520f))

# Pre-election control set (2000-census variables excluded as potential bad controls)
ctrl_vars <- c("vshr_islam1994", "partycount", "lpop1994",
               "merkezi", "merkezp", "subbuyuk", "buyuk")

df_cc <- df_ext |>
  drop_na(all_of(ctrl_vars))

# Sample size before and after dropping missing values
print(c(nrow(df), nrow(df_cc)))
h <- 0.2398   # IK bandwidth for women from the paper, used in the RD-by-hand comparison


# By-hand diagnostic (does margin still predict education within each side of 
# cutoff?)
left  <- df_cc |> filter(iwm94 > -0.5, iwm94 < 0)
right <- df_cc |> filter(iwm94 >= 0,   iwm94 < 0.5)

l1 <- feols(hischshr1520f ~ iwm94,
            data = left, cluster = ~pcode)
l2 <- feols(hischshr1520f ~ iwm94 + vshr_islam1994 + partycount + lpop1994 +
              merkezi + merkezp + subbuyuk + buyuk,
            data = left, cluster = ~pcode)
l3 <- feols(hischshr1520f ~ iwm94 + vshr_islam1994 + partycount + lpop1994 +
              merkezi + merkezp + subbuyuk + buyuk | prov81,
            data = left, cluster = ~pcode)
l4 <- feols(hischshr1520f ~ iwm94 + partycount + lpop1994 +
              merkezi + merkezp + subbuyuk + buyuk | prov81,
            data = left, cluster = ~pcode)

r1 <- feols(hischshr1520f ~ iwm94,
            data = right, cluster = ~pcode)
r2 <- feols(hischshr1520f ~ iwm94 + vshr_islam1994 + partycount + lpop1994 +
              merkezi + merkezp + subbuyuk + buyuk,
            data = right, cluster = ~pcode)
r3 <- feols(hischshr1520f ~ iwm94 + vshr_islam1994 + partycount + lpop1994 +
              merkezi + merkezp + subbuyuk + buyuk | prov81,
            data = right, cluster = ~pcode)
r4 <- feols(hischshr1520f ~ iwm94 + partycount + lpop1994 +
              merkezi + merkezp + subbuyuk + buyuk | prov81,
            data = right, cluster = ~pcode)

etable(l1, l2, l3, l4, keep = "iwm94",
       headers = c("Margin only", "+ X", "+ X + FE", "+ FE, no vote share"))
etable(r1, r2, r3, r4, keep = "iwm94",
       headers = c("Margin only", "+ X", "+ X + FE", "+ FE, no vote share"))


# Defining near- and far-window comparisons
# Near: Islamic wins by less than 10 pp. Far: wins by 10-30 pp.
# The windows do not overlap, so no municipality is in both groups.
# Both are compared with the same Islamic losers (margin -0.5 to 0)
near_data <- df_cc |>
  filter((iwm94 > -0.5 & iwm94 < 0) | (iwm94 > 0 & iwm94 < 0.1)) |>
  mutate(treat = as.integer(iwm94 > 0))

far_data <- df_cc |>
  filter((iwm94 > -0.5 & iwm94 < 0) | (iwm94 >= 0.1 & iwm94 < 0.3)) |>
  mutate(treat = as.integer(iwm94 > 0))

near_data |> count(treat)
far_data |> count(treat)

far_data |>
  group_by(treat) |>
  summarise(across(c(hischshr1520f, vshr_islam1994, partycount, lpop1994, merkezi), mean),
            n = n())

# Propensity scores and overlap
ps_near <- glm(treat ~ vshr_islam1994 + partycount + lpop1994 +
                 merkezi + merkezp + subbuyuk + buyuk,
               family = binomial(link = "logit"),
               data = near_data)
near_data$pscore <- predict(ps_near, type = "response")

ps_far <- glm(treat ~ vshr_islam1994 + partycount + lpop1994 +
                merkezi + merkezp + subbuyuk + buyuk,
              family = binomial(link = "logit"),
              data = far_data)
far_data$pscore <- predict(ps_far, type = "response")

near_data |> group_by(treat) |> summarise(mean_p = mean(pscore), median_p = median(pscore))
far_data |> group_by(treat) |> summarise(mean_p = mean(pscore), median_p = median(pscore))

ggplot(near_data, aes(x = pscore, fill = factor(treat))) +
  geom_histogram(aes(y = after_stat(density)),
                 bins = 50, alpha = 0.6, position = "identity") +
  labs(title = "Propensity-score overlap: near Islamic wins (0-10 pp) vs Islamic losses",
       x = "estimated propensity score", fill = "treat")

ggplot(far_data, aes(x = pscore, fill = factor(treat))) +
  geom_histogram(aes(y = after_stat(density)),
                 bins = 50, alpha = 0.6, position = "identity") +
  labs(title = "Propensity-score overlap: far Islamic wins (10-30 pp) vs Islamic losses",
       x = "estimated propensity score", fill = "treat")


# Trim for common support - drop towns with a propensity score outside 
# (0.05, 0.95)
near_trim <- near_data |> filter(pscore > 0.05, pscore < 0.95)
far_trim  <- far_data  |> filter(pscore > 0.05, pscore < 0.95)

near_trim |> count(treat)
far_trim |> count(treat)

far_data |>
  filter(treat == 1) |>
  mutate(kept = pscore > 0.05 & pscore < 0.95) |>
  group_by(kept) |>
  summarise(n = n(), margin = mean(iwm94), vote_shr = mean(vshr_islam1994),
            parties = mean(partycount), lpop = mean(lpop1994))


# Match and estimate the effect - near and far
m_near <- matchit(treat ~ vshr_islam1994 + partycount + lpop1994 +
                    merkezi + merkezp + subbuyuk + buyuk,
                  data = near_trim, method = "nearest", distance = "glm")
summary(m_near)
love.plot(m_near, abs = TRUE, thresholds = 0.1)
md_near <- match.data(m_near)

match_near   <- feols(hischshr1520f ~ treat, data = md_near, cluster = ~pcode)
match_near_x <- feols(hischshr1520f ~ treat + vshr_islam1994 + partycount + lpop1994 +
                        merkezi + merkezp + subbuyuk + buyuk,
                      data = md_near, cluster = ~pcode)

m_far <- matchit(treat ~ vshr_islam1994 + partycount + lpop1994 +
                   merkezi + merkezp + subbuyuk + buyuk,
                 data = far_trim, method = "nearest", distance = "glm")
summary(m_far)
love.plot(m_far, abs = TRUE, thresholds = 0.1)
md_far <- match.data(m_far)

match_far   <- feols(hischshr1520f ~ treat, data = md_far, cluster = ~pcode)
match_far_x <- feols(hischshr1520f ~ treat + vshr_islam1994 + partycount + lpop1994 +
                       merkezi + merkezp + subbuyuk + buyuk,
                     data = md_far, cluster = ~pcode)

etable(match_near, match_near_x, match_far, match_far_x, keep = "treat",
       headers = c("Near", "Near + X", "Far", "Far + X"))


# Placebo test - inventing a fake cutoff, so effect should come out near zero
placebo <- df_cc |>
  filter(iwm94 > -0.5, iwm94 < -0.1) |>
  mutate(treat = as.integer(iwm94 > -0.2))

placebo |> count(treat)

m_pl <- matchit(treat ~ vshr_islam1994 + partycount + lpop1994 +
                  merkezi + merkezp + subbuyuk + buyuk,
                data = placebo, method = "nearest", distance = "glm")
summary(m_pl)
love.plot(m_pl, abs = TRUE, thresholds = 0.1)
md_pl <- match.data(m_pl)

match_pl   <- feols(hischshr1520f ~ treat, data = md_pl, cluster = ~pcode)
match_pl_x <- feols(hischshr1520f ~ treat + vshr_islam1994 + partycount + lpop1994 +
                      merkezi + merkezp + subbuyuk + buyuk,
                    data = md_pl, cluster = ~pcode)

etable(match_pl, match_pl_x, keep = "treat", headers = c("Placebo", "Placebo + X"))


# Baseline comparisons (naive OLS, OLS+X+FE, RD by hand)
ols_naive <- feols(hischshr1520f ~ i94, data = df_cc, cluster = ~pcode)
ols_ctrl  <- feols(hischshr1520f ~ i94 + vshr_islam1994 + partycount + lpop1994 +
                     merkezi + merkezp + subbuyuk + buyuk | prov81,
                   data = df_cc, cluster = ~pcode)

rd_by_hand <- feols(hischshr1520f ~ i94 + iwm94 + iwm94:i94,
                    data = df_cc |> filter(abs(iwm94) < h),
                    cluster = ~pcode)

etable(ols_naive, ols_ctrl, rd_by_hand, keep = "i94",
       headers = c("Naive OLS", "OLS + X + FE", "RD by hand"))


# Plotting all six estimates together
results <- tibble(
  estimate = c("Naive OLS",
               "OLS + controls + FE",
               "RD at cutoff",
               "Matching: near wins (0-10 pp)",
               "Matching: far wins (10-30 pp)",
               "Placebo (no one treated)"),
  coef = c(coef(ols_naive)["i94"], coef(ols_ctrl)["i94"], coef(rd_by_hand)["i94"],
           coef(match_near_x)["treat"], coef(match_far_x)["treat"], coef(match_pl_x)["treat"]),
  se   = c(se(ols_naive)["i94"], se(ols_ctrl)["i94"], se(rd_by_hand)["i94"],
           se(match_near_x)["treat"], se(match_far_x)["treat"], se(match_pl_x)["treat"])
) |>
  mutate(lo = coef - 1.96 * se,
         hi = coef + 1.96 * se)

results

ggplot(results, aes(x = coef, y = fct_rev(fct_inorder(estimate)))) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_pointrange(aes(xmin = lo, xmax = hi)) +
  labs(title = "Does the effect hold away from the cutoff?",
       x = "effect of Islamic mayor on female high school share (95% CI)",
       y = NULL)


# Robustness check (caliper + replacement, far window)
# Caliper - discard matches that are too dissimilar
# Replacement - one control can be reused for multiple treated towns
m_far_cal <- matchit(treat ~ vshr_islam1994 + partycount + lpop1994 +
                       merkezi + merkezp + subbuyuk + buyuk,
                     data = far_trim, method = "nearest", distance = "glm",
                     link = "linear.logit", replace = TRUE, caliper = 0.2)
summary(m_far_cal)
love.plot(m_far_cal, abs = TRUE, thresholds = 0.1)
md_far_cal <- match.data(m_far_cal)

match_far_cal_x <- feols(hischshr1520f ~ treat + vshr_islam1994 + partycount + lpop1994 +
                           merkezi + merkezp + subbuyuk + buyuk,
                         data = md_far_cal, weights = ~weights, cluster = ~pcode)

etable(match_far_x, match_far_cal_x, keep = "treat",
       headers = c("Far: nearest neighbour", "Far: caliper + replacement"))