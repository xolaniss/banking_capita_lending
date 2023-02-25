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
preprocessed_data <- read_rds(here("Outputs", "artifacts_preprocessing_monthly.rds"))
preprocessed_data_total_tbl <- preprocessed_data$masters$total_master_tbl
preprocessed_data_banks_tbl <- preprocessed_data$masters$banks_master_trans_tbl %>% clean_names()
preprocessed_data_banks_tbl %>% glimpse()

# 2.0 Exploring -----------------------------------------------------------

# 2.1 Co plots -----------------------------------------------------------------

# 2.1.1 Households --------------------------------------------------------------
coplot(household_sector_secured_credit  ~ date|bank, type = "l", data = preprocessed_data_banks_tbl)
coplot(household_sector_unsecured_credit ~ date|bank, type = "l", data = preprocessed_data_banks_tbl)
coplot(households_residential_mortgages   ~ date|bank, type = "l", data = preprocessed_data_banks_tbl)

# 2.1.2 Non Financial Sector --------------------------------------------------------------
coplot(non_financial_corporate_sector_mortgages  ~ date|bank, type = "l", data = preprocessed_data_banks_tbl)
coplot(non_financial_corporate_secured_credit ~ date|bank, type = "l", data = preprocessed_data_banks_tbl)
coplot(non_financial_corporate_unsecured_credit    ~ date|bank, type = "l", data = preprocessed_data_banks_tbl)

# 2.2 Scatter plot ---------------------------------------------------------

# 2.2.1 Households --------------------------------------------------------
car::scatterplot(household_sector_secured_credit  ~ date|bank,
            boxplots=TRUE, 
            smooth = TRUE, 
            data =  preprocessed_data_banks_tbl)
car::scatterplot(household_sector_unsecured_credit ~ date|bank,
                 boxplots=TRUE, 
                 smooth = TRUE, 
                 data =  preprocessed_data_banks_tbl)
car::scatterplot(households_residential_mortgages   ~ date|bank,
                 boxplots=TRUE, 
                 smooth = TRUE, 
                 data =  preprocessed_data_banks_tbl)


# 2.2.1 Non Financial --------------------------------------------------------
car::scatterplot(non_financial_corporate_sector_mortgages ~ date|bank,
                 boxplots=TRUE, 
                 smooth = TRUE, 
                 data =  preprocessed_data_banks_tbl)
car::scatterplot(non_financial_corporate_secured_credit ~ date|bank,
                 boxplots=TRUE, 
                 smooth = TRUE, 
                 data =  preprocessed_data_banks_tbl)
car::scatterplot(non_financial_corporate_unsecured_credit   ~ date|bank,
                 boxplots=TRUE, 
                 smooth = TRUE, 
                 data =  preprocessed_data_banks_tbl)


# 2.3 Bank Heterogeneity (Fixed effects) --------------------------------------------------

# 2.3.1 Households --------------------------------------------------------
gplots::plotmeans(household_sector_secured_credit  ~ bank, 
                  data = preprocessed_data_banks_tbl)
gplots::plotmeans(household_sector_unsecured_credit ~ bank, 
                  data = preprocessed_data_banks_tbl)
gplots::plotmeans(households_residential_mortgages  ~ bank, 
                  data = preprocessed_data_banks_tbl)

# 2.3.1 Non Financial --------------------------------------------------------
gplots::plotmeans(non_financial_corporate_sector_mortgages  ~ bank, 
                  data = preprocessed_data_banks_tbl)
gplots::plotmeans(non_financial_corporate_secured_credit ~ bank, 
                  data = preprocessed_data_banks_tbl)
gplots::plotmeans(non_financial_corporate_unsecured_credit  ~ bank, 
                  data = preprocessed_data_banks_tbl)

# 3.0 Models (Surplus capital) --------------------------------------------------------

# 3.1 OLS Initial models --------------------------------------------------------------------

## 3.1.1 Loan supply -------------------------------------------------------------

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

## 3.1.2 Loan demand -------------------------------------------------------------
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

## 3.2 OLS New models ------------------------------------------------

