library(tidyverse)
library(haven)
library(fixest)
library(MatchIt)
library(cobalt)

df <- read_dta("regdata0.dta") |>
  zap_labels() |>
  filter(!is.na(iwm94), !is.na(hischshr1520f))

df_cc <- df |>
  drop_na(vshr_islam1994, partycount, lpop1994, merkezi, merkezp, subbuyuk, buyuk)

h <- 0.24



left  <- df_cc |> filter(iwm94 > -0.5, iwm94 < 0)
right <- df_cc |> filter(iwm94 >= 0,   iwm94 < 0.5)

l1 <- feols(hischshr1520f ~ iwm94,
            data = left, cluster = ~province_pre)
l2 <- feols(hischshr1520f ~ iwm94 + vshr_islam1994 + partycount + lpop1994 +
              merkezi + merkezp + subbuyuk + buyuk,
            data = left, cluster = ~province_pre)
l3 <- feols(hischshr1520f ~ iwm94 + vshr_islam1994 + partycount + lpop1994 +
              merkezi + merkezp + subbuyuk + buyuk | province_pre,
            data = left, cluster = ~province_pre)
l4 <- feols(hischshr1520f ~ iwm94 + partycount + lpop1994 +
              merkezi + merkezp + subbuyuk + buyuk | province_pre,
            data = left, cluster = ~province_pre)

r1 <- feols(hischshr1520f ~ iwm94,
            data = right, cluster = ~province_pre)
r2 <- feols(hischshr1520f ~ iwm94 + vshr_islam1994 + partycount + lpop1994 +
              merkezi + merkezp + subbuyuk + buyuk,
            data = right, cluster = ~province_pre)
r3 <- feols(hischshr1520f ~ iwm94 + vshr_islam1994 + partycount + lpop1994 +
              merkezi + merkezp + subbuyuk + buyuk | province_pre,
            data = right, cluster = ~province_pre)
r4 <- feols(hischshr1520f ~ iwm94 + partycount + lpop1994 +
              merkezi + merkezp + subbuyuk + buyuk | province_pre,
            data = right, cluster = ~province_pre)

etable(l1, l2, l3, l4, keep = "iwm94",
       headers = c("Margin only", "+ X", "+ X + FE", "+ FE, no vote share"))
etable(r1, r2, r3, r4, keep = "iwm94",
       headers = c("Margin only", "+ X", "+ X + FE", "+ FE, no vote share"))



near_data <- df_cc |>
  filter((iwm94 > -0.5 & iwm94 < 0) | (iwm94 > 0 & iwm94 < h)) |>
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
  labs(title = "Propensity-score overlap: near Islamic wins vs Islamic losses",
       x = "estimated propensity score", fill = "treat")

ggplot(far_data, aes(x = pscore, fill = factor(treat))) +
  geom_histogram(aes(y = after_stat(density)),
                 bins = 50, alpha = 0.6, position = "identity") +
  labs(title = "Propensity-score overlap: far Islamic wins (10-30 pp) vs Islamic losses",
       x = "estimated propensity score", fill = "treat")



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



m_near <- matchit(treat ~ vshr_islam1994 + partycount + lpop1994 +
                    merkezi + merkezp + subbuyuk + buyuk,
                  data = near_trim, method = "nearest", distance = "glm")
summary(m_near)
love.plot(m_near, abs = TRUE, thresholds = 0.1)
md_near <- match.data(m_near)

match_near   <- feols(hischshr1520f ~ treat, data = md_near, cluster = ~province_pre)
match_near_x <- feols(hischshr1520f ~ treat + vshr_islam1994 + partycount + lpop1994 +
                        merkezi + merkezp + subbuyuk + buyuk,
                      data = md_near, cluster = ~province_pre)

m_far <- matchit(treat ~ vshr_islam1994 + partycount + lpop1994 +
                   merkezi + merkezp + subbuyuk + buyuk,
                 data = far_trim, method = "nearest", distance = "glm")
summary(m_far)
love.plot(m_far, abs = TRUE, thresholds = 0.1)
md_far <- match.data(m_far)

match_far   <- feols(hischshr1520f ~ treat, data = md_far, cluster = ~province_pre)
match_far_x <- feols(hischshr1520f ~ treat + vshr_islam1994 + partycount + lpop1994 +
                       merkezi + merkezp + subbuyuk + buyuk,
                     data = md_far, cluster = ~province_pre)

etable(match_near, match_near_x, match_far, match_far_x, keep = "treat",
       headers = c("Near", "Near + X", "Far", "Far + X"))



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

match_pl   <- feols(hischshr1520f ~ treat, data = md_pl, cluster = ~province_pre)
match_pl_x <- feols(hischshr1520f ~ treat + vshr_islam1994 + partycount + lpop1994 +
                      merkezi + merkezp + subbuyuk + buyuk,
                    data = md_pl, cluster = ~province_pre)

etable(match_pl, match_pl_x, keep = "treat", headers = c("Placebo", "Placebo + X"))



ols_naive <- feols(hischshr1520f ~ i94, data = df, cluster = ~province_pre)
ols_ctrl  <- feols(hischshr1520f ~ i94 + vshr_islam1994 + partycount + lpop1994 +
                     merkezi + merkezp + subbuyuk + buyuk | province_pre,
                   data = df, cluster = ~province_pre)

rd_by_hand <- feols(hischshr1520f ~ i94 + iwm94 + iwm94:i94,
                    data = df |> filter(abs(iwm94) < h),
                    cluster = ~province_pre)

etable(ols_naive, ols_ctrl, rd_by_hand, keep = "i94",
       headers = c("Naive OLS", "OLS + X + FE", "RD by hand"))



results <- tibble(
  estimate = c("Naive OLS",
               "OLS + controls + FE",
               "RD at cutoff",
               "Matching: near wins",
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



m_far_cal <- matchit(treat ~ vshr_islam1994 + partycount + lpop1994 +
                       merkezi + merkezp + subbuyuk + buyuk,
                     data = far_data, method = "nearest", distance = "glm",
                     link = "linear.logit", replace = TRUE, caliper = 0.2)
summary(m_far_cal)
love.plot(m_far_cal, abs = TRUE, thresholds = 0.1)
md_far_cal <- match.data(m_far_cal)

match_far_cal_x <- feols(hischshr1520f ~ treat + vshr_islam1994 + partycount + lpop1994 +
                           merkezi + merkezp + subbuyuk + buyuk,
                         data = md_far_cal, weights = ~weights, cluster = ~province_pre)

etable(match_far_x, match_far_cal_x, keep = "treat",
       headers = c("Far: trimmed, class workflow", "Far: caliper + replacement"))

#hello