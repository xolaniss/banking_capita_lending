# Description
# Preprocessing for panel models by Xolani Sibande October 31

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

# 0.0 Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))

#  1. Total  ----------------------------------------------------------------

# 1.1. Asset data --------------------------------------------------------
combined_data <- read_rds(here("Outputs", "artifacts_combined_totals_data.rds"))
combined_gdp_ratio_data_tbl <- combined_data$ba900_gdp_ratio_combined_tbl %>% 
  dplyr::select(-`Real GDP`, -`Capital buffer`)
combined_level_data_tbl <- combined_data$ba900_levels_combined_tbl %>% 
  dplyr::select(-`Real GDP`, -`Capital buffer`)

# 1.2. Lending Rate ------------------------------------------------------
combined_lending <- read_rds(here("Outputs", "artifacts_combined_lending.rds"))
combined_lending_tbl <- combined_lending$combined_lending_tbl %>% 
  filter(Bank == "TOTAL BANKS") %>% 
  dplyr::select(-Bank) %>% 
  pivot_wider(names_from = Series, values_from = Value)

# 1.3 Capital buffers -------------------------------------------------------------------
capital_buffers <- read_rds(here("Outputs", "artifacts_general.rds"))
capital_buffer_tbl <- 
    capital_buffers$data$car_tbl %>% 
    dplyr::select(Date, `Minimum requirement`, `Surplus capital`) %>% 
  pivot_longer(-Date, names_to = "Series", values_to = "Value") %>% 
    group_by(Series) %>% 
    summarise_by_time(.date_var = Date, 
                      .by = "quarter", 
                      Value = mean(Value)) %>% 
  relocate(Date, .before = Series) %>% 
  pivot_wider(names_from = Series, values_from = Value)

#  2 Banks ----------------------------------------------------------------

# 2.1.  Asset data ------------------------------------------------------
combined_banks_data <- read_rds(here("Outputs", "artifacts_combined_banks.rds"))
combined_data_level_banks_tbl <- combined_banks_data$ba900_quarterly_levels_tbl
combined_data_gdp_ratio_banks_tbl <- combined_banks_data$ba900_quarterly_gdp_ratio_tbl

# 2.2 Lending Rates -----------------------------------------------------
combined_lending_banks_tbl <- combined_lending$combined_lending_tbl %>% 
  filter(!Bank == "TOTAL BANKS") %>% 
  pivot_wider(names_from = Series, values_from = Value)

# 2.3 Capital buffers ---------------------------------------------------
capital_buffers_banks <- read_rds(here("Outputs", "artifacts_capital_buffers.rds"))
capital_buffers_banks_tbl <- 
  capital_buffers_banks$data$capital_buffers_tbl %>% 
  dplyr::filter(Bank %in% c("ABSA BANK", "CAPITEC BANK", "FIRSTRAND BANK", "NEDBANK", "STANDARD BANK")) %>% 
  pivot_longer(-c(Date, Bank), names_to = "Series", values_to = "Value") %>% 
  group_by(Bank, Series) %>% 
  summarise_by_time(
    .date_var = Date, 
    .by = "quarter",
    Value = mean(Value)
  ) %>% 
  relocate(Date, .before = Bank) %>% 
  pivot_wider(names_from = Series, values_from = Value)

# 3 Macro  ------------------------------------------------
repo_rate_tbl <- read_excel(here("Data", "Repo.xlsx")) %>% 
  mutate(Date = seq(as.Date("2008-01-01"), as.Date("2021-02-01"), by = "month")) %>% 
  pivot_longer(-Date, names_to = "Series", values_to = "Value") %>% 
  summarise_by_time(.date_var = Date, 
                    .by = "quarter", 
                   Value = mean(Value)
                   ) %>% 
  rename("Repo Rate" = "Value")

macro_tbl <- combined_data$ba900_gdp_ratio_combined_tbl %>% 
  dplyr::select(Date, `Real GDP`) %>% 
  left_join(., repo_rate_tbl, by = c("Date" = "Date"))

# 4. Controls ------------------------------------------------------------
controls <- read_rds(here("Outputs", "artifacts_controls.rds"))
controls_tbl <- 
  controls$controls_tbl %>% 
  relocate(Date, .before = "Bank") %>% 
  pivot_wider(values_from = Value, names_from = Series)


# 5. Master tibble -----------------------------------------------------------
total_master_tbl <- 
  combined_level_data_tbl %>% 
  left_join(., combined_gdp_ratio_data_tbl, by = c("Date" = "Date")) %>% 
  left_join(., combined_lending_tbl, by = c("Date" = "Date")) %>% 
  left_join(., capital_buffer_tbl, by = c("Date" = "Date")) 

total_master_tbl %>% glimpse()

