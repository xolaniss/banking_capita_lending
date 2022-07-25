# Packages ----------------------------------------------------------------
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
library(openxlsx)


# Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))
source(here("Functions", "Sheets_import.R"))
source(here("Functions", "excel_import_sheet.R"))

# Import ------------------------------------------------------------------
path = here("Data", "BA900_Line_items_103_to_277.xlsx")
sheet_list = list(
  "Total Banks" = "Sheet1", 
  "Absa Bank"  = "Sheet2",
  "FNB" = "Sheet3",
  "Nedbank" = "Sheet5",
  "Standard Bank" = "Sheet6",
  "Capitec" = "Sheet12")
col_types = c("text", rep(x = "numeric", 148))

ba900_assets <- 
  excel_import_sheet(
  path = path,
  sheet_list = sheet_list,
  skip = 5,
  col_types = col_types 
    )

# Cleaning ----------------------------------------------------------

total_tbl <- ba900_assets$`Total Banks`  %>% as_tibble() %>% drop_na()
Absa_tbl <- ba900_assets$`Absa Bank`  %>%  as_tibble() %>% drop_na()
fnb <- ba900_assets$FNB %>% as_tibble() %>% drop_na()
nedbank <- ba900_assets$Nedbank %>% as_tibble() %>% drop_na()
standard <-  ba900_assets$`Standard Bank` %>% as_tibble() %>% drop_na()
capitec <- ba900_assets$Capitec %>% as_tibble() %>% drop_na()

# Transformations ---------------------------------------------------------
months <- seq(as.Date("2007-12-01"), as.Date("2020-04-01"), by = "month")
colnames(total_tbl) <- months 




# Graphing ----------------------------------------------------------------




# Export ------------------------------------------------------------------

