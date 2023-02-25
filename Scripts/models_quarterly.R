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
library(janitor)

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
library(plm)
library(gplots)

# 0.0  Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))

# 1.0 Import -------------------------------------------------------------
preprocessed_data <- read_rds(here("Outputs", "artifacts_preprocessing.rds"))
preprocessed_data_total_tbl <- preprocessed_data$masters$total_master_tbl
preprocessed_data_banks_tbl <- preprocessed_data$masters$banks_master_trans_tbl %>% clean_names()
preprocessed_data_banks_tbl %>% glimpse()

# 2.0 Exploring -----------------------------------------------------------

# 2.1 Co plots -----------------------------------------------------------------

# 2.1.1 Households --------------------------------------------------------------
coplot(household_sector_secured_credit_gdp  ~ date|bank, type = "l", data = preprocessed_data_banks_tbl)
coplot(household_sector_unsecured_credit_gdp ~ date|bank, type = "l", data = preprocessed_data_banks_tbl)
coplot(households_residential_mortgages_gdp   ~ date|bank, type = "l", data = preprocessed_data_banks_tbl)

# 2.1.2 Non Financial Sector --------------------------------------------------------------
coplot(non_financial_corporate_sector_mortgages  ~ date|bank, type = "l", data = preprocessed_data_banks_tbl)
coplot(non_financial_corporate_secured_credit_gdp ~ date|bank, type = "l", data = preprocessed_data_banks_tbl)
coplot(non_financial_corporate_unsecured_credit_gdp    ~ date|bank, type = "l", data = preprocessed_data_banks_tbl)

# 2.2 Scatter plot ---------------------------------------------------------

# 2.2.1 Households --------------------------------------------------------
car::scatterplot(household_sector_secured_credit_gdp  ~ date|bank,
            boxplots=TRUE, 
            smooth = TRUE, 
            data =  preprocessed_data_banks_tbl)
car::scatterplot(household_sector_unsecured_credit_gdp ~ date|bank,
                 boxplots=TRUE, 
                 smooth = TRUE, 
                 data =  preprocessed_data_banks_tbl)
car::scatterplot(households_residential_mortgages_gdp   ~ date|bank,
                 boxplots=TRUE, 
                 smooth = TRUE, 
                 data =  preprocessed_data_banks_tbl)


# 2.2.1 Non Financial --------------------------------------------------------
car::scatterplot(non_financial_corporate_sector_mortgages ~ date|bank,
                 boxplots=TRUE, 
                 smooth = TRUE, 
                 data =  preprocessed_data_banks_tbl)
car::scatterplot(non_financial_corporate_secured_credit_gdp ~ date|bank,
                 boxplots=TRUE, 
                 smooth = TRUE, 
                 data =  preprocessed_data_banks_tbl)
car::scatterplot(non_financial_corporate_unsecured_credit_gdp   ~ date|bank,
                 boxplots=TRUE, 
                 smooth = TRUE, 
                 data =  preprocessed_data_banks_tbl)


# 2.3 Bank Heterogeneity (Fixed effects) --------------------------------------------------

# 2.3.1 Households --------------------------------------------------------
gplots::plotmeans(household_sector_secured_credit_gdp  ~ bank, 
                  data = preprocessed_data_banks_tbl)
gplots::plotmeans(household_sector_unsecured_credit_gdp ~ bank, 
                  data = preprocessed_data_banks_tbl)
gplots::plotmeans(households_residential_mortgages_gdp  ~ bank, 
                  data = preprocessed_data_banks_tbl)

# 2.3.1 Non Financial --------------------------------------------------------
gplots::plotmeans(non_financial_corporate_sector_mortgages  ~ bank, 
                  data = preprocessed_data_banks_tbl)
gplots::plotmeans(non_financial_corporate_secured_credit_gdp ~ bank, 
                  data = preprocessed_data_banks_tbl)
gplots::plotmeans(non_financial_corporate_unsecured_credit_gdp  ~ bank, 
                  data = preprocessed_data_banks_tbl)

# 3.0 Models (Surplus capital) --------------------------------------------------------

# 3.1 OLS  --------------------------------------------------------------------


## Loan supply -------------------------------------------------------------

formula_function <-
  function(
    response_vec = NULL,
    variable_vec = NULL
  ) {
    as.formula(paste(
      response_vec,
      paste(variable_vec, collapse = "+"),
      sep = " ~ "
    ))
  }

response_vec = c(
  "change_in_log_of_household_sector_secured_credit",
  "change_in_log_of_household_sector_unsecured_credit",
  "change_in_log_of_households_residential_mortgages",
  "change_in_log_of_non_financial_corporate_secured_credit",
  "change_in_log_of_non_financial_corporate_unsecured_credit",
  "change_in_log_of_non_financial_corporate_sector_mortgages"
  )
