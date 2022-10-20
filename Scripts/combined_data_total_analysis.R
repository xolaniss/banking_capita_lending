# Description
# Data combination for modelling preparation by Xolani Sibande 17 October 2022

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


# Transformation ---------------------------------------------------------------
quarterly_capital_buffer_tbl <- 
  general$data$car_tbl %>% 
  dplyr::select(Date, `Surplus capital`) %>% 
  summarise_by_time(.date_var = Date, 
                    .by = "quarter", 
                    `Capital buffer` = mean(`Surplus capital`))

balance_sheet_to_gdp_tbl <- 
  balance_sheet_to_gdp$data$total_gdp_tbl %>% 
  pivot_wider(names_from = Series, values_from = Value) %>% 
  mutate(across(.cols = -Date, .fns = ~.x *100)) %>% 
  rename(
    
  )

ba900_quartely_tbl <- 
  ba900_quartely$quarterly_data$Totals_quarter_tbl %>% 
  pivot_wider(names_from = Series, values_from = Value)

real_gdp_tbl <- 
  general$data$credit_cycle_tbl %>% 
  pivot_wider(names_from = Cycles, values_from = value) %>% 
  dplyr::select(-Credit)

# Joining -----------------------------------------------------------------
ba900_gdp_ratio_combined_tbl <- 
  balance_sheet_to_gdp_tbl %>% 
  left_join(., quarterly_capital_buffer_tbl, by = c("Date" = "Date")) %>% 
  left_join(., real_gdp_tbl, by = c("Date" = "Date"))


ba900_levels_combined_tbl <- 
  ba900_quartely_tbl %>% 
  left_join(., quarterly_capital_buffer_tbl, by = c("Date" = "Date")) %>% 
  left_join(., real_gdp_tbl, by = c("Date" = "Date"))


# Descriptives ------------------------------------------------------------
descriptives_tbl <- ba900_gdp_ratio_combined_tbl %>% 
  pivot_longer(-Date, names_to = "Variable", values_to = "Value") %>% 
  group_by(Variable) %>% 
  summarise(across(.cols = -Date,
                   .fns = list(Median = median, 
                               SD = sd,
                               Min = min,
                               Max = max,
                               IQR = IQR,
                               Obs = ~ n()), 
                   .names = "{.fn}"))

  


# Export ---------------------------------------------------------------
artifacts_combined_totals_data <- list (
  descriptives_tbl = descriptives_tbl,
  ba900_gdp_ratio_combined_tbl = ba900_gdp_ratio_combined_tbl,
  ba900_levels_combined_tbl = ba900_levels_combined_tbl
)

write_rds(artifacts_combined_totals_data, file = here("Outputs", "artifacts_combined_totals_data.rds"))


