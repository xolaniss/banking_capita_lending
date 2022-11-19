# Description
# Aggregation of lending rates by Xolani Sibande 8 November 2022
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

balance_rate_cleanup <- function(data, bank = "Total Banks"){
  data %>% 
    mutate(Description = str_c(Banks, " ", Description)) %>% 
    dplyr::select(-Banks) %>% 
    rename(
      "Series" = "Description",
      "Value" = "Weighted average rate (%)") %>% 
    # drop_na() %>% 
    filter(str_detect(Series, bank)) %>% 
    dplyr::select(-Value) %>% 
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
    mutate(`Item Description` = str_to_sentence(`Item Description`)) %>% 
    pivot_wider(names_from = c(Series, `Item Description`, Item) , values_from = `Outstanding balance at month`) %>% 
    dplyr::select(-contains("fixed rate")) %>% 
    dplyr::select(-contains("Domestic")) %>% 
    dplyr::select(-contains("Hash")) %>% 
    dplyr::select(-contains("Other"))
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
  mutate(Series = str_to_sentence(Series)) %>% 
  pivot_wider(names_from = c(Series, `Item Description`) , values_from = Value) %>% 
  dplyr::select(-contains("fixed rate")) %>% 
  dplyr::select(-contains("Domestic")) %>% 
  dplyr::select(-contains("Hash")) %>% 
  dplyr::select(-contains("Other"))


absa_lending_rate_tbl <- lending_rates$data$lending_rate_tbl %>% 
  lending_rate_cleanup(bank = "Absa Bank") %>% 
  mutate(`Series` = str_replace_all(`Series`, "Absa bank credit cards-" , "Absa bank credit cards")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Absa bank - fixed rate installment sale agreements" , "Absa bank installment sale agreements- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Absa bank - fixed rate leasing transactions" , "Absa bank leasing transactions- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Absa bank - fixed rate mortgage advances" , "Absa bank mortgage advances- fixed rate" )) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Absa bank " , "" )) %>% 
  mutate(Series = str_to_sentence(Series)) %>% 
  pivot_wider(names_from = c(Series, `Item Description`) , values_from = Value) %>% 
  dplyr::select(-contains("fixed rate")) %>% 
  dplyr::select(-contains("Domestic")) %>% 
  dplyr::select(-contains("Hash")) %>% 
  dplyr::select(-contains("Other"))


fnb_lending_rate_tbl <- lending_rates$data$lending_rate_tbl %>% 
  lending_rate_cleanup(bank = "FNB") %>% 
  mutate(`Series` = str_replace_all(`Series`, "Fnb credit cards-" , "Fnb credit cards")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Fnb - fixed rate installment sale agreements" , "Fnb installment sale agreements- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Fnb - fixed rate leasing transactions" , "Fnb leasing transactions- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Fnb - fixed rate mortgage advances" , "Fnb mortgage advances- fixed rate" )) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Fnb " , "" )) %>% 
  mutate(Series = str_to_sentence(Series)) %>% 
  pivot_wider(names_from = c(Series, `Item Description`) , values_from = Value) %>% 
  dplyr::select(-contains("fixed rate")) %>% 
  dplyr::select(-contains("Domestic")) %>% 
  dplyr::select(-contains("Hash")) %>% 
  dplyr::select(-contains("Other"))

nedbank_lending_rate_tbl <- lending_rates$data$lending_rate_tbl %>% 
  lending_rate_cleanup(bank = "Nedbank") %>% 
  mutate(`Series` = str_replace_all(`Series`, "Nedbank credit cards-" , "Nedbank credit cards")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Nedbank - fixed rate installment sale agreements" , "Nedbank installment sale agreements- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Nedbank - fixed rate leasing transactions" , "Nedbank leasing transactions- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Nedbank - fixed rate mortgage advances" , "Nedbank mortgage advances- fixed rate" )) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Nedbank " , "" )) %>% 
  mutate(Series = str_to_sentence(Series)) %>% 
  pivot_wider(names_from = c(Series, `Item Description`) , values_from = Value) %>% 
  dplyr::select(-contains("fixed rate")) %>% 
  dplyr::select(-contains("Domestic")) %>% 
  dplyr::select(-contains("Hash")) %>% 
  dplyr::select(-contains("Other"))
  
