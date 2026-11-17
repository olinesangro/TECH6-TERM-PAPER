# Replication of Meyersson (2014): Islamic Rule and the Empowerment of the Poor and Pious

TECH6 – Data Science and Econometrics, NHH, Autumn 2026
Group 7: Oline, Kristine, Maren

Meyersson, E. (2014). "Islamic Rule and the Empowerment of the Poor and Pious."
*Econometrica*, 82(1), 229–269.

## Overview

This repository is the replication package for our TECH6 term paper. It contains:

- **Replication (R):** Tables 1, 2, 3 and 7 and Figures 1, 2, 3 and 4 from the main text of
  Meyersson (2014), following the paper's own specifications: its controls, province fixed
  effects, standard errors clustered by province, and its bandwidths.
- **Extension 1 (R):** matching, to test whether the effect found at the cutoff also holds where
  the Islamic party won by larger margins.
- **Extension 2 (Python):** machine learning, to predict what Islamic-mayor municipalities
  would have had under a secular mayor.
- **One command:** `source("run_all.R")` regenerates every replication table and figure from
  `regdata0.dta`. The two extensions are run separately (see below).

The write-up (PDF) discusses the results. This README explains how to reproduce them.

## Quick start

1. Clone or download this repository.
2. Open `TECH6-TERM-PAPER.Rproj` in RStudio.
3. Run: `source("run_all.R")`

When the run is finished, the console prints
`Done: tables are in output/tables, figures in output/figures`.
Tables are saved to `output/tables/` and figures to `output/figures/`. The folders are created
automatically if they do not exist.

**Running the extensions** (from the project root, after the steps above):

- Extension 1: `source("extensions/extention_01.R")`
- Extension 2: `python extensions/extension_02.py`

## Good to know before running

- **Working directory:** all paths are relative to the project root. If the scripts cannot find
  `regdata0.dta` or `replications/setup.R`, the project was most likely not opened through the
  `.Rproj` file. In RStudio, use *Session → Set Working Directory → To Project Directory*.
  Extension 2 also reads `regdata0.dta` from the working directory, so run it from the project root.
- **Running single scripts:** every R script loads `replications/setup.R` itself, so any table or
  figure can be run on its own without running `run_all.R` first.
- **Runtime:** Figures 3 and 4 take the longest, because the local linear fit is computed on a
  grid of 50 points for every panel and side of the cutoff.
- **Warnings:** the console shows some warnings from `ggplot2` ("Removed rows containing
  missing values"). These come from observations outside the axis limits, which were set to
  match the paper's figures, and do not affect the results.

## Data

| File | Description | Source |
|------|-------------|--------|
| `regdata0.dta` | Municipality-level data on the 1994 local elections, census outcomes from 1990, 2000 and 2011, and covariates | Replication data from Meyersson (2014), shared on Canvas |

## Requirements

- R 4.6.1 and RStudio 2026.09.0 (build 174)
- R packages (all loaded by `setup.R`): `tidyverse`, `estimatr`, `fixest`, `causaldata`,
  `MatchIt`, `cobalt`, `rdrobust`, `rddensity`, `haven`, `patchwork`, `flextable`
- Python 3.12.4 with `pandas`, `numpy`, `matplotlib`, `scikit-learn` (Extension 2 only)

Install the R packages once with:

```r
install.packages(c("tidyverse", "estimatr", "fixest", "causaldata", "MatchIt", "cobalt",
                   "rdrobust", "rddensity", "haven", "patchwork", "flextable"))
```

Install the Python packages with:

```
pip install pandas numpy matplotlib scikit-learn
```

The results were produced on macOS. Exact package versions are listed under Software
environment at the bottom of this file.

## Repository structure

```
TECH6-TERM-PAPER/
├── TECH6-TERM-PAPER.Rproj     # RStudio project; open this first
├── run_all.R                  # One command that regenerates all replication results
├── regdata0.dta               # Data
├── README.md
├── replications/
│   ├── setup.R                # Packages, data, analysis sample, controls and shared helpers
│   ├── tables/                # table-01.R, table-02.R, table-03.R, table-07.R
│   └── figures/               # figure-01.R, figure-02.R, figure-03.R, figure-04.R
├── extensions/
│   ├── extention_01.R         # Extension 1: matching (R)
│   └── extension_02.py        # Extension 2: machine learning (Python)
└── output/
    ├── tables/                # Generated tables
    └── figures/               # Generated figures
```

`setup.R` contains what the scripts have in common: it loads the packages and the data, builds
the province identifier (`prov81`) from the 81 province dummies, defines the analysis sample
(`df_matched`) and the paper's control set (`..ctrl`), and holds two helper functions (`f3` for
three-decimal formatting and `stars` for significance stars). The local linear smoother used in
Figures 3 and 4 is defined inside `figure-03.R` and `figure-04.R`.

