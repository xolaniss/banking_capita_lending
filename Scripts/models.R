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
preprocessed_data <- read_rds(here("Outputs", "artifacts_preprocessing.rds"))

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