standard_lending_rate_tbl <- lending_rates$data$lending_rate_tbl %>% 
  lending_rate_cleanup(bank = "Standard") %>% 
  mutate(`Series` = str_replace_all(`Series`, "Standard bank credit cards-" , "Standard bank credit cards")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Standard bank - fixed rate installment sale agreements" , "Standard bank installment sale agreements- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Standard bank - fixed rate leasing transactions" , "Standard bank leasing transactions- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Standard bank - fixed rate mortgage advances" , "Standard bank mortgage advances- fixed rate" )) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Standard bank " , "" )) %>% 
  mutate(Series = str_to_sentence(Series)) %>% 
  pivot_wider(names_from = c(Series, `Item Description`) , values_from = Value) %>% 
  dplyr::select(-contains("fixed rate")) %>% 
  dplyr::select(-contains("Domestic")) %>% 
  dplyr::select(-contains("Hash")) %>% 
  dplyr::select(-contains("Other"))

capitec_lending_rate_tbl <- lending_rates$data$lending_rate_tbl %>% 
  lending_rate_cleanup(bank = "Capitec") %>% 
  mutate(`Series` = str_replace_all(`Series`, "Capitec credit cards-" , "Capitec credit cards")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Capitec - fixed rate installment sale agreements" , "Capitec installment sale agreements- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Capitec - fixed rate leasing transactions" , "Capitec leasing transactions- fixed rate")) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Capitec - fixed rate mortgage advances" , "Capitec mortgage advances- fixed rate" )) %>% 
  mutate(`Series` = str_replace_all(`Series`, "Capitec " , "" )) %>% 
  mutate(Series = str_to_sentence(Series)) %>% 
  pivot_wider(names_from = c(Series, `Item Description`) , values_from = Value) %>% 
  dplyr::select(-contains("fixed rate")) %>% 
  dplyr::select(-contains("Domestic")) %>% 
  dplyr::select(-contains("Hash")) %>% 
  dplyr::select(-contains("Other"))

# Weights calculation -----------------------------------------------------

weights <-
  function(data,
           name_1,
           name_2,
           name_3,
           name_4,
           name_5,
           name_6,
           name_7,
           name_8,
           credit_1,
           credit_2,
           credit_3,
           credit_4,
           credit_5,
           credit_6,
           credit_7,
           credit_8,
           total_1,
           total_2) {
    data %>%
      mutate({
        {
          name_1
        }
      } :=  {
        {
          credit_1
        }
      } /  {{ total_1 }}) %>%
      mutate({
        {
          name_2
        }
      } :=  {
        {
          credit_2
        }
      } /  {{ total_1 }}) %>%
      mutate({
        {
          name_3
        }
      } :=  {
        {
          credit_3
        }
      } /  {{ total_1 }}) %>%
      mutate({
        {
          name_4
        }
      } :=  {
        {
          credit_4
        }
      } /  {{ total_1 }}) %>%
      mutate({
        {
          name_5
        }
      } :=  {
        {
          credit_5
        }
      } /  {{ total_2 }}) %>%
      mutate({
        {
          name_6
        }
      } :=  {
        {
          credit_6
        }
      } /  {{ total_2 }}) %>%
      mutate({
        {
          name_7
        }
      } :=  {
        {
          credit_7
        }
      } /  {{ total_2 }}) %>%
      mutate({
        {
          name_8
        }
      } :=  {
        {
          credit_8
        }
      } /  {{ total_2 }}) %>%
      dplyr::select(Date,
                    {
                      {
                        name_1
                      }
                    },
                    {
                      {
                        name_2
                      }
                    },
                    {
                      {
                        name_3
                      }
                    },
                    {
                      {
                        name_4
                      }
                    },
                    {
                      {
                        name_5
                      }
                    },
                    {
                      {
                        name_6
                      }
                    },
                    {
                      {
                        name_7
                      }
                    },
                    {
                      {
                        name_8
                      }
                    })
  }



