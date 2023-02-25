# Description

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
preproprecing <- read_rds(here("Outputs", "artifacts_preprocessing_monthly.rds"))
banks_master_tbl <- preproprecing$masters$banks_master_tbl

# Dummy variable -----------------------------------------------------------------
banks_master_tbl %>% glimpse()
low_surplus_capital <- 0.01
banks_master_dummy_tbl <- 
  banks_master_tbl %>% 
  mutate(Surplus_dummy = ifelse(
    `Surplus capital` <= low_surplus_capital, 1, 0
  ))
 
surplus_dummy_gg <- 
  banks_master_dummy_tbl %>% 
  dplyr::select(Date, Bank, Surplus_dummy) %>% 
  pivot_longer(-c(Date, Bank), names_to = "Series", values_to = "Value") %>% 
  ggplot(aes(x = Date, y = Value, color = Series)) +
  geom_line() +
  facet_wrap(. ~ Bank)

bank_descriptives <- 
  banks_master_dummy_tbl %>% 
  dplyr::select(Date, Bank, `Surplus capital`, Surplus_dummy) %>% 
  filter(!Surplus_dummy == 0) %>% 
  pivot_longer(-c(Date, Bank), names_to = "Series", values_to = "Value") %>% 
  drop_na() %>% 
  group_by(Bank, Series) %>% 
  summarise(across(.cols = -c(Date),
                   .fns = list(Median = median, 
                               SD = sd,
                               Min = min,
                               Max = max,
                               Obs = ~ n()), 
                   .names = "{.fn}"))
bank_descriptives


# Export ---------------------------------------------------------------
artifacts_dummy <- list (
  banks_master_dummy_tbl = banks_master_dummy_tbl,
  bank_descriptives = bank_descriptives 
)

write_rds(artifacts_dummy, file = here("Outputs", "artifacts_dummy.rds"))


