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
library(janitor)

# graphs
library(PNWColors)
library(patchwork)

# eda
library(psych)
library(DataExplorer)
library(skimr)
library(datawizard)

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
combined_data <- read_rds(here("Outputs", "artifacts_combined_totals_data_monthly.rds"))
combined_level_data_tbl <- combined_data$ba900_monthly_tbl 

# 1.2. Lending Rate ------------------------------------------------------
combined_lending <- read_rds(here("Outputs", "artifacts_combined_lending_monthly.rds"))
combined_lending_tbl <- combined_lending$combined_lending_tbl %>% 
  filter(Bank == "TOTAL BANKS") %>% 
  dplyr::select(-Bank) %>% 
  pivot_wider(names_from = Series, values_from = Value)

# 1.3 Capital buffers -------------------------------------------------------------------
capital_buffers <- read_rds(here("Outputs", "artifacts_general.rds"))
capital_buffer_tbl <- 
    capital_buffers$data$car_tbl %>% 
    dplyr::select(Date, `Minimum requirement`, `Surplus capital`)
    
#  2 Banks ----------------------------------------------------------------

# 2.1.  Asset data ------------------------------------------------------
combined_banks_data <- read_rds(here("Outputs", "artifacts_combined_banks_monthly.rds"))
combined_data_level_banks_tbl <- combined_banks_data$ba900_monthly_levels_tbl

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
  relocate(Date, .before = Bank) %>% 
  pivot_wider(names_from = Series, values_from = Value)

# 3 Macro  ------------------------------------------------
repo_rate_tbl <- read_excel(here("Data", "Repo.xlsx")) %>% 
  mutate(Date = seq(as.Date("2008-01-01"), as.Date("2021-02-01"), by = "month"))


# 4. Controls ------------------------------------------------------------
controls <- read_rds(here("Outputs", "artifacts_controls.rds"))
controls_tbl <- 
  controls$controls_tbl %>% 
  relocate(Date, .before = "Bank") %>% 
  pivot_wider(values_from = Value, names_from = Series)

# 5. Master tibble -----------------------------------------------------------
total_master_tbl <- 
  combined_level_data_tbl %>% 
  left_join(., combined_lending_tbl, by = c("Date" = "Date")) %>% 
  left_join(., capital_buffer_tbl, by = c("Date" = "Date")) %>% 
  left_join(., repo_rate_tbl, by = c("Date" = "Date"))

total_master_tbl %>% glimpse()

banks_master_tbl <- combined_data_level_banks_tbl %>% 
  left_join(., combined_lending_banks_tbl, by = c("Date" = "Date", "Bank" = "Bank")) %>% 
  left_join(., capital_buffers_banks_tbl, by = c("Date" = "Date", "Bank" = "Bank")) %>% 
  left_join(., controls_tbl, by = c("Date" = "Date", "Bank" = "Bank")) %>%
  left_join(., repo_rate_tbl, by = c("Date" = "Date")) %>% 
  filter(!Bank == "CAPITEC BANK") ## Dropping Capitec bank from the master bank sample

banks_master_tbl %>% group_by(Bank) %>% skim()

banks_master_tbl %>% 
  pivot_longer(-c(Date, Bank)) %>% 
  ggplot(aes(x = Date, group = Bank, y = value, col = Bank)) +
  geom_line() +
  facet_wrap( ~ name, ncol = 4, scale = "free") +
  theme(legend.position = "top")


# 6. Modelling transformations -----------------------------------------------
banks_master_trans_tbl <- 
  banks_master_tbl %>% 
  mutate(across(.cols = 3:9, .fns = ~ log(.x), .names = "Log of {.col}")) %>%     # logging loans
  mutate(across(.cols = 29:35, .fns = ~ .x - lag(.x, n = 1), .names = "Change in {.col}")) %>%    # change in logs loans
  mutate(across(.cols = 10:15, .fns = ~  lag(.x), .names = "First lag of {.col}")) %>%   # lending lags
  mutate(across(.cols = 10:15, .fns = ~  lag(.x, n = 2), .names = "Second lag of {.col}")) %>% 
  mutate(across(.cols = 10:15, .fns = ~  lag(.x, n = 3), .names = "Third lag of {.col}")) %>% 
  mutate(across(.cols = 10:15, .fns = ~  .x - lag(.x), .names = "Change using the first lag of {.col}")) %>%   # lending lags
  mutate(across(.cols = 10:15, .fns = ~  .x - lag(.x, n = 2), .names = "Change using the second lag of {.col}")) %>% 
  mutate(across(.cols = 10:15, .fns = ~  .x - lag(.x, n = 3), .names = "Change using the third lag of {.col}")) %>% 
  mutate(across(.cols = 28, .fns = ~  lag(.x, n = 1), .names = "First lag of {.col}")) %>%   # Repo lags
  mutate(across(.cols = 28, .fns = ~  lag(.x, n = 2), .names = "Second lag of {.col}")) %>% 
  mutate(across(.cols = 28, .fns = ~  lag(.x, n = 3), .names = "Third lag of {.col}")) %>% 
  mutate(across(.cols = 16, .fns = ~ .x - lag(.x), .names = "Change using first lag of {.col}")) %>%  # Minimum capital lags
  mutate(across(.cols = 16, .fns = ~ .x - lag(.x, n = 2), .names = "Change using the second lag of {.col}")) %>% 
  mutate(across(.cols = 16, .fns = ~ .x - lag(.x, n = 3), .names = "Change using the third lag of {.col}")) %>% 
  mutate(across(.cols = 17, .fns = ~  lag(.x), .names = "First lag of {.col}")) %>%  # Surplus capital lags
  mutate(across(.cols = 17, .fns = ~  lag(.x, n = 2), .names = "Second lag of {.col}")) %>% 
  mutate(across(.cols = 17, .fns = ~  lag(.x, n = 3), .names = "Third lag of {.col}")) %>% 
  mutate(across(.cols = 85:87, .fns =  ~ .x - lag(.x), .names = "Change in {.col}")) %>%     # Change in capital surplus
  mutate(across(.cols = 88:90, .fns = ~ .x^2, .names = "Squared {.col}")) %>%  # Squared change in lagged capital surplus
  mutate(across(.cols = 10:15, .fns =  ~ .x - `Repo rate`, .names = "Interest margin using {.col}"))  %>%    # Interest margin
  mutate(across(.cols = 43:48, .fns =  ~ .x - `First lag of Repo rate`, .names = "Interest margin using {.col}")) %>% 
  mutate(across(.cols = 49:54, .fns =  ~ .x - `Second lag of Repo rate`, .names = "Interest margin using {.col}")) %>% 
  mutate(across(.cols = 55:60, .fns =  ~ .x - `Third lag of Repo rate`, .names = "Interest margin using {.col}")) %>% 
  mutate(across(.cols = 93:117, .fns = ~ .x - lag(.x), .names = "Change in {.col}")) %>%   # Change in the interest margin
  mutate(across(.cols = 17, .fns = ~ .x - lag(.x), .names = "Change in {.col}"))      # Change in capital surplus

