# Description
# Transformation o quarterly and getting ratio to GDP

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
Totals_tbl <-  balance_sheet$aggregated_data$total_aggregation_tbl
absa_tbl <- balance_sheet$aggregated_data$absa_aggregation_tbl
fnb_tbl <- balance_sheet$aggregated_data$fnb_aggregation_tbl
nedbank_tbl <- balance_sheet$aggregated_data$nedbank_aggregation_tbl
standard_tbl <- balance_sheet$aggregated_data$standard_aggregation_tbl
capitec_tbl <- balance_sheet$aggregated_data$capitec_aggregation_tbl

# Transformations ---------------------------------------------------------
Totals_quarter_tbl <- 
  Totals_tbl %>% 
  summarise_quarter_last()
absa_quarter_tbl <- 
  absa_tbl %>% 
  summarise_quarter_last()
fnb_quarter_tbl <- 
  fnb_tbl %>% 
  summarise_quarter_last()
nedbank_quarter_tbl <- 
  nedbank_tbl %>% 
  summarise_quarter_last()
standard_quarter_tbl <- 
  standard_tbl %>% 
  summarise_quarter_last()
capitec_quarter_tbl <- 
  capitec_tbl %>% 
  summarise_quarter_last()

# Graphing ---------------------------------------------------------------
Total_quartely_gg <- 
  Totals_quarter_tbl %>% 
  balance_sheet_rename_quartely_gg()
absa_quartely_gg <- 
  absa_quarter_tbl %>% 
  balance_sheet_rename_quartely_gg()
fnb_quartely_gg <- 
  fnb_quarter_tbl %>% 
  balance_sheet_rename_quartely_gg()
nedbank_quartely_gg <- 
  nedbank_quarter_tbl %>% 
  balance_sheet_rename_quartely_gg()
standard_quartely_gg <- 
  standard_quarter_tbl %>% 
  balance_sheet_rename_quartely_gg()
capitec_quartely_gg <-
  capitec_quarter_tbl %>% 
  balance_sheet_rename_quartely_gg()
  
# Export ---------------------------------------------------------------
artifacts_balance_sheet_quartely <- list (
  quarterly_data = list(
    Totals_quarter_tbl = Totals_quarter_tbl,
    absa_quarter_tbl = absa_quarter_tbl,
    fnb_quarter_tbl = fnb_quarter_tbl,
    nedbank_quarter_tbl = nedbank_quarter_tbl, 
    standard_quarter_tbl = standard_quarter_tbl,
    capitec_quarter_tbl = capitec_quarter_tbl
  ),
  
  quartely_graphs = list(
    Total_quartely_gg = Total_quartely_gg,
    absa_quartely_gg = absa_quartely_gg,
    fnb_quartely_gg = fnb_quartely_gg,
    nedbank_quartely_gg = nedbank_quartely_gg,
    standard_quartely_gg  = standard_quartely_gg ,
    capitec_quartely_gg = capitec_quartely_gg
  )
  
)

write_rds(artifacts_balance_sheet_quartely, 
          file = here("Outputs", "artifacts_balance_sheet_quartely.rds"))


