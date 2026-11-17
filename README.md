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

## Data

| File | Description | Source |
|------|-------------|--------|
| `regdata0.dta` | Municipality-level data on the 1994 local elections, census outcomes from 1990, 2000 and 2011, and covariates | Replication data from Meyersson (2014), shared on Canvas |

## Requirements

- R 4.6.1 and RStudio 2026.09.0 (build 174)
- R packages (all loaded by `setup.R`): `tidyverse`, `estimatr`, `fixest`, `causaldata`,
  `MatchIt`, `cobalt`, `rdrobust`, `rddensity`, `haven`, `patchwork`, `flextable`
- Python 3.12.4 with `pandas`, `numpy`, `matplotlib`, `scikit-learn` (Extension 2 only)



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

