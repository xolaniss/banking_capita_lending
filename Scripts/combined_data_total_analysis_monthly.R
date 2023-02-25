# Description
# Data combination for modelling preparation by Xolani Sibande 19-01-2023

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

# Transformation ---------------------------------------------------------------

ba900_monthly_tbl <- 
  ba900_monthly$monthly_data$Totals_monthly_tbl %>% 
  pivot_wider(names_from = Series, values_from = Value) %>% 
  mutate(across(.cols = -Date, .fns = ~.x *100)) %>% 
  rename(
  )


# Descriptives ------------------------------------------------------------
descriptives_tbl <- ba900_monthly_tbl %>% 
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
  ba900_monthly_tbl = ba900_monthly_tbl
)

write_rds(artifacts_combined_totals_data, file = here("Outputs", "artifacts_combined_totals_data_monthly.rds"))