total_banks_weights_tbl <- 
  lending_rates$data$lending_rate_tbl %>% balance_rate_cleanup() %>% 
  weights(
    name_1 = "corporate_overdraft_weights",
    name_2 = "corporate_credit_weights",
    name_3 = "corporate_installment_weights",
    name_4 = "corporate_leasing_weights",
    name_5 = "households_overdraft_weights",
    name_6 = "households_credit_weights",
    name_7 = "households_installment_weights",
    name_8 = "households_leasing_weights",
    credit_1 = `Total banks overdrafts_Corporate sector_48`,
    credit_2  = `Total banks credit cards-_Corporate sector_55`,
    credit_3 = `Total banks instalment sale agreements- flexible rate_Corporate sector_49`,
    credit_4 = `Total banks leasing transactions- flexible rate_Corporate sector_51`,
    credit_5 = `Total banks overdrafts_Household sector_58`,
    credit_6  = `Total banks credit cards_Household sector_65`,
    credit_7 = `Total banks instalment sale agreements- flexible rate_Household sector_59`,
    credit_8 = `Total banks leasing transactions- flexible rate_Household sector_61`,
    total_1 = `Total banks corporate sector 3 (total of items 48-56)_Corporate sector_47`,
    total_2 = `Total banks household sector4 (total of items 58 to 66)_Household sector_57`
  )

standard_weights_tbl <- 
  lending_rates$data$lending_rate_tbl %>% 
  balance_rate_cleanup(bank = "Standard Bank") %>%
  weights(
    name_1 = "corporate_overdraft_weights",
    name_2 = "corporate_credit_weights",
    name_3 = "corporate_installment_weights",
    name_4 = "corporate_leasing_weights",
    name_5 = "households_overdraft_weights",
    name_6 = "households_credit_weights",
    name_7 = "households_installment_weights",
    name_8 = "households_leasing_weights",
    credit_1 = `Standard bank overdrafts_Corporate sector_48`,
    credit_2  = `Standard bank credit cards-_Corporate sector_55`,
    credit_3 = `Standard bank instalment sale agreements- flexible rate_Corporate sector_49`,
    credit_4 = `Standard bank leasing transactions- flexible rate_Corporate sector_51`,
    credit_5 = `Standard bank overdrafts_Household sector_58`,
    credit_6  = `Standard bank credit cards_Household sector_65`,
    credit_7 = `Standard bank instalment sale agreements- flexible rate_Household sector_59`,
    credit_8 = `Standard bank leasing transactions- flexible rate_Household sector_61`,
    total_1 = `Standard bank corporate sector 3 (total of items 48-56)_Corporate sector_47`,
    total_2 = `Standard bank household sector4 (total of items 58 to 66)_Household sector_57`
  )


fnb_weights_tbl <- 
  lending_rates$data$lending_rate_tbl %>% balance_rate_cleanup(bank = "FNB") %>% 
  weights(
    name_1 = "corporate_overdraft_weights",
    name_2 = "corporate_credit_weights",
    name_3 = "corporate_installment_weights",
    name_4 = "corporate_leasing_weights",
    name_5 = "households_overdraft_weights",
    name_6 = "households_credit_weights",
    name_7 = "households_installment_weights",
    name_8 = "households_leasing_weights",
    credit_1 = `Fnb overdrafts_Corporate sector_48`,
    credit_2  = `Fnb credit cards-_Corporate sector_55`,
    credit_3 = `Fnb instalment sale agreements- flexible rate_Corporate sector_49`,
    credit_4 = `Fnb leasing transactions- flexible rate_Corporate sector_51`,
    credit_5 = `Fnb overdrafts_Household sector_58`,
    credit_6  = `Fnb credit cards_Household sector_65`,
    credit_7 = `Fnb instalment sale agreements- flexible rate_Household sector_59`,
    credit_8 = `Fnb leasing transactions- flexible rate_Household sector_61`,
    total_1 = `Fnb corporate sector 3 (total of items 48-56)_Corporate sector_47`,
    total_2 = `Fnb household sector4 (total of items 58 to 66)_Household sector_57`
  )


