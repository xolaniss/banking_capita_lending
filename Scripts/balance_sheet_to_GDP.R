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

# Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))
source(here("Functions", "balance_sheet_rename_gg.R"))

combine_gdp <- function(data){
  combined_tbl <- 
    data %>% 
    pivot_wider(names_from = Series, values_from = Value) %>% 
    left_join(nominal_GDP, by = c("Date" = "Date")) %>% 
    drop_na() %>% 
    mutate(across(-Date, .fns = ~ . / `Nominal GDP  (SAA)`)) %>% 
    dplyr::select(-`Nominal GDP  (SAA)`) %>% 
    rename(
      "Household sector secured credit / GDP" = "Household sector secured credit",
      "Household sector unsecured credit / GDP"  = "Household sector unsecured credit" ,
      "Households residential mortgages / GDP" = "Households residential mortgages" ,
      "Other assets / GDP" = "Other assets",
      "Non-financial corporate sector mortgages / GDP"= "Non-financial corporate sector mortgages",
      "Non-financial corporate secured credit / GDP" = "Non-financial corporate secured credit",
      "Non-financial corporate unsecured credit / GDP" = "Non-financial corporate unsecured credit"
    ) %>% 
    pivot_longer(-Date, values_to = "Value", names_to = "Series")
}
 
balance_sheet_gdp_gg <- function(data){
  data %>% 
    fx_nopivot_plot(ncol = 2) +
    scale_y_continuous(labels = scales::label_percent())
} 

# Import -------------------------------------------------------------
balance_sheet_quartely <- read_rds(here("Outputs", "artifacts_balance_sheet_quartely.rds"))
nominal_GDP <- read_excel(here("Data", "GDP.xlsx")) %>% 
  mutate(`Nominal GDP  (SAA)` = `Nominal GDP  (SAA)` * 1000000) %>% 
  mutate(Date = Date %+time% "1 day")

total_tbl <- balance_sheet_quartely$quarterly_data$Totals_quarter_tbl
fnb_tbl <- balance_sheet_quartely$quarterly_data$fnb_quarter_tbl
absa_tbl <- balance_sheet_quartely$quarterly_data$absa_quarter_tbl
standard_tbl <- balance_sheet_quartely$quarterly_data$standard_quarter_tbl
nedbank_tbl <- balance_sheet_quartely$quarterly_data$nedbank_quarter_tbl
capitec_tbl <- balance_sheet_quartely$quarterly_data$capitec_quarter_tbl

# Transformations --------------------------------------------------------
total_gdp_tbl <- total_tbl %>% combine_gdp() 
fnb_gdp_tbl <- fnb_tbl %>% combine_gdp() 
absa_gdp_tbl <- absa_tbl %>% combine_gdp() 
standard_gdp_tbl <- standard_tbl %>% combine_gdp() 
nedbank_gdp_tbl <- nedbank_tbl %>% combine_gdp()
capitec_gdp_tbl <- capitec_tbl %>% combine_gdp() 


# Graphing ---------------------------------------------------------------
nominal_GDP_gg <- 
  nominal_GDP %>% fx_plot(variables_color = 1) +
  scale_y_continuous(labels = 
                       scales::label_dollar(prefix = "R", scale_cut = cut_short_scale()))
total_gdp_gg <-  total_gdp_tbl%>% balance_sheet_gdp_gg() 
fnb_gdp_gg <-  fnb_gdp_tbl %>% balance_sheet_gdp_gg() 
absa_gdp_gg <-  absa_gdp_tbl %>% balance_sheet_gdp_gg() 
standard_gdp_gg <-  standard_gdp_tbl %>% balance_sheet_gdp_gg() 
nedbank_gdp_gg <-  nedbank_gdp_tbl %>% balance_sheet_gdp_gg()
capitec_gdp_gg <-  capitec_gdp_tbl %>% balance_sheet_gdp_gg()

# Export ---------------------------------------------------------------
artifacts_balance_sheet_gdp <- list (
  data = list(
    total_gdp_tbl = total_gdp_tbl,
    fnb_gdp_tbl = fnb_gdp_tbl,
    absa_gdp_tbl = absa_gdp_tbl,
    standard_gdp_tbl = standard_gdp_tbl,
    nedbank_gdp_tbl = nedbank_gdp_tbl,
    capitec_gdp_tbl = capitec_gdp_tbl
  ),
  graphs = list(
    nominal_GDP_gg = nominal_GDP_gg,
    total_gdp_gg = total_gdp_gg,
    fnb_gdp_gg = fnb_gdp_gg ,
    absa_gdp_gg = absa_gdp_gg ,
    standard_gdp_gg = standard_gdp_gg,
    nedbank_gdp_gg = nedbank_gdp_gg,
    capitec_gdp_gg = capitec_gdp_gg
  )
  

)
write_rds(artifacts_balance_sheet_gdp, file = here("Outputs", "artifacts_balance_sheet_gdp.rds"))


