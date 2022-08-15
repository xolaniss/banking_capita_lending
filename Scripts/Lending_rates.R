# Description
# Cleaning and importing files
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
# Import -------------------------------------------------------------
sheet_list = list(
  "Total Banks" = "Total Banks", 
  "Absa Bank"  = "ABSA",
  "FNB" = "First_Rand",
  "Nedbank" = "Nedbank",
  "Standard Bank" = "Standard_Bank",
  "Capitec" = "Capitec")

year <- seq(2008, 2022, by = 1)
path_list <- 
  year %>% 
  map(~ glue(
  here("Data", "4.1 BA930 Multiple Bank Export ({.}).xlsx")
))

lending_rate <- 
  path_list %>% 
  purrr::set_names(year) %>% 
  map(~excel_import_sheet(
    path = .,
    sheet_list = sheet_list,
    skip = 5,
    col_types = c("text", "text", "numeric", "numeric", "numeric", "numeric", "numeric") 
  )) 

# Cleaning -----------------------------------------------------------------
lending_rate_no_names <- 
  lending_rate %>%
  map(~bind_rows(., .id = "Banks")) %>% 
  map(~dplyr::select(., 1:6)) 
names <-   c(
  "Banks"     
  ,"Description"                            
  ,"Date"          
  ,"Item" 
  ,"Outstanding balance at month" 
  ,"Weighted average rate (%)"
)

colnames(lending_rate_no_names$`2008`) <- names
colnames(lending_rate_no_names$`2009`) <- names
colnames(lending_rate_no_names$`2010`) <- names
colnames(lending_rate_no_names$`2011`) <- names
colnames(lending_rate_no_names$`2012`) <- names
colnames(lending_rate_no_names$`2013`) <- names
colnames(lending_rate_no_names$`2014`) <- names
colnames(lending_rate_no_names$`2015`) <- names
colnames(lending_rate_no_names$`2016`) <- names
colnames(lending_rate_no_names$`2017`) <- names
colnames(lending_rate_no_names$`2018`) <- names
colnames(lending_rate_no_names$`2019`) <- names
colnames(lending_rate_no_names$`2020`) <- names
colnames(lending_rate_no_names$`2021`) <- names
colnames(lending_rate_no_names$`2022`) <- names

lending_rate_tbl <- 
  lending_rate_no_names %>% 
  map(~separate(., Date, into = c("Month", "Year"), sep =  " ")) %>% 
  map(~relocate(., Year,.before = Banks)) %>% 
  map(~relocate(., Month,.before = Year)) %>% 
  bind_rows() %>% 
  filter(!Month == "LENDING") %>% 
  filter(!is.na(Month)) %>% 
  mutate(Date = str_c(Month,"-", Year)) %>% 
  relocate(., Date,.before = Month) %>% 
  mutate(Date = parse_date_time(Date, "b-Y")) %>% 
  mutate(Description = na.locf(Description)) %>% 
  mutate(Description = str_c(Description, "-", Month, "-", Year)) 


# Transformations --------------------------------------------------------


# Graphing ---------------------------------------------------------------


# Export ---------------------------------------------------------------
artifacts_lending_rates <- list (
  data = list(
    lending_rate_tbl = lending_rate_tbl
  )
)

write_rds(artifacts_lending_rates, file = here("Outputs", "artifacts_lending_rates.rds"))