absa_bank_weights_tbl <- 
  lending_rates$data$lending_rate_tbl %>% balance_rate_cleanup(bank = "Absa Bank") %>% 
  weights(
    name_1 = "corporate_overdraft_weights",
    name_2 = "corporate_credit_weights",
    name_3 = "corporate_installment_weights",
    name_4 = "corporate_leasing_weights",
    name_5 = "households_overdraft_weights",
    name_6 = "households_credit_weights",
    name_7 = "households_installment_weights",
    name_8 = "households_leasing_weights",
    credit_1 = `Absa bank overdrafts_Corporate sector_48`,
    credit_2  = `Absa bank credit cards-_Corporate sector_55`,
    credit_3 = `Absa bank instalment sale agreements- flexible rate_Corporate sector_49`,
    credit_4 = `Absa bank leasing transactions- flexible rate_Corporate sector_51`,
    credit_5 = `Absa bank overdrafts_Household sector_58`,
    credit_6  = `Absa bank credit cards_Household sector_65`,
    credit_7 = `Absa bank instalment sale agreements- flexible rate_Household sector_59`,
    credit_8 = `Absa bank leasing transactions- flexible rate_Household sector_61`,
    total_1 = `Absa bank corporate sector 3 (total of items 48-56)_Corporate sector_47`,
    total_2 = `Absa bank household sector4 (total of items 58 to 66)_Household sector_57`
  )
  
  
nedbank_weights_tbl <- 
  lending_rates$data$lending_rate_tbl %>% balance_rate_cleanup(bank = "Nedbank") %>% 
  weights(
    name_1 = "corporate_overdraft_weights",
    name_2 = "corporate_credit_weights",
    name_3 = "corporate_installment_weights",
    name_4 = "corporate_leasing_weights",
    name_5 = "households_overdraft_weights",
    name_6 = "households_credit_weights",
    name_7 = "households_installment_weights",
    name_8 = "households_leasing_weights",
    credit_1 = `Nedbank overdrafts_Corporate sector_48`,
    credit_2  = `Nedbank credit cards-_Corporate sector_55`,
    credit_3 = `Nedbank instalment sale agreements- flexible rate_Corporate sector_49`,
    credit_4 = `Nedbank leasing transactions- flexible rate_Corporate sector_51`,
    credit_5 = `Nedbank overdrafts_Household sector_58`,
    credit_6  = `Nedbank credit cards_Household sector_65`,
    credit_7 = `Nedbank instalment sale agreements- flexible rate_Household sector_59`,
    credit_8 = `Nedbank leasing transactions- flexible rate_Household sector_61`,
    total_1 = `Nedbank corporate sector 3 (total of items 48-56)_Corporate sector_47`,
    total_2 = `Nedbank household sector4 (total of items 58 to 66)_Household sector_57`
  )

capitec_weights_tbl <- 
  lending_rates$data$lending_rate_tbl %>% balance_rate_cleanup(bank = "Capitec") %>% 
  weights(
    name_1 = "corporate_overdraft_weights",
    name_2 = "corporate_credit_weights",
    name_3 = "corporate_installment_weights",
    name_4 = "corporate_leasing_weights",
    name_5 = "households_overdraft_weights",
    name_6 = "households_credit_weights",
    name_7 = "households_installment_weights",
    name_8 = "households_leasing_weights",
    credit_1 = `Capitec overdrafts_Corporate sector_48`,
    credit_2  = `Capitec credit cards-_Corporate sector_55`,
    credit_3 = `Capitec instalment sale agreements- flexible rate_Corporate sector_49`,
    credit_4 = `Capitec leasing transactions- flexible rate_Corporate sector_51`,
    credit_5 = `Capitec overdrafts_Household sector_58`,
    credit_6  = `Capitec credit cards_Household sector_65`,
    credit_7 = `Capitec instalment sale agreements- flexible rate_Household sector_59`,
    credit_8 = `Capitec leasing transactions- flexible rate_Household sector_61`,
    total_1 = `Capitec corporate sector 3 (total of items 48-56)_Corporate sector_47`,
    total_2 = `Capitec household sector4 (total of items 58 to 66)_Household sector_57`
  )


# lending and weights combination -----------------------------------------
joining <- function(data, joiner_data){
 data %>% 
    left_join(., joiner_data, by = c("Date" = "Date"))
}

