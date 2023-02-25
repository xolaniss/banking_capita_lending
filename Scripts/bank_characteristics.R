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
library(janitor)
library(datawizard)

# econometrics
library(tseries)
library(strucchange)
library(vars)
library(urca)
library(mFilter)
library(car)

# Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))
source(here("Functions", "formular_function.R"))

# Import -------------------------------------------------------------
preprocessed_data <-
  read_rds(here("Outputs", "artifacts_preprocessing_monthly.rds"))
preprocessed_data_banks_tbl <-
  preprocessed_data$masters$banks_master_tbl
preprocessed_data_banks_tbl %>% glimpse()

# Transformations ---------------------------------------------------------
preprocessed_data_banks_base_tbl <-
  preprocessed_data_banks_tbl %>%
  mutate(across(
    .cols = 3:9,
    .fns = ~ log(.x),
    .names = "Log of {.col}"
  )) %>%     # logging loans
  mutate(across(
    .cols = starts_with("Log of"),
    .fns = ~ .x - lag(.x, n = 1),
    .names = "Change in {.col}"
  )) %>%     # one month change
  mutate(across(
    .cols = matches("Surplus capital"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  )) %>%   # one month change
  mutate(across(
    .cols = 10:15,
    .fns =  ~ .x - `Repo rate`,
    .names = "Interest margin using {.col}"
  ))  %>%    # Interest margin (demand)
  mutate(across(
    .cols = matches("Interest margin using"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  ))  %>%    # one month change
  mutate(across(
    .cols = matches("Total assets"),
    .fns = ~ log(.x),
    .names = "Log of {.col}"
  )) %>%     # logging total loans
  mutate(across(
    .cols = matches("Log of Total assets"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Return on assets"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Return on equity"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Level one high"),
    .fns = ~ log(.x),
    .names = "Log of {.col}"
  )) %>%     # logging liquidity
  mutate(across(
    .cols = contains("Log of level one high"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  )) %>%
  clean_names() %>%
  mutate(year = lubridate::year(date))

preprocessed_data_banks_base_tbl %>%
  glimpse()


# Outliers ----------------------------------------------------------------
preprocessed_data_banks_base_tbl <-
  preprocessed_data_banks_base_tbl %>%
  mutate(across(contains("change_in"), .fns = ~ winsorize(.x, threshold = .01))) %>%
  mutate(across(
    contains("change_in_surplus_capital"),
    .fns = ~ winsorize(.x, threshold = .01)
  )) %>%
  mutate(across(
    contains("change_in_interest_margin_using"),
    .fns = ~ winsorize(.x, threshold = .4)
  ))