banks_master_tbl <- combined_data_level_banks_tbl %>% 
  left_join(., combined_data_gdp_ratio_banks_tbl, by = c("Date" = "Date", "Bank" = "Bank")) %>% 
  left_join(., combined_lending_banks_tbl, by = c("Date" = "Date", "Bank" = "Bank")) %>% 
  left_join(., capital_buffers_banks_tbl, by = c("Date" = "Date", "Bank" = "Bank")) %>% 
  left_join(., controls_tbl, by = c("Date" = "Date", "Bank" = "Bank")) %>% 
  left_join(., macro_tbl, by = c("Date" = "Date"))


banks_master_tbl %>% glimpse()

# 6. Modelling transformations -----------------------------------------------
banks_master_trans_tbl <- 
  banks_master_tbl %>% 
  mutate(across(.cols = 3:8, .fns = ~ log(.x), .names = "Log of {.col}")) %>%  # logging loans
  mutate(across(.cols = 37:42, .fns = ~ .x - lag(.x, n = 1), .names = "Change in {.col}")) %>%  # change in logs loans
  mutate(across(.cols = 10:15, .fns = ~ .x - lag(.x), .names = "Change in {.col}")) %>%  # /GDP changes
  mutate(across(.cols = 17:22, .fns = ~  lag(.x), .names = "First lag of {.col}"))  %>% 
  mutate(across(.cols = 17:22, .fns = ~  lag(.x, n = 2), .names = "Second lag of {.col}")) %>% 
  mutate(across(.cols = 17:22, .fns = ~  lag(.x, n = 3), .names = "Third lag of {.col}")) %>% 
  mutate(across(.cols = 36, .fns = ~  lag(.x, n = 1), .names = "First lag of {.col}")) %>%  # Repo lags
  mutate(across(.cols = 36, .fns = ~  lag(.x, n = 2), .names = "Second lag of {.col}")) %>% 
  mutate(across(.cols = 36, .fns = ~  lag(.x, n = 3), .names = "Third lag of {.col}")) %>% 
  mutate(across(.cols = 23, .fns = ~  lag(.x, n = 1), .names = "First lag of {.col}")) %>% # Minimum capital lags
  mutate(across(.cols = 23, .fns = ~  lag(.x, n = 2), .names = "Second lag of {.col}")) %>% 
  mutate(across(.cols = 23, .fns = ~  lag(.x, n = 3), .names = "Third lag of {.col}"))  %>%  
  mutate(across(.cols = 24, .fns = ~  lag(.x, n = 1), .names = "First lag of {.col}")) %>%  # Surplus capital lags
  mutate(across(.cols = 24, .fns = ~  lag(.x, n = 2), .names = "Second lag of {.col}")) %>% 
  mutate(across(.cols = 24, .fns = ~  lag(.x, n = 3), .names = "Third lag of {.col}")) %>% 
  mutate(across(.cols = 79:81, .fns =  ~ .x - lag(.x), .names = "Change in {.col}")) %>%  # Change in capital surplus
  mutate(across(.cols = 17:22, .fns =  ~ .x - `Repo Rate`, .names = "Interest margin using {.col}")) %>%  # Interest margin
  mutate(across(.cols = 55:60, .fns =  ~ .x - `First lag of Repo Rate`, .names = "Interest margin using {.col}")) %>% 
  mutate(across(.cols = 61:66, .fns =  ~ .x - `Second lag of Repo Rate`, .names = "Interest margin using {.col}")) %>%
  mutate(across(.cols = 67:72, .fns =  ~ .x - `Third lag of Repo Rate`, .names = "Interest margin using {.col}"))  %>% 
  mutate(across(.cols = 85:108, .fns = ~ .x - lag(.x), .names = "Change in {.col}")) %>%  # Change in the interest margin
  mutate(across(.cols = 24, .fns = ~ .x - lag(.x), .names = "Change in {.col}"))

banks_master_trans_tbl %>% glimpse()
banks_master_trans_tbl %>% skim()

# Export ---------------------------------------------------------------
artifacts_preprocessing <- list (
  Totals = list(
    combined_gdp_ratio_data_tbl  = combined_gdp_ratio_data_tbl,
    combined_level_data_tbl = combined_level_data_tbl,
    combined_lending_tbl = combined_lending_tbl,
    capital_buffer_tbl = capital_buffer_tbl
  ),
  Banks  = list(
    combined_data_level_banks_tbl = combined_data_level_banks_tbl,
    combined_data_gdp_ratio_banks_tbl = combined_data_gdp_ratio_banks_tbl,
    combined_lending_banks_tbl = combined_lending_banks_tbl,
    capital_buffers_banks_tbl = capital_buffers_banks_tbl
  ),
  Macro = list(
    macro_tbl = macro_tbl
  ),
  Control = list(
    controls_tbl = controls_tbl
  ),
  masters = list(
    total_master_tbl = total_master_tbl,
    banks_master_tbl = banks_master_tbl,
    banks_master_trans_tbl = banks_master_trans_tbl
  )
)

write_rds(artifacts_preprocessing, file = here("Outputs", "artifacts_preprocessing_quartely.rds"))



