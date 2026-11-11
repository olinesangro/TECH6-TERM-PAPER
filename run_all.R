#-------------------------------------------------------------------------------
# RUN ALL: regenerates every table and figure from regdata0.dta
# Open TECH6-EXAM-PROJECT.Rproj, then run: source("run_all.R")
#-------------------------------------------------------------------------------

# Start from an empty workspace, so nothing old is used by mistake
rm(list = ls())

# Tables (each script loads setup.R itself)
source("replications/tables/table-01.R")
source("replications/tables/table-02.R")
source("replications/tables/table-03.R")
source("replications/tables/table-07.R")

# Figures
source("replications/figures/figure-01.R")
source("replications/figures/figure-02.R")
source("replications/figures/figure-03.R")
source("replications/figures/figure-04.R")

cat("Done: tables are in output/tables, figures in output/figures\n")