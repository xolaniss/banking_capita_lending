# Description

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
lending_rate_cleanup <- function(data, bank = "Total Banks"){
  data %>% 
    mutate(Description = str_c(Banks, " ", Description)) %>% 
    dplyr::select(-Banks, -Item, -`Outstanding balance at month`) %>% 
    rename(
      "Series" = "Description",
      "Value" = "Weighted average rate (%)") %>% 
    drop_na() %>% 
    filter(str_detect(Series, bank)) %>% 
    mutate(Series = str_to_sentence(Series)) %>% 
    mutate(Series = str_remove_all(Series, "\"")) %>% 
    mutate(Series = str_replace_all(Series, ":", "-")) %>% 
    mutate(Series = str_replace_all(Series, "- -", "-")) %>% 
    mutate(`Item Description` = str_replace_all(`Item Description`, "leasing transactions", "")) %>% 
    mutate(`Item Description` = str_replace_all(`Item Description`, "installment sale agreements", "")) %>% 
    mutate(`Item Description` = str_replace_all(`Item Description`, " mortgage advances", "")) %>% 
    mutate(`Item Description` = str_replace_all(`Item Description`, "corporate sector ", "corporate sector")) %>%
    mutate(`Item Description` = str_replace_all(`Item Description`, "household sector " , "household sector" )) %>% 
    mutate(`Item Description` = str_replace_all(`Item Description`, "domestic private sector " , "domestic private sector" )) %>% 
    mutate(`Item Description` = str_replace_all(`Item Description`, "Domestic private sector " , "domestic private sector" )) %>%
    mutate(`Series` = str_replace_all(`Series`, "-corporate sector", "")) %>% 
    mutate(`Series` = str_replace_all(`Series`, "-household sector", "")) %>% 
    mutate(`Series` = str_replace_all(`Series`, "-domestic private sector", "")) %>% 
    filter(!`Item Description` %in% c("Micro loans", "Interbank lending rate", "foreign sector" )) %>% 
    mutate(`Item Description` = str_to_sentence(`Item Description`))
}

# Import -------------------------------------------------------------
lending_rates <- read_rds(here("Outputs", "artifacts_lending_rates_v2.rds"))

# Combining-----------------------------------------------------------
total_lending_rate_tbl <- lending_rates$data$lending_rate_tbl %>% 
  lending_rate_cleanup(bank = "Total Banks") %>% 
  mutate(`Series` = str_replace_all(`Series`, "Total banks credit cards-" , "Total banks credit cards")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Total banks - fixed rate installment sale agreements" , "Total banks installment sale agreements- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Total banks - fixed rate leasing transactions" , "Total banks leasing transactions- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Total banks - fixed rate mortgage advances" , "Total banks mortgage advances- fixed rate" )) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Total banks " , "" )) %>% 
  mutate(Series = str_to_sentence(Series))
unique(total_lending_rate_tbl$`Item Description`)
unique(total_lending_rate_tbl$Series)

absa_lending_rate_tbl <- lending_rates$data$lending_rate_tbl %>% 
  lending_rate_cleanup(bank = "Absa Bank") %>% 
  mutate(`Series` = str_replace_all(`Series`, "Absa bank credit cards-" , "Absa bank credit cards")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Absa bank - fixed rate installment sale agreements" , "Absa bank installment sale agreements- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Absa bank - fixed rate leasing transactions" , "Absa bank leasing transactions- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Absa bank - fixed rate mortgage advances" , "Absa bank mortgage advances- fixed rate" )) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Absa bank " , "" )) %>% 
  mutate(Series = str_to_sentence(Series))
unique(absa_lending_rate_tbl$`Item Description`)
unique(absa_lending_rate_tbl$Series)

fnb_lending_rate_tbl <- lending_rates$data$lending_rate_tbl %>% 
  lending_rate_cleanup(bank = "FNB") %>% 
  mutate(`Series` = str_replace_all(`Series`, "Fnb credit cards-" , "Fnb credit cards")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Fnb - fixed rate installment sale agreements" , "Fnb installment sale agreements- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Fnb - fixed rate leasing transactions" , "Fnb leasing transactions- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Fnb - fixed rate mortgage advances" , "Fnb mortgage advances- fixed rate" )) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Fnb " , "" )) %>% 
  mutate(Series = str_to_sentence(Series))
unique(fnb_lending_rate_tbl$`Item Description`)
unique(absa_lending_rate_tbl$Series)

