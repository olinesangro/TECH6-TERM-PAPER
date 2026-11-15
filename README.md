# Replication of Meyersson (2014): Islamic Rule and the Empowerment of the Poor and Pious

TECH6 – Data Science and Econometrics, NHH, Autumn 2026
Group: Oline, Kristine, Maren

Meyersson, E. (2014). "Islamic Rule and the Empowerment of the Poor and Pious."
*Econometrica*, 82(1), 229–269.

## Overview

This repository is the replication package for our TECH6 term paper. It contains:

- **Replication (R):** Tables 1, 2, 3 and 7 and Figures 1, 2, 3 and 4 from the main text of
  Meyersson (2014), following the paper's own specifications: its controls, province fixed
  effects, standard errors clustered by province, and its bandwidths.
- **Extensions:** two extensions, one in R and one in Python.
- **One command:** source("run_all.R") regenerates every table and figure from `regdata0.dta`. The extensions are run separately.

The write-up (PDF) discusses the results. This README explains how to reproduce them.

## Quick start

1. Clone or download this repository.
2. Open TECH6-TERM-PAPER.Rproj in RStudio.
4. Run: source("run_all.R")

When the run is finished, the console prints
`Done: tables are in output/tables, figures in output/figures`.
Tables are saved to `output/tables/` and figures to `output/figures/`. The folders are created automatically if they do not exist.

## Good to know before running

- **Working directory:** all paths are relative to the project root. If the scripts cannot find `regdata0.dta` or `replications/setup.R`, the project was most likely not opened through the `.Rproj` file. In RStudio, use *Session → Set Working Directory → To Project Directory*.
- **Running single scripts:** every script loads `Replications/setup.R` itself, so any table or figure can be run on its own without running `run_all.R` first.
- **Python extension:** Extension 2 is written in Python. This requires a working Python installation with the packages listed.
- **Runtime:** Figures 3 and 4 take the longest, because the bandwidth and the local linear fits are computed separately for every panel.
- **Warnings:** the console shows some warnings from `ggplot2` ("Removed rows containing
  missing values"). These come from observations outside the axis limits, which were set to match the paper's figures, and do not affect the results.

## Data

| File | Description | Source |
|------|-------------|--------|
| `regdata0.dta` | Municipality-level data on the 1994 local elections, census outcomes from 1990 and 2000, and covariates | Shared on Canvas, included in the repository files |

## Requirements

- R 4.6.1 and RStudio 2026.09.0 (build 174).
- R packages: `tidyverse`, `estimatr`, `fixest`, `causaldata`, `MatchIt`, `cobalt`,
  `rdrobust`, `rddensity`, `haven`, `patchwork`, `flextable`
- Python 3.12.4 with pandas, numpy, matplotlib, scikit-learn (Extension 2 only)

Install the R packages once with:

```r
install.packages(c("tidyverse", "estimatr", "fixest", "causaldata", "MatchIt", "cobalt",
                   "rdrobust", "rddensity", "haven", "patchwork", "flextable"))
```
Install the Python packages with:

```
pip install pandas numpy matplotlib scikit-learn

```

The results were produced on macOS. Exact package versions are listed
under Software environment at the bottom of this file.

## Repository structure

```
TECH6-TERM-PAPER/
├── TECH6-TERM-PAPER.Rproj     # RStudio project; open this first
├── run_all.R                  # One command that regenerates all results
├── regdata0.dta               # Data 
├── README.md
├── replications/
│   ├── setup.R                # Packages, data, analysis sample, controls and shared helpers
│   ├── tables/                # table-01.R, table-02.R, table-03.R, table-07.R
│   └── figures/               # figure-01.R, figure-02.R, figure-03.R, figure-04.R
├── extentions/
│   ├── extension_01.R         # Matching
│   └── extension_02.py        # Machine Learning
└── output/
    ├── tables/                # Generated tables
    └── figures/               # Generated figures
```

`setup.R` contains everything the scripts have in common: it loads the packages and the data, builds the province identifier for the province fixed effects, defines the analysis sample (`df_matched`) and the paper's control set, and holds the helper functions used by several scripts (number formatting, significance stars, and the local linear smoother used in the RD plots in Figures 3 and 4). Each step is defined in one place, so every table and figure uses the same sample and the same specification.

## Output map

| Result | Content | Script | Output file | Write-up |
|--------|---------|--------|-------------|----------|
| Table 1 | Summary statistics, Islamic vs. secular municipalities | `replications/tables/table-01.R` | `output/tables/table1.csv, table1.docx` | Section [x] |
| Table 2 | Main RD estimates, high school completion | `replications/tables/table-02.R` | `output/tables/table2.csv, table2.docx`| Section [x] |
| Table 3 | Robustness to bandwidth and polynomial order, women and men| `replications/tables/table-03.R` | `output/tables/table3.csv, table3.docx` | Section [x] |
| Table 7 | Long-run outcomes in 2011, global OLS and local linear RD | `replications/tables/table-07.R` | `output/tables/table7.csv, table7.docx` | Section [x] |
| Figure 1 | Islamic win margin and Islamic vote share in 1994 | `replications/figures/figure-01.R` | `output/figures/figure1.png` | Section [x] |
| Figure 2a | Global histogram of the Islamic win margin | `replications/figures/figure-02.R` | `output/figures/figure2a.png` | Section [x] |
| Figure 2b | Density test at the cutoff | `replications/figures/figure-02.R` | `output/figures/figure2b.png` | Section [x] |
| Figure 3 | Covariate balance around the cutoff | `replications/figures/figure-03.R` | `output/figures/figure3.png` | Section [x] |
| Figure 4 | RD plots of high school completion, women and men, 2000 and 1990 | `replications/figures/figure-04.R` | `output/figures/figure4.png` | Section [x] |
| Extension 1 | Matching near and far from the cutoff, with placebo | `extentions/extension_01.R` | printed to console | Section [x] |
| Extension 2 | Ridge/Lasso, predicted untreated outcomes | `extentions/extension_02.py` | printed to console | Section [x] |

## Notes on the replication

- **Analysis sample:** all results use the same sample, defined once in `setup.R` as
  municipalities with non-missing outcomes, treatment and covariates.
- **Specification:** we follow the paper's specification: its covariates, province fixed effects
  (81 provinces), standard errors clustered by province, and the paper's bandwidths.
- **Figures 3 and 4:** the bandwidth on each side of the cutoff is chosen with `rdrobust`, and
  the lines are local linear fits with a triangular kernel and 95% confidence bands, estimated
  separately on each side of the cutoff.
- **Figure 2b:** the density test uses `rddensity`; the estimate and standard error are printed
  below the figure. Because this differs from the McCrary (2008) test used in the paper, the
  numbers may differ slightly.

## Software environment
