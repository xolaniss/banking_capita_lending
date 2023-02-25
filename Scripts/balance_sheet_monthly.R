# Description
# Monthly data by Xolani Sibande 19-01-23

# Preliminaries -----------------------------------------------------------
library(tidyverse)
library(readr)
library(readxl)
library(here)
library(lubridate)
library(xts)
library(tseries)
library(broom)
library(glue)
library(vars)
library(PNWColors)
library(patchwork)
library(psych)
library(kableExtra)
library(strucchange)
library(timetk)
library(purrr)
library(pins)
library(uniqtag)
library(scales)

# Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))
source(here("Functions", "balance_sheet_rename_gg.R"))
source(here("Functions", "summarise_quarter_last.R"))

# Import -------------------------------------------------------------
balance_sheet <- read_rds(here("Outputs", "artifacts_ba900.rds"))
Totals_monthly_tbl <-  balance_sheet$aggregated_data$total_aggregation_tbl
absa_monthly_tbl <- balance_sheet$aggregated_data$absa_aggregation_tbl
fnb_monthly_tbl <- balance_sheet$aggregated_data$fnb_aggregation_tbl
nedbank_monthly_tbl <- balance_sheet$aggregated_data$nedbank_aggregation_tbl
standard_monthly_tbl <- balance_sheet$aggregated_data$standard_aggregation_tbl
capitec_monthly_tbl <- balance_sheet$aggregated_data$capitec_aggregation_tbl

# Graphing ---------------------------------------------------------------
Total_monthly_gg <- 
  Totals_monthly_tbl %>% 
  balance_sheet_rename_gg()
absa_monthly_gg <- 
  absa_monthly_tbl %>% 
  balance_sheet_rename_gg()
fnb_monthly_gg <- 
  fnb_monthly_tbl %>% 
  balance_sheet_rename_gg()
nedbank_monthly_gg <- 
  nedbank_monthly_tbl %>% 
  balance_sheet_rename_gg()
standard_monthly_gg <- 
  standard_monthly_tbl %>% 
  balance_sheet_rename_gg()
capitec_monthly_gg <-
  capitec_monthly_tbl %>% 
  balance_sheet_rename_gg()
  
# Export ---------------------------------------------------------------
artifacts_balance_sheet_monthly <- list (
  monthly_data = list(
    Totals_monthly_tbl = Totals_monthly_tbl,
    absa_monthly_tbl = absa_monthly_tbl,
    fnb_monthly_tbl = fnb_monthly_tbl,
    nedbank_monthly_tbl = nedbank_monthly_tbl, 
    standard_monthly_tbl = standard_monthly_tbl,
    capitec_monthly_tbl = capitec_monthly_tbl
  ),
  
  monthly_graphs = list(
    Total_monthly_gg = Total_monthly_gg,
    absa_monthly_gg = absa_monthly_gg,
    fnb_monthly_gg = fnb_monthly_gg,
    nedbank_monthly_gg = nedbank_monthly_gg,
    standard_monthly_gg  = standard_monthly_gg ,
    capitec_monthly_gg = capitec_monthly_gg
  )
  
)

write_rds(artifacts_balance_sheet_monthly, 
          file = here("Outputs", "artifacts_balance_sheet_monthly.rds"))