total_banks_lending_weights_tbl <- total_lending_rate_tbl %>% joining(joiner_data = total_banks_weights_tbl)
fnb_lending_weights_tbl <- total_lending_rate_tbl %>% joining(joiner_data = fnb_weights_tbl)
absa_bank_lending_weights_tbl <- total_lending_rate_tbl %>% joining(joiner_data = absa_bank_weights_tbl)
standard_lending_weights_tbl <- total_lending_rate_tbl %>% joining(joiner_data = standard_weights_tbl)
nedbank_lending_weights_tbl <- total_lending_rate_tbl %>% joining(joiner_data = nedbank_weights_tbl)
capitec_lending_weights_tbl <- total_lending_rate_tbl %>% joining(joiner_data = capitec_weights_tbl)

# Aggregation -------------------------------------------------------------
aggregation <- function(data){
  data %>% 
    mutate(`Corporate unsecured credit rate` =  
             `Overdrafts_Corporate sector` *corporate_overdraft_weights  + # weighted average
             `Credit cards_Corporate sector`*corporate_credit_weights) %>% 
    mutate(`Corporate secured credit rate` = 
             `Instalment sale agreements- flexible rate_Corporate sector` *corporate_installment_weights  +   # weighted average
             `Leasing transactions- flexible rate_Corporate sector`*corporate_leasing_weights) %>% 
    rename("Corporate mortage rate" = "Mortgage advances- flexible rate_Corporate sector") %>% 
    mutate(`Household unsecured credit rate` = 
           `Overdrafts_Household sector` * households_overdraft_weights  + 
           `Credit cards_Household sector` * households_credit_weights ) %>% 
    mutate(`Household secured credit rate` = 
             `Instalment sale agreements- flexible rate_Household sector`* households_installment_weights + 
             `Leasing transactions- flexible rate_Household sector`  * households_leasing_weights) %>% 
    rename("Household mortage rate" = "Mortgage advances- flexible rate_Household sector") %>% 
    dplyr::select(Date, `Corporate unsecured credit rate`, `Corporate secured credit rate`, `Corporate mortage rate`, 
                  `Household unsecured credit rate`, `Household secured credit rate`, `Household mortage rate`) %>% 
    pivot_longer(-Date, names_to ="Series", values_to = "Value") 
}

# Combined data -----------------------------------------------------------
combined_lending_tbl <- 
  list("TOTAL BANKS" = total_banks_lending_weights_tbl %>% aggregation(),
      "ABSA BANK" = absa_bank_lending_weights_tbl %>% aggregation(),
      "FIRSTRAND BANK" = fnb_lending_weights_tbl %>% aggregation(),
      "STANDARD BANK" = standard_lending_weights_tbl %>% aggregation(),
      "NEDBANK" = nedbank_lending_weights_tbl %>% aggregation(),
      "CAPITEC BANK" = capitec_lending_weights_tbl  %>% aggregation()
       ) %>% 
  bind_rows(.id = "Bank") %>% 
  group_by(Bank, Series) %>% 
  summarise_by_time(
    .date_var = Date,
    .by = "quarter",
    Value = mean(Value)
  ) %>% 
  relocate(Date, .before = Bank) %>% 
  ungroup() 



# Descriptives -----------------------------------------------------------
descriptives_tbl <- combined_lending_tbl  %>% 
  drop_na() %>% 
  group_by(Series) %>% 
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
  group_by(Bank, Series) %>% 
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
  total_lending_rate_tbl = total_lending_rate_tbl,
  absa_lending_rate_tbl = absa_lending_rate_tbl,
  fnb_lending_rate_tbl = fnb_lending_rate_tbl,
  nedbank_lending_rate_tbl = nedbank_lending_rate_tbl,
  standard_lending_rate_tbl = standard_lending_rate_tbl,
  capitec_lending_rate_tbl = capitec_lending_rate_tbl,
  descriptives_tbl = descriptives_tbl,
  descriptives_by_bank_tbl = descriptives_by_bank_tbl,
  combined_lending_tbl = combined_lending_tbl
)

write_rds(artifacts_combined_lending , file = here("Outputs", "artifacts_combined_lending.rds"))


