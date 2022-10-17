# Description
# Modeling for bank capital by Xolani Sibande 26 September 2022

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
ba900 <- read_rds(here("Outputs", "artifacts_ba900.rds"))
balance_sheet_gdp <- read_rds(here("Outputs", "artifacts_balance_sheet_gdp.rds"))
lending_rates <- read_rds(here("Outputs", "artifacts_lending_rates_v2.rds"))
capital_buffers <- read_rds(here("Outputs", "artifacts_capital_buffers.rds"))
general <- read_rds(here("Outputs", "artifacts_general.rds"))

# Combining data  ---------------------------------------------------------



# Descriptives -----------------------------------------------------------------


# Models --------------------------------------------------------


# # v1 --------------------------------------------------------------------


# # v2 --------------------------------------------------------------------


# # v3 --------------------------------------------------------------------



# # v4 --------------------------------------------------------------------


# # v5 --------------------------------------------------------------------


# Graphing ---------------------------------------------------------------


# Export ---------------------------------------------------------------
artifacts_models <- list (

)

write_rds(artifacts_models, file = here("Outputs", "artifacts_models.rds"))


