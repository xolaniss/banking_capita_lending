# Description
# Preprocessing for panel models by Xolani Sibande October 18

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

#  1.1 Banks ----------------------------------------------------------------
combined_banks_data <- read_rds(here("Outputs", "artifacts_combined_banks.rds"))
combined_data_banks_tbl <- combined_banks_data$combined_5_banks_tbl
combined_data_gdp_ratio_tbl <- combined_data$ba900_gdp_ratio_combined_tbl
combined_lending <- read_rds(here("Outputs", "artifacts_combined_lending.rds"))
combined_lending_tbl <- combined_lending$combined_lending_tbl 

#  1.2 Total and general ----------------------------------------------------------------
combined_data <- read_rds(here("Outputs", "artifacts_combined_data.rds"))
combined_gdp_ratio_data <- combined_data$ba900_gdp_ratio_combined_tbl
combined_level_data <- combined_data$ba900_levels_combined_tbl

# Export ---------------------------------------------------------------
artifacts_preprocessing <- list (

)

write_rds(artifacts_preprocessing, file = here("Outputs", "artifacts_preprocessing.rds"))



