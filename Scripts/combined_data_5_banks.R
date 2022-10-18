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
library(fDMA)
library(vars)
library(urca)
library(mFilter)
library(car)

# Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))

# Import -------------------------------------------------------------
capital_buffers <- read_rds(here("Outputs", "artifacts_capital_buffers.rds"))
balance_sheet_to_gdp <- read_rds(here("Outputs", "artifacts_balance_sheet_gdp.rds"))
ba900_quartely <- read_rds(here("Outputs", "artifacts_balance_sheet_quartely.rds"))
general <- read_rds(here("Outputs", "artifacts_general.rds"))


# Cleaning ----------------------------------------------------------------
capital_buffers_tbl <- 
  capital_buffers$data$capital_buffers_tbl %>% 
  dplyr::filter(Bank %in% c("ABSA BANK", "CAPITEC BANK", "FIRSTRAND BANK", "NEDBANK", "STANDARD BANK")) %>% 
  pivot_longer(-c(Date, Bank), names_to = "Series", values_to = "Value") %>% 
  group_by(Bank, Series) %>% 
  summarise_by_time(
    .date_var = Date, 
    .by = "quarter",
    Value = mean(Value)
  ) %>% 
  pivot_wider(names_from = Series, values_from = Value)

ba900_quarterly_levels_tbl <- 
  list("ABSA BANK" = ba900_quartely$quarterly_data$absa_quarter_tbl , 
       "FIRSTRAND BANK" = ba900_quartely$quarterly_data$fnb_quarter_tbl,
       "STANDARD BANK" = ba900_quartely$quarterly_data$standard_quarter_tbl,
       "NEDBANK" = ba900_quartely$quarterly_data$nedbank_quarter_tbl,
       "CAPITEC BANK" = ba900_quartely$quarterly_data$capitec_quarter_tbl) %>% 
  bind_rows(.id = "Bank") %>% 
  ungroup() %>% 
  pivot_wider(names_from = Series, values_from = Value)

ba900_quarterly_gdp_ratio_tbl <- 
  list("ABSA BANK" = balance_sheet_to_gdp$data$absa_gdp_tbl , 
     "FIRSTRAND BANK" = balance_sheet_to_gdp$data$fnb_gdp_tbl,
     "STANDARD BANK" = balance_sheet_to_gdp$data$standard_gdp_tbl,
     "NEDBANK" = balance_sheet_to_gdp$data$nedbank_gdp_tbl,
     "CAPITEC BANK" = balance_sheet_to_gdp$data$capitec_gdp_tbl) %>% 
  bind_rows(.id = "Bank") %>% 
  ungroup() %>% 
  pivot_wider(names_from = Series, values_from = Value)



# Joining -----------------------------------------------------------------
combined_5_banks_tbl <- 
  capital_buffers_tbl %>% 
  left_join(., ba900_quarterly_levels_tbl, by = c("Date" = "Date", "Bank" = "Bank")) %>% 
  left_join(., ba900_quarterly_gdp_ratio_tbl, by = c("Date" = "Date", "Bank" = "Bank"))



# Descriptives ------------------------------------------------------------
descriptives_tbl <- combined_5_banks_tbl %>% 
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

descriptives_by_bank_tbl <- combined_5_banks_tbl %>% 
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
artifacts_combined_banks <- list (
  descriptives_tbl = descriptives_tbl,
  descriptives_by_bank_tbl = descriptives_by_bank_tbl,
  combined_5_banks_tbl = combined_5_banks_tbl
)

write_rds(artifacts_combined_banks, file = here("Outputs", "artifacts_combined_banks.rds"))


