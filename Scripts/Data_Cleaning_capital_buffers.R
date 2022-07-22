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


# Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))

# Import ------------------------------------------------------------------
capital_buffers <- read_excel(here("Data", "capital_buffers.xlsx"), skip = 3 )


# Cleaning ----------------------------------------------------------
capital_buffers_tbl <- 
  capital_buffers %>% 
  relocate(...3, .before = ...1) %>% 
  rename("Bank" = ...1, 
         "Date" = ...3,
         `Aggregate amount of qualifying capital and reserve funds` =
           `Aggregate amount of qualifying capital and reserve funds...9`) %>% 
  fill(Bank, .direction = "down") %>% 
  dplyr::select(-...2, -...4) %>% 
  mutate(Date = parse_date_time(Date, orders = "bY")) %>% 
  dplyr::select(Date, Bank, `Minimum required capital and reserve funds`, 
                `Aggregate amount of qualifying capital and reserve funds`,
                `Surplus capital`)

# Graphing ----------------------------------------------------------------
bank_names <- list(unique(capital_buffers_tbl$Bank))

bank_capital_buffer_gg <- function(data, variables_color = 3, ...) {
 ggplot <-  data %>% 
    pivot_longer(cols = -(1:2), values_to = "Value", names_to = "Series") %>% 
    filter(Bank %in% ...) %>% 
    unite("Series", Bank:Series, sep = ": ") %>% 
    fx_nopivot_plot(variables_color = variables_color, scale = "free") +
    scale_y_continuous(labels = scales::label_percent())
 ggplot
}

big_banks <- c("ABSA BANK LTD", 
               "CAPITEC BANK", 
               "DISCOVERY BANK LIMITED" ,
               "FIRSTRAND BANK LIMITED",
               "INVESTEC BANK LTD",
               "NEDBANK LTD" ,
               "THE STANDARD BANK OF S A LTD" )

bank_capital_buffer_gg(capital_buffers_tbl, variables_color = 21,
                  big_banks)

# Export ------------------------------------------------------------------
artifacts_capital_buffers <- 
  list(
    Data = list(capital_buffers_tbl)
  ) %>% write_rds(file = here("Outputs", "artifacts_capital_buffers.rds"))