banks_master_trans_tbl %>% glimpse()



# Outliers ----------------------------------------------------------------
banks_master_trans_tbl <- 
banks_master_trans_tbl %>% 
  mutate(across(matches("Change in Log"), .fns = ~ winsorize(.x, threshold = .01 ))) %>% 
  mutate(across(contains("Surplus capital"), .fns = ~ winsorize(.x, threshold = .01 )))

# Minimum capital dummy ---------------------------------------------------
banks_master_trans_tbl <- 
banks_master_trans_tbl %>% 
 mutate(Change_in_min_cap = c(NA, diff(`Minimum required capital and reserve funds`))) %>% 
 mutate(Minimum_cap_dummy = case_when(
   Change_in_min_cap > 0 ~ 1,
   Change_in_min_cap <= 0 ~ 0,
 )) %>% 
  glimpse()
  

# Model variable graphs ---------------------------------------------------
Surplus_gg <-   
  banks_master_trans_tbl %>% 
  dplyr::select(Date, Bank, matches("Surplus")) %>% 
  pivot_longer(-c(Date, Bank)) %>% 
  ggplot(aes(x = Date, group = Bank, y = value, col = Bank)) +
  geom_line() +
  facet_wrap( ~ name, ncol = 4, scale = "free") +
  theme(legend.position = "top", text = element_text(size = 6))

loans_gg <-   
  banks_master_trans_tbl %>% 
  dplyr::select(Date, Bank, matches("Change in Log")) %>% 
  pivot_longer(-c(Date, Bank)) %>% 
  ggplot(aes(x = Date, group = Bank, y = value, col = Bank)) +
  geom_line() +
  facet_wrap( ~ name, ncol = 4, scale = "free") +
  theme(legend.position = "top", text = element_text(size = 6))

Minimum_gg <-   
  banks_master_trans_tbl %>% 
  dplyr::select(Date, Bank, matches("Minimum")) %>% 
  pivot_longer(-c(Date, Bank)) %>% 
  ggplot(aes(x = Date, group = Bank, y = value, col = Bank)) +
  geom_line() +
  facet_wrap( ~ name, ncol = 4, scale = "free") +
  theme(legend.position = "top", text = element_text(size = 6))


Interest_margin_gg <-   
  banks_master_trans_tbl %>% 
  dplyr::select(Date, Bank, matches("Change in Interest margin")) %>% 
  pivot_longer(-c(Date, Bank)) %>% 
  ggplot(aes(x = Date, group = Bank, y = value, col = Bank)) +
  geom_line() +
  facet_wrap( ~ name, ncol = 4, scale = "free") +
  theme(legend.position = "top", text = element_text(size = 6))

banks_master_trans_tbl %>% glimpse()

# Export ---------------------------------------------------------------
artifacts_preprocessing <- list (
  Totals = list(
    combined_level_data_tbl = combined_level_data_tbl,
    combined_lending_tbl = combined_lending_tbl,
    capital_buffer_tbl = capital_buffer_tbl
  ),
  Banks  = list(
    combined_data_level_banks_tbl = combined_data_level_banks_tbl,
    combined_lending_banks_tbl = combined_lending_banks_tbl,
    capital_buffers_banks_tbl = capital_buffers_banks_tbl
 ),
  Macro = list(
    repo_rate_tbl = repo_rate_tbl
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

write_rds(artifacts_preprocessing, file = here("Outputs", "artifacts_preprocessing_monthly.rds"))