### Linear --------------------------------------------------------------
response_new_vec= c(
  "change_in_log_of_household_sector_secured_credit",
  "change_in_log_of_household_sector_unsecured_credit",
  "change_in_log_of_households_residential_mortgages",
  "change_in_log_of_non_financial_corporate_secured_credit",
  "change_in_log_of_non_financial_corporate_unsecured_credit",
  "change_in_log_of_non_financial_corporate_sector_mortgages"
)

vec_new_list <- list(
  all_vec_household_secured = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital"
    # "change_using_the_first_lag_of_household_secured_credit_rate",
    # "change_using_the_second_lag_of_household_secured_credit_rate",
    # "change_using_the_third_lag_of_household_secured_credit_rate"
  ),
  all_vec_household_unsecured = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital"
    # "change_using_the_first_lag_of_household_unsecured_credit_rate",
    # "change_using_the_second_lag_of_household_unsecured_credit_rate",
    # "change_using_the_third_lag_of_household_unsecured_credit_rate"
  ),
  all_vec_household_mortgage = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital"
    # "change_using_the_first_lag_of_household_mortage_rate",
    # "change_using_the_second_lag_of_household_mortage_rate",
    # "change_using_the_third_lag_of_household_mortage_rate"
  ),
  all_vec_corporate_secured = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital"
    # "change_using_the_first_lag_of_corporate_secured_credit_rate",
    # "change_using_the_second_lag_of_corporate_secured_credit_rate",
    # "change_using_the_third_lag_of_corporate_secured_credit_rate"
  ),
  all_vec_corporate_unsecured = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital"
    # "change_using_the_first_lag_of_corporate_unsecured_credit_rate",
    # "change_using_the_second_lag_of_corporate_unsecured_credit_rate",
    # "change_using_the_third_lag_of_corporate_unsecured_credit_rate"
  ),
  all_vec_corporate_mortgage = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital"
    # "change_using_the_first_lag_of_corporate_mortage_rate",
    # "change_using_the_second_lag_of_corporate_mortage_rate",
    # "change_using_the_third_lag_of_corporate_mortage_rate"
  )
)

formula_new_list <- map2(response_new_vec, vec_new_list, .f = ~ formula_function(.x, variable_vec = .y))
ols_model_new_list <- map(formula_new_list, .f = ~ lm(.x, data = preprocessed_data_banks_tbl))
ols_model_new_list %>% map(., ~summary(.x))

ols_model_new_list %>% map(., ~bptest(.x))

  # With min cap dummy
vec_min_cap_list <- list(
  all_vec_household_secured = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital",
    "minimum_cap_dummy"
    # "change_using_the_first_lag_of_household_secured_credit_rate",
    # "change_using_the_second_lag_of_household_secured_credit_rate",
    # "change_using_the_third_lag_of_household_secured_credit_rate"
  ),
  all_vec_household_unsecured = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital",
    "minimum_cap_dummy"
    # "change_using_the_first_lag_of_household_unsecured_credit_rate",
    # "change_using_the_second_lag_of_household_unsecured_credit_rate",
    # "change_using_the_third_lag_of_household_unsecured_credit_rate"
  ),
  all_vec_household_mortgage = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital",
    "minimum_cap_dummy"
    # "change_using_the_first_lag_of_household_mortage_rate",
    # "change_using_the_second_lag_of_household_mortage_rate",
    # "change_using_the_third_lag_of_household_mortage_rate"
  ),
  all_vec_corporate_secured = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital",
    "minimum_cap_dummy"
    # "change_using_the_first_lag_of_corporate_secured_credit_rate",
    # "change_using_the_second_lag_of_corporate_secured_credit_rate",
    # "change_using_the_third_lag_of_corporate_secured_credit_rate"
  ),
  all_vec_corporate_unsecured = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital",
    "minimum_cap_dummy"
    # "change_using_the_first_lag_of_corporate_unsecured_credit_rate",
    # "change_using_the_second_lag_of_corporate_unsecured_credit_rate",
    # "change_using_the_third_lag_of_corporate_unsecured_credit_rate"
  ),
  all_vec_corporate_mortgage = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital",
    "minimum_cap_dummy"
    # "change_using_the_first_lag_of_corporate_mortage_rate",
    # "change_using_the_second_lag_of_corporate_mortage_rate",
    # "change_using_the_third_lag_of_corporate_mortage_rate"
  )
)