nedbank_lending_rate_tbl <- lending_rates$data$lending_rate_tbl %>% 
  lending_rate_cleanup(bank = "Nedbank") %>% 
  mutate(`Series` = str_replace_all(`Series`, "Nedbank credit cards-" , "Nedbank credit cards")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Nedbank - fixed rate installment sale agreements" , "Nedbank installment sale agreements- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Nedbank - fixed rate leasing transactions" , "Nedbank leasing transactions- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Nedbank - fixed rate mortgage advances" , "Nedbank mortgage advances- fixed rate" )) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Nedbank " , "" )) %>% 
  mutate(Series = str_to_sentence(Series))
unique(nedbank_lending_rate_tbl$`Item Description`)

standard_lending_rate_tbl <- lending_rates$data$lending_rate_tbl %>% 
  lending_rate_cleanup(bank = "Standard") %>% 
  mutate(`Series` = str_replace_all(`Series`, "Standard bank credit cards-" , "Standard bank credit cards")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Standard bank - fixed rate installment sale agreements" , "Standard bank installment sale agreements- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Standard bank - fixed rate leasing transactions" , "Standard bank leasing transactions- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Standard bank - fixed rate mortgage advances" , "Standard bank mortgage advances- fixed rate" )) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Standard bank " , "" )) %>% 
  mutate(Series = str_to_sentence(Series))
unique(standard_lending_rate_tbl$`Item Description`)

capitec_lending_rate_tbl <- lending_rates$data$lending_rate_tbl %>% 
  lending_rate_cleanup(bank = "Capitec") %>% 
  mutate(`Series` = str_replace_all(`Series`, "Capitec credit cards-" , "Capitec credit cards")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Capitec - fixed rate installment sale agreements" , "Capitec installment sale agreements- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Capitec - fixed rate leasing transactions" , "Capitec leasing transactions- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Capitec - fixed rate mortgage advances" , "Capitec mortgage advances- fixed rate" )) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Capitec " , "" )) %>% 
  mutate(Series = str_to_sentence(Series))
unique(capitec_lending_rate_tbl$`Item Description`)  


# Combined data -----------------------------------------------------------
combined_lending_tbl <- 
  list("TOTAL BANKS" = total_lending_rate_tbl,
      "ABSA BANK" = absa_lending_rate_tbl,
      "FIRSTRAND BANK" = fnb_lending_rate_tbl,
      "STANDARD BANK" = standard_lending_rate_tbl,
      "NEDBANK" = nedbank_lending_rate_tbl,
      "CAPITEC BANK" = capitec_lending_rate_tbl
       ) %>% 
  bind_rows(.id = "Bank") %>% 
  group_by(Bank, Series, `Item Description`) %>% 
  summarise_by_time(
    .date_var = Date,
    .by = "quarter",
    Value = mean(Value)
  ) %>% 
  ungroup() %>% 
  pivot_wider(names_from = Series, values_from = Value)
  

# Descriptives -----------------------------------------------------------
descriptives_tbl <- combined_lending_tbl  %>% 
  drop_na() %>% 
  pivot_longer(-c(Date, Bank, `Item Description`), names_to = "Variable", values_to = "Value") %>% 
  group_by(Variable, `Item Description`) %>% 
  summarise(across(.cols = -c(Date, Bank),
                   .fns = list(Median = median, 
                               SD = sd,
                               Min = min,
                               Max = max,
                               IQR = IQR,
                               Obs = ~ n()), 
                   .names = "{.fn}"))

descriptives_by_bank_tbl <- combined_lending_tbl %>% 
  drop_na() %>% 
  pivot_longer(-c(Date, Bank, `Item Description`), names_to = "Variable", values_to = "Value") %>% 
  group_by(Bank, Variable, `Item Description`) %>% 
  summarise(across(.cols = -c(Date),
                   .fns = list(Median = median, 
                               SD = sd,
                               Min = min,
                               Max = max,
                               IQR = IQR,
                               Obs = ~ n()), 
                   .names = "{.fn}"))



# Export ---------------------------------------------------------------
artifacts_combined_lending <- list (
  descriptives_tbl = descriptives_tbl,
  descriptives_by_bank_tbl = descriptives_by_bank_tbl,
  combined_lending_tbl = combined_lending_tbl
)

write_rds(artifacts_combined_lending , file = here("Outputs", "artifacts_combined_lending.rds"))