vec_list <- list(
  all_vec_household_secured = c(
    "change_in_interest_margin_using_household_secured_credit_rate",
    "change_in_interest_margin_using_first_lag_of_household_secured_credit_rate",
    "change_in_interest_margin_using_second_lag_of_household_secured_credit_rate",
    "change_in_interest_margin_using_third_lag_of_household_secured_credit_rate",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital"
  ),
  all_vec_household_unsecured = c(
  "change_in_interest_margin_using_household_unsecured_credit_rate",
    "change_in_interest_margin_using_first_lag_of_household_unsecured_credit_rate",
    "change_in_interest_margin_using_second_lag_of_household_unsecured_credit_rate",
    "change_in_interest_margin_using_third_lag_of_household_unsecured_credit_rate",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital"
  ),
  all_vec_household_mortgage = c(
    "change_in_interest_margin_using_household_mortage_rate",
    "change_in_interest_margin_using_first_lag_of_household_mortage_rate",
    "change_in_interest_margin_using_second_lag_of_household_mortage_rate",
    "change_in_interest_margin_using_third_lag_of_household_mortage_rate",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital"
  ),
  all_vec_corporate_secured = c(
    "change_in_interest_margin_using_corporate_secured_credit_rate",
    "change_in_interest_margin_using_first_lag_of_corporate_secured_credit_rate",
    "change_in_interest_margin_using_second_lag_of_corporate_secured_credit_rate",
    "change_in_interest_margin_using_third_lag_of_corporate_secured_credit_rate",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital"
  ),
  all_vec_corporate_unsecured = c(
    "change_in_interest_margin_using_corporate_unsecured_credit_rate",
    "change_in_interest_margin_using_first_lag_of_corporate_unsecured_credit_rate",
    "change_in_interest_margin_using_second_lag_of_corporate_unsecured_credit_rate",
    "change_in_interest_margin_using_third_lag_of_corporate_unsecured_credit_rate",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital"
  ),
  all_vec_corporate_mortgage = c(
    "change_in_interest_margin_using_corporate_mortage_rate",
    "change_in_interest_margin_using_first_lag_of_corporate_mortage_rate",
    "change_in_interest_margin_using_second_lag_of_corporate_mortage_rate",
    "change_in_interest_margin_using_third_lag_of_corporate_mortage_rate",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital"
  )
)

formula_list <- map2(response_vec, vec_list, .f = ~ formula_function(.x, variable_vec = .y))
ols_model_list <- map(formula_list, .f = ~ lm(.x, data = preprocessed_data_banks_tbl))

ols_model_list %>% map(., ~summary(.x))


## Loan demand -------------------------------------------------------------
response_demand_vec <- c(
  "change_in_interest_margin_using_household_secured_credit_rate",
  "change_in_interest_margin_using_household_unsecured_credit_rate",
  "change_in_interest_margin_using_household_mortage_rate",
  "change_in_interest_margin_using_corporate_secured_credit_rate",
  "change_in_interest_margin_using_corporate_unsecured_credit_rate",
  "change_in_interest_margin_using_corporate_mortage_rate"
)

vec_demand_list <- list(
  capital_surplus = c(
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital"
  )
)

formula_list_demand <- map2(response_demand_vec, vec_demand_list, .f = ~ formula_function(.x, variable_vec = .y))
ols_model_list_demand <- map(formula_list_demand, .f = ~ lm(.x, data = preprocessed_data_banks_tbl))

ols_model_list_demand %>% map(., ~summary(.x))


# 3.2 Within model --------------------------------------------------------------------
preprocessed_data_banks_pdata <- pdata.frame(preprocessed_data_banks_tbl, index = c("bank", "date"))
preprocessed_data_banks_pdata %>% glimpse()
within_model_list <- 
map(
  formula_list,
  .f = ~ plm(
    .x,
    index = c("bank", "date"),
    model = "within",
    effect = "twoways",
    data = preprocessed_data_banks_pdata
  )
)
within_model_list %>% map(., ~summary(.x))


# fixef(household_secured_within_model) %>% summary() # fixed effects
# pFtest(household_secured_within_model, ols_household_secured_model)

# 3.3 Random effects --------------------------------------------------------------------

# random_model_list <- 
#   map(
#     formula_list,
#     .f = ~ plm(
#       .x,
#       index = c("bank", "date"),
#       model = "random",
#       data = preprocessed_data_banks_pdata
#     )
#   )
# random_model_list %>% map(., ~summary(.x))


household_secured_random_model <- 
plm(household_sector_secured_credit_gdp ~ surplus_capital, 
    data = preprocessed_data_banks_pdata,
    index = c("bank", "date"), 
    model = "random"
)
household_secured_random_model %>% 
  summary()

ranef(household_secured_random_model)


# 3.4 Fixed or Random effects test ---------------------------------------------
# phtest(fixed_household_secured_within_model, 
#        random_household_secured_within_model) # fixed or random test (Hausman test)

# # v4 --------------------------------------------------------------------


# # v5 --------------------------------------------------------------------


# Graphing ---------------------------------------------------------------


# Export ---------------------------------------------------------------
artifacts_models <- list (
  ols_model_list = ols_model_list,
  ols_model_list_demand = ols_model_list_demand,
  within_model_list = within_model_list
  )
write_rds(artifacts_models, file = here("Outputs", "artifacts_models_quartely.rds"))