formula_mincap_dummy_list <- map2(response_new_vec, vec_min_cap_list, .f = ~ formula_function(.x, variable_vec = .y))
ols_model_mincap_dummy_list <- map(formula_mincap_dummy_list, .f = ~ lm(.x, data = preprocessed_data_banks_tbl))
ols_model_mincap_dummy_list %>% map(., ~summary(.x))

# Time effects
preprocessed_data_banks_pdata <- pdata.frame(preprocessed_data_banks_tbl, 
                                                     index = c("bank", "date"))
between_linear_time_model_list <- 
  map(
    formula_new_list,
    .f = ~ plm(
      .x,
      index = c("bank", "date"),
      model = "between",
      effect = "time",
      data = preprocessed_data_banks_pdata
    )
  )
between_linear_time_model_list %>% map(., ~summary(.x)) 
map2(between_linear_time_model_list, ols_model_new_list, ~pFtest(.x,.y))

  # with min cap
between_linear_time_min_cap_model_list <- 
  map(
    formula_mincap_dummy_list,
    .f = ~ plm(
      .x,
      index = c("bank", "date"),
      model = "between",
      effect = "time",
      data = preprocessed_data_banks_pdata
    )
  )
between_linear_time_min_cap_model_list %>% map(., ~summary(.x)) 

# Reduced sample ----------------------------------------------------------

# OLS
preprocessed_data_banks_reduced_tbl <- 
  preprocessed_data_banks_tbl %>%
  filter(surplus_capital < 0.015) 

formula_new_list <- map2(response_new_vec, vec_new_list, .f = ~ formula_function(.x, variable_vec = .y))
ols_model_new_reduced_list <- map(formula_new_list, .f = ~ lm(.x, data = preprocessed_data_banks_reduced_tbl))

ols_model_new_reduced_list %>% map(., ~summary(.x))

  # with min cap
formula_reduced_mincap_dummy_list <- map2(response_new_vec, 
                                          vec_min_cap_list, .f = ~ formula_function(.x, variable_vec = .y))
ols_model_reduced_mincap_dummy_list <- map(formula_reduced_mincap_dummy_list, 
                                           .f = ~ lm(.x, data = preprocessed_data_banks_reduced_tbl))
ols_model_reduced_mincap_dummy_list %>% map(., ~summary(.x))

# Time effects
preprocessed_data_banks_reduced_pdata <- pdata.frame(preprocessed_data_banks_reduced_tbl, 
                                                     index = c("bank", "date"))
between_linear_time_reduced_model_list <- 
  map(
    formula_new_list,
    .f = ~ plm(
      .x,
      index = c("bank", "date"),
      model = "between",
      effect = "time",
      data =preprocessed_data_banks_reduced_pdata
    )
  )
between_linear_time_reduced_model_list %>% map(., ~summary(.x))

  # with min cap
between_reduced_linear_time_min_cap_model_list <- 
  map(
    formula_mincap_dummy_list,
    .f = ~ plm(
      .x,
      index = c("bank", "date"),
      model = "between",
      effect = "time",
      data = preprocessed_data_banks_reduced_pdata
    )
  )
between_reduced_linear_time_min_cap_model_list %>% map(., ~summary(.x)) 

