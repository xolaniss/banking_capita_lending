# Description

# Preliminaries -----------------------------------------------------------
library(tidyverse)
library(readr)
library(readxl)
library(here)
library(lubridate)
library(xts)
library(tseries)
library(broom)
library(glue)
library(vars)
library(PNWColors)
library(patchwork)
library(psych)
library(kableExtra)
library(strucchange)
library(timetk)
library(purrr)
library(pins)
library(fDMA)
library(uniqtag)
library(scales)
library(urca)
library(mFilter)

# Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))
source(here("Functions", "Sheets_import.R"))
source(here("Functions", "excel_import_sheet.R"))

path = here("Data", "4.1 BA930 Multiple Bank Export (2022).xlsx")
sheet_list = list(
  "Total Banks" = "Total Banks", 
  "Absa Bank"  = "ABSA",
  "FNB" = "First_Rand",
  "Nedbank" = "Nedbank",
  "Standard Bank" = "Standard_Bank",
  "Capitec" = "Capitec")
col_types = c("text", rep(x = "numeric", 148))

 

# Import -------------------------------------------------------------
lending_rate <- 
  excel_import_sheet(
    path = path,
    sheet_list = sheet_list,
    skip = 5
    # col_types = col_types 
  )


# Cleaning -----------------------------------------------------------------


# Transformations --------------------------------------------------------


# Graphing ---------------------------------------------------------------


# Export ---------------------------------------------------------------
artifacts_ <- list (

)

write_rds(artifacts_, file = here("Outputs", "artifacts_.rds"))


