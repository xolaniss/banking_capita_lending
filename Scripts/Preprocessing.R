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
library(fDMA)
library(vars)
library(urca)
library(mFilter)
library(car)

# 0.0 Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))

# 1.0 Import -------------------------------------------------------------

#  1.1 Total  ----------------------------------------------------------------
combined_data <- read_rds(here("Outputs", "artifacts_combined_data.rds"))
combined_gdp_ratio_data_tbl <- combined_data$ba900_gdp_ratio_combined_tbl %>% 
  dplyr::select(-`Real GDP`)
combined_level_data_tbl <- combined_data$ba900_levels_combined_tbl %>% 
  dplyr::select(-`Real GDP`)
combined_lending <- read_rds(here("Outputs", "artifacts_combined_lending.rds"))
combined_lending_tbl <- combined_lending$combined_lending_tbl %>% 
  filter(Bank == "TOTAL BANKS")

#  1.2 Banks ----------------------------------------------------------------

# 1.2.1.  Asset data ------------------------------------------------------
combined_banks_data <- read_rds(here("Outputs", "artifacts_combined_banks.rds"))
combined_data_level_banks_tbl <- combined_banks_data$combined_5_banks_tbl
combined_data_gdp_ratio_banks_tbl <- combined_data$ba900_gdp_ratio_combined_tbl

# 1.2.2 Lending Rates -----------------------------------------------------
combined_lending_banks_tbl <- combined_lending$combined_lending_tbl %>% 
  filter(!Bank == "TOTAL BANKS")  ## waiting for Alister to advice on consolidatoin the data to align with the asset data

# 1.3 Macro  ------------------------------------------------
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

# 1.4 Controls ------------------------------------------------------------

## To get to the PA -- called on 31 October 2022


# 2.0 Modelling transformations -----------------------------------------------



# Export ---------------------------------------------------------------
artifacts_preprocessing <- list (
  Totals = list(
    combined_gdp_ratio_data_tbl  = combined_gdp_ratio_data_tbl,
    combined_level_data_tbl = combined_level_data_tbl,
    combined_lending_tbl = combined_lending_tbl
  ),
  Banks  = list(
    combined_data_level_banks_tbl = combined_data_level_banks_tbl,
    combined_data_gdp_ratio_banks_tbl = combined_data_gdp_ratio_banks_tbl,
    combined_lending_banks_tbl = combined_lending_banks_tbl
  ),
  Macro = list(
    macro_tbl = macro_tbl
  ),
  Control = list(
    
  )
)

write_rds(artifacts_preprocessing, file = here("Outputs", "artifacts_preprocessing.rds"))