## Output map

| Result | Content | Script | Output file |
|--------|---------|--------|-------------|
| Table 1 | Descriptive statistics, Islamic vs. secular municipalities | `replications/tables/table-01.R` | `output/tables/table1.csv`, `table1.docx` |
| Table 2 | Islamic mayor and high school education in 2000: OLS and RD, women and men, enrollment, gender difference | `replications/tables/table-02.R` | `output/tables/table2.csv`, `table2.docx` |
| Table 3 | Robustness to bandwidth and polynomial order (50 RD regressions) | `replications/tables/table-03.R` | `output/tables/table3.csv`, `table3.docx` |
| Table 7 | Long-run effects on education and marriage in 2011 | `replications/tables/table-07.R` | `output/tables/table7.csv`, `table7.docx` |
| Figure 1 | Islamic win margin and Islamic vote share in 1994 | `replications/figures/figure-01.R` | `output/figures/figure1.png` |
| Figure 2a | Global histogram of the Islamic win margin | `replications/figures/figure-02.R` | `output/figures/figure2a.png` |
| Figure 2b | Density test at the cutoff | `replications/figures/figure-02.R` | `output/figures/figure2b.png` |
| Figure 3 | Covariates around the cutoff | `replications/figures/figure-03.R` | `output/figures/figure3.png` |
| Figure 4 | RD plots of high school completion, women and men, 2000 and 1990 | `replications/figures/figure-04.R` | `output/figures/figure4.png` |
| Extension 1 | Matching near and far from the cutoff: overlap, balance, placebo, comparison with OLS and RD | `extentions/extension_01.R` | Printed to the console and the RStudio Plots pane (not saved) |
| Extension 2 | Ridge, Lasso and polynomial OLS trained on secular municipalities; predicted untreated outcomes | `extentions/extension_02.py` | Printed to the console (plots shown with `plt.show()`, not saved) |

## Notes on the replication

- **Sample:** Tables 1–3 and Figure 1 use the same sample, `df_matched`, defined in `setup.R` as
  the 2,629 municipalities with non-missing values on all outcome, treatment and covariate
  variables. Table 7 uses its own sample (2,338 municipalities, as in the paper). Figures 2a, 3
  and 4 follow the author's graph code and use all municipalities with non-missing values on the
  variables plotted.
- **Specification:** we follow the paper: its covariates, province fixed effects (81 provinces),
  standard errors clustered by province, and the Imbens–Kalyanaraman bandwidths reported in the
  paper (hard-coded in Tables 2 and 7).
- **Table 1:** stars follow the levels used in the author's code (*** p<0.001, ** p<0.01, * p<0.05). The published table note states 1, 5 and 10 percent, which does not match the stars shown. All other tables use 1, 5 and 10 percent.
- **Figures 3 and 4:** following the author's graph code, the dots are bin averages
  (8-percentage-point bins in Figure 3, 4-point bins in Figure 4) and the lines are local linear
  fits with an Epanechnikov kernel and fixed bandwidths (0.06 in Figure 3, 0.08 in Figure 4),
  estimated separately on each side of the cutoff. The grey lines are approximate 95% bands
  (±2 standard errors).
- **Figure 2b:** the density test uses `rddensity`, on municipalities with a win margin within
  ±0.6; the estimate and standard error are printed below the figure. This differs from the
  McCrary (2008) test used in the paper, so the numbers differ.

## Notes on the extensions

- **Extension 1 (matching):** uses only covariates measured before the 1994 election (Islamic
  vote share, number of parties, log population, and the municipality-type indicators). The
  2000-census variables are excluded because they may themselves be affected by Islamic rule.
  The script compares Islamic winners with losers near the cutoff and 10–30 percentage points
  from it, using propensity-score overlap, trimming at 0.05–0.95, nearest-neighbour matching,
  love plots, a placebo test and a caliper robustness check.
- **Extension 2 (machine learning):** trains polynomial OLS, Ridge and Lasso on secular
  municipalities, chooses the polynomial degree and penalty with 5-fold cross-validation,
  predicts the untreated outcome for Islamic municipalities, and takes the effect as actual minus
  predicted. The random seed is fixed (`RANDOM_STATE = 1234`).
- The extensions are not part of `run_all.R`.
