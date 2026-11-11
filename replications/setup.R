#--------------------------------------------------------------
# SETUP: shared by every table, figure and extension
# Each script starts with source("Replications/setup.R")
#--------------------------------------------------------------

# The necessairy packages
library(tidyverse)
library(estimatr)
library(fixest)
library(causaldata)
library(MatchIt)
library(cobalt)
library(rdrobust)
library(rddensity)
library(haven)
library(patchwork)
library(flextable)

# The data
df <- read_dta("regdata0.dta")

# Province number for the province fixed effects. The paper uses the 81 province dummies. 
df$prov81 <- max.col(as.matrix(df[paste0("pd_", 1:81)]))

# Analysis sample
vars <- c("hischshr1520f", "hischshr1520m",
          "i94",
          "vshr_islam1994", "partycount",
          "lpop1994", "ageshr19", "ageshr60", "sexr", "shhs",
          "merkezi", "merkezp", "subbuyuk")
df_matched <- df |> filter(complete.cases(df[, vars]))


# The paper's controls, covariates + province fixed effects
setFixest_fml(..ctrl = ~ vshr_islam1994 + partycount + lpop1994 +
                ageshr19 + ageshr60 + sexr + shhs +
                merkezi + merkezp + subbuyuk + buyuk + factor(prov81))


# Formatting helpers, three decimals for the answers
f3 <- function(x) sprintf("%.3f", x)

# Significance stars as in the paper: *** 1%, ** 5%, * 10%, nothing if p is NA
stars <- function(p) {
  ifelse(is.na(p), "",
         ifelse(p < 0.01, "***",
                ifelse(p < 0.05, "**",
                       ifelse(p < 0.10, "*", ""))))
}


# Output folder, error if already in them 
dir.create("output/tables",  recursive = TRUE, showWarnings = FALSE)
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)