# Description
# Preliminary panel for modelling 18 October 2022
# Preliminaries -----------------------------------------------------------
# core
library(tidyverse)
library(readr)
library(readxl)
library(here)
library(lubridate)
library(xts)
library(broom)
library(glue)
library(scales)
library(kableExtra)
library(pins)
library(timetk)
library(uniqtag)

# graphs
library(PNWColors)
library(patchwork)

# eda
library(psych)
library(DataExplorer)
library(skimr)

# econometrics
library(tseries)
library(strucchange)
library(vars)
library(urca)
library(mFilter)
library(car)

# Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))

# Import -------------------------------------------------------------
ba900_monthly <- read_rds(here("Outputs", "artifacts_balance_sheet_monthly.rds"))



# Cleaning ----------------------------------------------------------------
ba900_monthly_levels_tbl <- 
  list("ABSA BANK" = ba900_monthly$monthly_data$absa_monthly_tbl , 
       "FIRSTRAND BANK" = ba900_monthly$monthly_data$fnb_monthly_tbl,
       "STANDARD BANK" = ba900_monthly$monthly_data$standard_monthly_tbl,
       "NEDBANK" = ba900_monthly$monthly_data$nedbank_monthly_tbl,
       "CAPITEC BANK" = ba900_monthly$monthly_data$capitec_monthly_tbl) %>% 
  bind_rows(.id = "Bank") %>% 
  ungroup() %>% 
  pivot_wider(names_from = Series, values_from = Value)


# Descriptives ------------------------------------------------------------
descriptives_tbl <- ba900_monthly_levels_tbl %>% 
  drop_na() %>% 
  pivot_longer(-c(Date, Bank), names_to = "Variable", values_to = "Value") %>% 
  group_by(Variable) %>% 
  summarise(across(.cols = -c(Date, Bank),
                   .fns = list(Median = median, 
                               SD = sd,
                               Min = min,
                               Max = max,
                               IQR = IQR,
                               Obs = ~ n()), 
                   .names = "{.fn}"))

descriptives_by_bank_tbl <-  ba900_monthly_levels_tbl %>% 
  drop_na() %>% 
  pivot_longer(-c(Date, Bank), names_to = "Variable", values_to = "Value") %>% 
  group_by(Bank, Variable) %>% 
  summarise(across(.cols = -c(Date),
                   .fns = list(Median = median, 
                               SD = sd,
                               Min = min,
                               Max = max,
                               IQR = IQR,
                               Obs = ~ n()), 
                   .names = "{.fn}"))


# Export ---------------------------------------------------------------
artifacts_combined_banks_monthly <- list (
  descriptives_tbl = descriptives_tbl,
  descriptives_by_bank_tbl = descriptives_by_bank_tbl,
  ba900_monthly_levels_tbl = ba900_monthly_levels_tbl
)

write_rds(artifacts_combined_banks_monthly, file = here("Outputs", "artifacts_combined_banks_monthly.rds"))