### Non-Linear --------------------------------------------------------------
vec_squared_new_list <- list(
  all_vec_household_secured = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital",
    "squared_change_in_first_lag_of_surplus_capital",
    "squared_change_in_second_lag_of_surplus_capital",
    "squared_change_in_third_lag_of_surplus_capital"
    # "change_using_the_first_lag_of_household_secured_credit_rate",
    # "change_using_the_second_lag_of_household_secured_credit_rate",
    # "change_using_the_third_lag_of_household_secured_credit_rate"
  ),
  all_vec_household_unsecured = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital",
    "squared_change_in_first_lag_of_surplus_capital",
    "squared_change_in_second_lag_of_surplus_capital",
    "squared_change_in_third_lag_of_surplus_capital"
    # "change_using_the_first_lag_of_household_unsecured_credit_rate",
    # "change_using_the_second_lag_of_household_unsecured_credit_rate",
    # "change_using_the_third_lag_of_household_unsecured_credit_rate"
  ),
  all_vec_household_mortgage = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital",
    "squared_change_in_first_lag_of_surplus_capital",
    "squared_change_in_second_lag_of_surplus_capital",
    "squared_change_in_third_lag_of_surplus_capital"
    # "change_using_the_first_lag_of_household_mortage_rate",
    # "change_using_the_second_lag_of_household_mortage_rate",
    # "change_using_the_third_lag_of_household_mortage_rate"
  ),
  all_vec_corporate_secured = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital",
    "squared_change_in_first_lag_of_surplus_capital",
    "squared_change_in_second_lag_of_surplus_capital",
    "squared_change_in_third_lag_of_surplus_capital"
    # "change_using_the_first_lag_of_corporate_secured_credit_rate",
    # "change_using_the_second_lag_of_corporate_secured_credit_rate",
    # "change_using_the_third_lag_of_corporate_secured_credit_rate"
  ),
  all_vec_corporate_unsecured = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital",
    "squared_change_in_first_lag_of_surplus_capital",
    "squared_change_in_second_lag_of_surplus_capital",
    "squared_change_in_third_lag_of_surplus_capital"
    # "change_using_the_first_lag_of_corporate_unsecured_credit_rate",
    # "change_using_the_second_lag_of_corporate_unsecured_credit_rate",
    # "change_using_the_third_lag_of_corporate_unsecured_credit_rate"
  ),
  all_vec_corporate_mortgage = c(
    # "change_using_first_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_second_lag_of_minimum_required_capital_and_reserve_funds",
    # "change_using_the_third_lag_of_minimum_required_capital_and_reserve_funds",
    "change_in_surplus_capital",
    "change_in_first_lag_of_surplus_capital",
    "change_in_second_lag_of_surplus_capital",
    "change_in_third_lag_of_surplus_capital",
    "squared_change_in_first_lag_of_surplus_capital",
    "squared_change_in_second_lag_of_surplus_capital",
    "squared_change_in_third_lag_of_surplus_capital"
    # "change_using_the_first_lag_of_corporate_mortage_rate",
    # "change_using_the_second_lag_of_corporate_mortage_rate",
    # "change_using_the_third_lag_of_corporate_mortage_rate"
  )
)

formula_squared_new_list <- map2(response_new_vec, vec_squared_new_list, .f = ~ formula_function(.x, variable_vec = .y))
ols_model_squared_new_list <- map(formula_squared_new_list, .f = ~ lm(.x, data = preprocessed_data_banks_tbl))
ols_model_squared_new_list  %>% map(., ~summary(.x))

# Time effects
between_nonlinear_time_model_list <- 
  map(
    formula_squared_new_list,
    .f = ~ plm(
      .x,
      index = c("bank", "date"),
      model = "within",
      effect = "time",
      data = preprocessed_data_banks_pdata
    )
  )
between_nonlinear_time_model_list %>% map(., ~summary(.x))
map2(between_nonlinear_time_model_list, ols_model_squared_new_list, ~pFtest(.x,.y))

# Export ---------------------------------------------------------------
artifacts_models <- list (
  lin_cap_buffer = list(
    ols_model_new_list = ols_model_new_list,
    ols_model_new_reduced_list = ols_model_new_reduced_list,
    between_linear_time_model_list = between_linear_time_model_list,
    between_linear_time_reduced_model_list = between_linear_time_reduced_model_list
  ),
  lin_cap_buffer_min_cap = list(
    ols_model_mincap_dummy_list = ols_model_mincap_dummy_list,
    ols_model_reduced_mincap_dummy_list = ols_model_reduced_mincap_dummy_list,
    between_linear_time_min_cap_model_list = between_linear_time_min_cap_model_list,
    between_reduced_linear_time_min_cap_model_list = between_reduced_linear_time_min_cap_model_list
  ),
  non_lin_cap_buffer = list(
    ols_model_squared_new_list = ols_model_squared_new_list,
    between_nonlinear_time_model_list = between_nonlinear_time_model_list 
  )
)
write_rds(artifacts_models, file = here("Outputs", "artifacts_models_monthly.rds"))

