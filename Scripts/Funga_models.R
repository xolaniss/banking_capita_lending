# Description ----
# Funga et al. approach to our paper - Xolani Sibande February 2023

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
library(modelsummary)
library(flextable)

# graphs
library(PNWColors)
library(patchwork)

# eda
library(psych)
library(DataExplorer)
library(skimr)
library(janitor)
library(datawizard)

# econometrics
library(tseries)
library(strucchange)
library(vars)
library(urca)
library(mFilter)
library(car)
library(lpirfs)


# Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))
source(here("Functions", "formular_function.R"))
source(here("Functions", "flextable_word.R"))
source(here("Functions", "modelsummary_word.R"))
source(here("Functions", "borderlines.R"))

# Import -------------------------------------------------------------
preprocessed_data <-
  read_rds(here("Outputs", "artifacts_preprocessing_monthly.rds"))
preprocessed_data_banks_tbl <-
  preprocessed_data$masters$banks_master_tbl %>% 
  rename(`Required capital` = `Minimum required capital and reserve funds`)

preprocessed_data_banks_tbl %>% 
  glimpse()

# Transformations ---------------------------------------------------------
preprocessed_data_banks_base_tbl <-
  preprocessed_data_banks_tbl %>%
  mutate(across(
    .cols = 3:9,
    .fns = ~ log(.x),
    .names = "Log of {.col}"
  )) %>%     # logging loans
  mutate(across(
    .cols = starts_with("Log of"),
    .fns = ~ .x - lag(.x, n = 1),
    .names = "Change in {.col}"
  )) %>%     # one month change
  mutate(across(
    .cols = matches("Surplus capital"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  )) %>%   # one month change
  mutate(across(
    .cols = 10:15,
    .fns =  ~ .x - `Repo rate`,
    .names = "Interest margin using {.col}"
  ))  %>%    # Interest margin (demand)
  mutate(across(
    .cols = matches("Interest margin using"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  ))  %>%    # one month change
  mutate(across(
    .cols = matches("Total assets"),
    .fns = ~ log(.x),
    .names = "Log of {.col}"
  )) %>%     # logging total loans
  mutate(across(
    .cols = matches("Log of Total assets"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Return on assets"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Return on equity"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Level one high"),
    .fns = ~ log(.x),
    .names = "Log of {.col}"
  )) %>%     # logging liquidity
  mutate(across(
    .cols = contains("Log of level one high"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Required capital"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  )) %>%
  clean_names() %>%
  mutate(month = lubridate::month(date)) %>% 
  filter(date > "2013-01-01") 

  

preprocessed_data_banks_base_tbl %>% glimpse()

# Outliers ----------------------------------------------------------------
preprocessed_data_banks_base_tbl <-
  preprocessed_data_banks_base_tbl %>%
  mutate(across(contains("change_in"), .fns = ~ winsorize(.x, threshold = .01))) %>%
  mutate(across(
    contains("change_in_surplus_capital"),
    .fns = ~ winsorize(.x, threshold = .01)
  )) %>%
  mutate() %>% 
  mutate(across(
    contains("change_in_interest_margin_using"),
    .fns = ~ if_else(.x > 1, mean(.x), .x)
  ))

preprocessed_data_banks_base_tbl %>% glimpse()

# Capital requirement dummy -----------------------------------------------
preprocessed_data_banks_base_tbl <- 
preprocessed_data_banks_base_tbl %>% 
  mutate(
     across(
       .col =  contains("change_in_required_capital"), 
       .fns = ~  if_else(change_in_required_capital > 0.001, 1,
                                          if_else(change_in_required_capital < -0.001, 1, 0)),
                                                 
       .names = "{.col}_dummy"
     )
  ) %>%  
  mutate(
    change_in_required_capital_dummy = if_else(date <= "2012-12-01", 0, change_in_required_capital_dummy)
    ) 


# Summaries ---------------------------------------------------------------
summaries_tbl <- 
  preprocessed_data_banks_base_tbl %>% 
  dplyr::select(date, 
                bank, 
                change_in_log_of_household_sector_unsecured_credit,
                change_in_log_of_household_sector_secured_credit,
                change_in_log_of_households_residential_mortgages,
                change_in_log_of_non_financial_corporate_unsecured_credit,
                change_in_log_of_non_financial_corporate_secured_credit,
                change_in_log_of_non_financial_corporate_sector_mortgages,
                change_in_interest_margin_using_household_unsecured_credit_rate,
                change_in_interest_margin_using_household_secured_credit_rate,
                change_in_interest_margin_using_household_mortage_rate,
                change_in_interest_margin_using_corporate_unsecured_credit_rate,
                change_in_interest_margin_using_corporate_secured_credit_rate,
                change_in_interest_margin_using_corporate_mortage_rate,
                change_in_surplus_capital,
                change_in_required_capital_dummy,
                return_on_equity,
                return_on_assets,
                log_of_level_one_high_quality_liquid_assets_required_to_be_held
                ) %>% 
  drop_na() %>% 
  pivot_longer(-c(date,bank), names_to = "variable", values_to = "value") %>% 
  group_by(variable) %>% 
  summarise(across(.cols = -c(bank, date),
                   .fns = list(Median = median, 
                               SD = sd,
                               Min = min,
                               Max = max,
                               # IQR = IQR,
                               Obs = ~ n()), 
                   .names = "{.fn}"))

  
preprocessed_data_banks_base_tbl %>% glimpse()

# Graphing ----------------------------------------------------------------
Surplus_gg <-
  preprocessed_data_banks_base_tbl %>%
  dplyr::select(date, bank, matches("surplus")) %>%
  pivot_longer(-c(date, bank)) %>%
  ggplot(aes(
    x = date,
    group = bank,
    y = value,
    col = bank
  )) +
  geom_line() +
  facet_wrap(~ name, ncol = 4, scale = "free") +
  theme(legend.position = "top", text = element_text(size = 6))

loans_gg <-
  preprocessed_data_banks_base_tbl %>%
  dplyr::select(date, bank, contains("change_in")) %>%
  pivot_longer(-c(date, bank)) %>%
  ggplot(aes(
    x = date,
    group = bank,
    y = value,
    col = bank
  )) +
  geom_line() +
  facet_wrap(~ name, ncol = 4, scale = "free") +
  theme(legend.position = "top", text = element_text(size = 6))

loans_gg


Interest_margin_gg <-
  preprocessed_data_banks_base_tbl %>%
  dplyr::select(date, bank, matches("change_in_interest_margin_using")) %>%
  pivot_longer(-c(date, bank)) %>%
  ggplot(aes(
    x = date,
    group = bank,
    y = value,
    col = bank
  )) +
  geom_line() +
  facet_wrap(~ name, ncol = 4, scale = "free") +
  theme(legend.position = "top", text = element_text(size = 6))

Interest_margin_gg

required_gg <-
  preprocessed_data_banks_base_tbl %>%
  dplyr::select(date, bank, contains("required_capital")) %>%
  pivot_longer(-c(date, bank)) %>%
  ggplot(aes(
    x = date,
    group = bank,
    y = value,
    col = bank
  )) +
  geom_line() +
  facet_wrap(~ name, ncol = 4, scale = "free") +
  theme(legend.position = "top", text = element_text(size = 6))

required_gg

#  Models ------------------------------------------------------
## capital buffer requirement model -------------------------------------------------------------------
response_buffer_vec = c(
  "change_in_log_of_household_sector_secured_credit",
  "change_in_log_of_household_sector_unsecured_credit",
  "change_in_log_of_households_residential_mortgages",
  "change_in_log_of_non_financial_corporate_secured_credit",
  "change_in_log_of_non_financial_corporate_unsecured_credit",
  "change_in_log_of_non_financial_corporate_sector_mortgages"
)
predictor_buffer_vec = c(
  "change_in_required_capital_dummy",
  # "change_in_surplus_capital",
  "factor(bank)",
  "factor(month)",
  "-1")
vec_buffer_list <- list(
  all_vec_household_secured = predictor_buffer_vec,
  all_vec_household_unsecured = predictor_buffer_vec,
  all_vec_household_mortgage = predictor_buffer_vec,
  all_vec_corporate_secured = predictor_buffer_vec,
  all_vec_corporate_unsecured = predictor_buffer_vec,
  all_vec_corporate_mortgage = predictor_buffer_vec
)

one_month_buffer_formula_list <-
  map2(response_buffer_vec,
       vec_buffer_list,
       .f = ~ formula_function(.x, variable_vec = .y))
one_month_buffer_ols_model_list <-
  map(one_month_buffer_formula_list,
      .f = ~ lm(.x,  data = preprocessed_data_banks_base_tbl))
one_month_buffer_ols_model_list %>% map(., ~ summary(.x))
one_month_buffer_coeftest_model_list <-
  map(one_month_buffer_ols_model_list,
      .f = ~ coeftest(.x, vcov = vcovBS, cluster = ~ bank))
modelsummary(
  one_month_buffer_coeftest_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = NULL,
  title = "Capital requirement only"
)
zero_buffer_vec <- c("change_in_required_capital_dummy = 0")
joint_test_buffer <-
  map(one_month_buffer_ols_model_list,
      ~ linearHypothesis(.x, zero_buffer_vec, vcov. = vcovBS(.x, cluster = ~ bank)))


## capital buffer requirement and capital surplus ----------------------------------
predictor_buffer_and_surplus_vec = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  "factor(bank)",
  "factor(month)",
  "-1")
vec_buffer_surplus_list <- list(
  all_vec_household_secured = predictor_buffer_and_surplus_vec,
  all_vec_household_unsecured = predictor_buffer_and_surplus_vec,
  all_vec_household_mortgage = predictor_buffer_and_surplus_vec,
  all_vec_corporate_secured = predictor_buffer_and_surplus_vec,
  all_vec_corporate_unsecured = predictor_buffer_and_surplus_vec,
  all_vec_corporate_mortgage = predictor_buffer_and_surplus_vec
)

one_month_buffer_surplus_formula_list <-
  map2(response_buffer_vec,
       vec_buffer_surplus_list,
       .f = ~ formula_function(.x, variable_vec = .y))
one_month_buffer_surplus_ols_model_list <-
  map(one_month_buffer_surplus_formula_list,
      .f = ~ lm(.x, data = preprocessed_data_banks_base_tbl))
one_month_buffer_surplus_ols_model_list %>% map(., ~ summary(.x))
one_month_buffer_surplus_coeftest_model_list <-
  map(one_month_buffer_surplus_ols_model_list,
      .f = ~ coeftest(.x, vcov = vcovBS, cluster = ~ bank))
modelsummary(
  one_month_buffer_surplus_coeftest_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = NULL,
  title = "Capital buffer and Capital surplus buffer only"
)

zero_buffer_surplus_vec <- c(
  "change_in_required_capital_dummy = 0",
  "change_in_surplus_capital = 0")
joint_test_buffer_surplus <-
  map(one_month_buffer_surplus_ols_model_list,
      ~ linearHypothesis(.x, zero_buffer_surplus_vec, vcov. = vcovBS(.x, cluster = ~ bank)))

##  capital buffer requirement, capital surplus and demand model -------------------------------------------------------------------
predictor_vec_household_secured = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  "change_in_interest_margin_using_household_secured_credit_rate",
  "factor(bank)",
  "factor(month)",
  "-1"
)
predictor_vec_household_unsecured = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  "change_in_interest_margin_using_household_unsecured_credit_rate",
  "factor(bank)",
  "factor(month)",
  "-1"
)
predictor_vec_household_mortgage = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  "change_in_interest_margin_using_household_mortage_rate",
  "factor(bank)",
  "factor(month)",
  "-1"
)
predictor_vec_corporate_secured = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  "change_in_interest_margin_using_corporate_secured_credit_rate",
  "factor(bank)",
  "factor(month)",
  "-1"
)
predictor_vec_corporate_unsecured = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  "change_in_interest_margin_using_corporate_unsecured_credit_rate",
  "factor(bank)",
  "factor(month)",
  "-1"
)
predictor_vec_corporate_mortgage = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  "change_in_interest_margin_using_corporate_mortage_rate",
  "factor(bank)",
  "factor(month)",
  "-1"
)

vec_buffer_surplus_demand_list <- list(
  all_vec_household_secured = predictor_vec_household_secured,
  all_vec_household_unsecured = predictor_vec_household_unsecured,
  all_vec_household_mortgage = predictor_vec_household_mortgage,
  all_vec_corporate_secured = predictor_vec_corporate_secured,
  all_vec_corporate_unsecured = predictor_vec_corporate_unsecured,
  all_vec_corporate_mortgage = predictor_vec_corporate_mortgage
)
one_month_buffer_surplus_demand_formula_list <-
  map2(response_buffer_vec,
       vec_buffer_surplus_demand_list,
       .f = ~ formula_function(.x, variable_vec = .y))
one_month_buffer_surplus_demand_ols_model_list <-
  map(one_month_buffer_surplus_demand_formula_list,
      .f = ~ lm(.x, data = preprocessed_data_banks_base_tbl))
one_month_buffer_surplus_demand_ols_model_list %>% map(., ~ summary(.x))
one_month_buffer_surplus_demand_coeftest_model_list <-
  map(one_month_buffer_surplus_demand_ols_model_list,
      .f = ~ coeftest(.x, vcov = vcovBS, cluster = ~ bank))
modelsummary(
  one_month_buffer_surplus_demand_coeftest_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = NULL,
  title = "Capital requirement, Capital buffer and demand"
)
zero_buffer_surplus_demand_vec <- c(
  "change_in_required_capital_dummy = 0",
  "change_in_surplus_capital = 0")
joint_test_buffer_surplus_demand <-
  map(one_month_buffer_surplus_demand_ols_model_list,
      ~ linearHypothesis(.x, zero_buffer_surplus_demand_vec, vcov. = vcovBS(.x, cluster = ~ bank)))

## capital buffer controls ----------------------------------------------
predictor_buffer_surplus_control_vec = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  # "lag(log_of_total_assets)",
  "lag(return_on_assets)",
  "lag(return_on_equity)",
  "lag(log_of_level_one_high_quality_liquid_assets_required_to_be_held)",
  "factor(bank)",
  "factor(month)",
  "-1"
)
vec_buffer_surplus_control_list <- list(
  all_vec_household_secured = predictor_buffer_surplus_control_vec,
  all_vec_household_unsecured = predictor_buffer_surplus_control_vec,
  all_vec_household_mortgage = predictor_buffer_surplus_control_vec,
  all_vec_corporate_secured = predictor_buffer_surplus_control_vec,
  all_vec_corporate_unsecured = predictor_buffer_surplus_control_vec,
  all_vec_corporate_mortgage = predictor_buffer_surplus_control_vec
)

one_month_buffer_surplus_control_formula_list <-
  map2(response_buffer_vec,
       vec_buffer_surplus_control_list,
       .f = ~ formula_function(.x, variable_vec = .y))
one_month_buffer_surplus_control_ols_model_list <-
  map(
    one_month_buffer_surplus_control_formula_list,
    .f = ~ lm(.x, data = preprocessed_data_banks_base_tbl)
  )
one_month_buffer_surplus_control_ols_model_list %>% map(., ~ summary(.x))
one_month_buffer_surplus_control_coeftest_model_list <-
  map(
    one_month_buffer_surplus_control_ols_model_list,
    .f = ~ coeftest(.x, vcov = vcovBS, cluster = ~
                      bank)
  )

modelsummary(
  one_month_buffer_surplus_control_coeftest_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = NULL,
  title = "Capital buffer and bank controls"
)

zero_buffer_surplus_control_vec <- c(
  "change_in_required_capital_dummy = 0",
  "change_in_surplus_capital = 0"
)
joint_test_buffer_surplus_control <-
  map(
    one_month_buffer_surplus_control_ols_model_list,
    ~ linearHypothesis(.x, zero_buffer_surplus_control_vec, vcov. = vcovBS(.x, cluster = ~ bank)))

## capital buffer, capital surplus and demand and controls model -------------------------------------------------------------------
predictor_vec_household_secured_control = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  "change_in_interest_margin_using_household_secured_credit_rate",
  # "lag(log_of_total_assets)",
  "lag(return_on_assets)",
  "lag(return_on_equity)",
  "lag(log_of_level_one_high_quality_liquid_assets_required_to_be_held)",
  "factor(bank)",
  "factor(month)",
  "-1"
)
predictor_vec_household_unsecured_control = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  "change_in_interest_margin_using_household_unsecured_credit_rate",
  # "lag(log_of_total_assets)",
  "lag(return_on_assets)",
  "lag(return_on_equity)",
  "lag(log_of_level_one_high_quality_liquid_assets_required_to_be_held)",
  "factor(bank)",
  "factor(month)",
  "-1"
)
predictor_vec_household_mortgage_control = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  "change_in_interest_margin_using_household_mortage_rate",
  # "lag(log_of_total_assets)",
  "lag(return_on_assets)",
  "lag(return_on_equity)",
  "lag(log_of_level_one_high_quality_liquid_assets_required_to_be_held)",
  "factor(bank)",
  "factor(month)",
  "-1"
)
predictor_vec_corporate_secured_control = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  "change_in_interest_margin_using_corporate_secured_credit_rate",
  # "lag(log_of_total_assets)",
  "lag(return_on_assets)",
  "lag(return_on_equity)",
  "lag(log_of_level_one_high_quality_liquid_assets_required_to_be_held)",
  "factor(bank)",
  "factor(month)",
  "-1"
)
predictor_vec_corporate_unsecured_control = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  "change_in_interest_margin_using_corporate_unsecured_credit_rate",
  # "lag(log_of_total_assets)",
  "lag(return_on_assets)",
  "lag(return_on_equity)",
  "lag(log_of_level_one_high_quality_liquid_assets_required_to_be_held)",
  "factor(bank)",
  "factor(month)",
  "-1"
)
predictor_vec_corporate_mortgage_control = c(
  "change_in_required_capital_dummy",
  "change_in_surplus_capital",
  "change_in_interest_margin_using_corporate_mortage_rate",
  # "lag(log_of_total_assets)",
  "lag(return_on_assets)",
  "lag(return_on_equity)",
  "lag(log_of_level_one_high_quality_liquid_assets_required_to_be_held)",
  "factor(bank)",
  "factor(month)",
  "-1"
)

vec_buffer_surplus_demand_control_list <- list(
  all_vec_household_secured = predictor_vec_household_secured_control,
  all_vec_household_unsecured = predictor_vec_household_unsecured_control,
  all_vec_household_mortgage = predictor_vec_household_mortgage_control,
  all_vec_corporate_secured = predictor_vec_corporate_secured_control,
  all_vec_corporate_unsecured = predictor_vec_corporate_unsecured_control,
  all_vec_corporate_mortgage = predictor_vec_corporate_mortgage_control
)
one_month_buffer_surplus_demand_control_formula_list <-
  map2(response_buffer_vec,
       vec_buffer_surplus_demand_control_list,
       .f = ~ formula_function(.x, variable_vec = .y))
one_month_buffer_surplus_demand_control_ols_model_list <-
  map(
    one_month_buffer_surplus_demand_control_formula_list,
    .f = ~ lm(.x, data = preprocessed_data_banks_base_tbl)
  )
one_month_buffer_surplus_demand_control_ols_model_list %>% map(., ~ summary(.x))
one_month_buffer_surplus_demand_control_coeftest_model_list <-
  map(
    one_month_buffer_surplus_demand_control_ols_model_list,
    .f = ~ coeftest(.x, vcov = vcovBS, cluster = ~ bank)
  )
modelsummary(
  one_month_buffer_surplus_demand_control_coeftest_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = NULL,
  title = "capital buffer and demand and bank controls"
)
zero_buffer_surplus_demand_control_vec <- c(
  "change_in_required_capital_dummy = 0",
  "change_in_surplus_capital = 0"
)
joint_test_buffer_surplus_demand_control <-
  map(
    one_month_buffer_surplus_demand_control_ols_model_list,
    ~ linearHypothesis(.x, zero_buffer_surplus_demand_control_vec, vcov. = vcovBS(.x, cluster = ~ bank))
  )

# Bank characteristics ----------------------------------------------------


## Return on assets ------------------------------------------------------

### filtering data ---------------------------------------------------------
preprocessed_data_banks_top_return_on_assets_base_tbl <- 
  preprocessed_data_banks_base_tbl %>% 
  # group_by(bank) %>% 
  slice_max( 
    order_by = return_on_assets, 
    prop = .5) %>% 
  ungroup()

preprocessed_data_banks_bottom_return_on_assets_base_tbl <- 
  preprocessed_data_banks_base_tbl %>% 
  # group_by(bank) %>% 
  slice_min( 
    order_by = return_on_assets, 
    prop = .5) %>% 
  ungroup()


### top capital controls ----------------------------------------------
one_month_buffer_surplus_control_ols_top_return_on_assets_model_list <-
  map(
    one_month_buffer_surplus_control_formula_list,
    .f = ~ lm(.x, data = preprocessed_data_banks_top_return_on_assets_base_tbl)
  )
one_month_buffer_surplus_control_ols_top_return_on_assets_model_list %>% map(., ~ summary(.x))
one_month_buffer_surplus_control_coeftest_top_return_on_assets_model_list <-
  map(
    one_month_buffer_surplus_control_ols_top_return_on_assets_model_list,
    .f = ~ coeftest(.x, vcov = vcovBS, cluster = ~
                      bank)
  )
modelsummary(
  one_month_buffer_surplus_control_coeftest_top_return_on_assets_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = NULL,
  title = "High return on assets capital buffer and bank controls"
)
joint_test_buffer_surplus_control_top_return_on_assets <-
  map(
    one_month_buffer_surplus_control_ols_top_return_on_assets_model_list,
    ~ linearHypothesis(.x, zero_buffer_surplus_control_vec, vcov. = vcovBS(.x, cluster = ~ bank)))

### bottom capital controls -------------------------------------------------
one_month_buffer_surplus_control_ols_bottom_return_on_assets_model_list <-
  map(
    one_month_buffer_surplus_control_formula_list,
    .f = ~ lm(.x, data = preprocessed_data_banks_bottom_return_on_assets_base_tbl)
  )
one_month_buffer_surplus_control_ols_bottom_return_on_assets_model_list %>% map(., ~ summary(.x))
one_month_buffer_surplus_control_coeftest_bottom_return_on_assets_model_list <-
  map(
    one_month_buffer_surplus_control_ols_bottom_return_on_assets_model_list,
    .f = ~ coeftest(.x, vcov = vcovBS, cluster = ~
                      bank)
  )
modelsummary(
  one_month_buffer_surplus_control_coeftest_bottom_return_on_assets_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = NULL,
  title = "Low return on assets capital buffers and bank controls"
)
joint_test_buffer_surplus_control_bottom_return_on_assets <-
  map(
    one_month_buffer_surplus_control_ols_bottom_return_on_assets_model_list,
    ~ linearHypothesis(.x, zero_buffer_surplus_control_vec, vcov. = vcovBS(.x, cluster = ~ bank))
  )

## Return on equity ------------------------------------------------------

### filtering data ---------------------------------------------------------
preprocessed_data_banks_top_return_on_equity_base_tbl <- 
  preprocessed_data_banks_base_tbl %>% 
  # group_by(bank) %>% 
  slice_max( 
    order_by = return_on_equity, 
    prop = .5) %>% 
  ungroup()

preprocessed_data_banks_bottom_return_on_equity_base_tbl <- 
  preprocessed_data_banks_base_tbl %>% 
  # group_by(bank) %>% 
  slice_min( 
    order_by = return_on_equity, 
    prop = .5) %>% 
  ungroup()


### top capital controls ----------------------------------------------
one_month_buffer_surplus_control_ols_top_return_on_equity_model_list <-
  map(
    one_month_buffer_surplus_control_formula_list,
    .f = ~ lm(.x, data = preprocessed_data_banks_top_return_on_equity_base_tbl)
  )
one_month_buffer_surplus_control_ols_top_return_on_equity_model_list %>% map(., ~ summary(.x))
one_month_buffer_surplus_control_coeftest_top_return_on_equity_model_list <-
  map(
    one_month_buffer_surplus_control_ols_top_return_on_equity_model_list,
    .f = ~ coeftest(.x, vcov = vcovBS, cluster = ~
                      bank)
  )
modelsummary(
  one_month_buffer_surplus_control_coeftest_top_return_on_equity_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = NULL,
  title = "High return on equity capital buffer and bank controls"
)
joint_test_buffer_surplus_control_top_return_on_equity <-
  map(
    one_month_buffer_surplus_control_ols_top_return_on_equity_model_list,
    ~ linearHypothesis(.x, zero_buffer_surplus_control_vec, vcov. = vcovBS(.x, cluster = ~ bank))
  )

### bottom capital controls -------------------------------------------------
one_month_buffer_surplus_control_ols_bottom_return_on_equity_model_list <-
  map(
    one_month_buffer_surplus_control_formula_list,
    .f = ~ lm(.x, data = preprocessed_data_banks_bottom_return_on_equity_base_tbl)
  )
one_month_buffer_surplus_control_ols_bottom_return_on_equity_model_list %>% map(., ~ summary(.x))
one_month_buffer_surplus_control_coeftest_bottom_return_on_equity_model_list <-
  map(
    one_month_buffer_surplus_control_ols_bottom_return_on_equity_model_list,
    .f = ~ coeftest(.x, vcov = vcovBS, cluster = ~
                      bank)
  )
modelsummary(
  one_month_buffer_surplus_control_coeftest_bottom_return_on_equity_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = NULL,
  title = "Low return on equity capital buffer and bank controls"
)
joint_test_buffer_surplus_control_bottom_return_on_equity <-
  map(
    one_month_buffer_surplus_control_ols_bottom_return_on_equity_model_list,
    ~ linearHypothesis(.x, zero_buffer_surplus_control_vec, vcov. = vcovBS(.x, cluster = ~ bank))
  )

## Liquidity ------------------------------------------------------
### filtering data ---------------------------------------------------------
preprocessed_data_banks_top_liqudity_base_tbl <- 
  preprocessed_data_banks_base_tbl %>% 
  # group_by(bank) %>% 
  slice_max( 
    order_by = change_in_log_of_level_one_high_quality_liquid_assets_required_to_be_held, 
    prop = .5) %>% 
  ungroup()

preprocessed_data_banks_bottom_liqudity_base_tbl <- 
  preprocessed_data_banks_base_tbl %>% 
  # group_by(bank) %>% 
  slice_min( 
    order_by = change_in_log_of_level_one_high_quality_liquid_assets_required_to_be_held, 
    prop = .5) %>% 
  ungroup()


### top capital controls ----------------------------------------------
one_month_buffer_surplus_control_ols_top_liqudity_model_list <-
  map(
    one_month_buffer_surplus_control_formula_list,
    .f = ~ lm(.x, data = preprocessed_data_banks_top_liqudity_base_tbl)
  )
one_month_buffer_surplus_control_ols_top_liqudity_model_list %>% map(., ~ summary(.x))
one_month_buffer_surplus_control_coeftest_top_liqudity_model_list <-
  map(
    one_month_buffer_surplus_control_ols_top_liqudity_model_list,
    .f = ~ coeftest(.x, vcov = vcovBS, cluster = ~
                      bank)
  )
modelsummary(
  one_month_buffer_surplus_control_coeftest_top_liqudity_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = NULL,
  title = "High liquidity capital buffer and bank controls"
)
joint_test_buffer_surplus_control_top_liqudity <-
  map(
    one_month_buffer_surplus_control_ols_top_liqudity_model_list,
    ~ linearHypothesis(.x, zero_buffer_surplus_control_vec, vcov. = vcovBS(.x, cluster = ~ bank))
  )

### bottom capital controls -------------------------------------------------
one_month_buffer_surplus_control_ols_bottom_liqudity_model_list <-
  map(
    one_month_buffer_surplus_control_formula_list,
    .f = ~ lm(.x, data = preprocessed_data_banks_bottom_liqudity_base_tbl)
  )
one_month_buffer_surplus_control_ols_bottom_liqudity_model_list %>% map(., ~ summary(.x))
one_month_buffer_surplus_control_coeftest_bottom_liqudity_model_list <-
  map(
    one_month_buffer_surplus_control_ols_bottom_liqudity_model_list,
    .f = ~ coeftest(.x, vcov = vcovBS, cluster = ~
                      bank)
  )
modelsummary(
  one_month_buffer_surplus_control_coeftest_bottom_liqudity_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = NULL,
  title = "Low liquidity capital buffers and bank controls"
)
joint_test_buffer_surplus_control_bottom_liqudity <-
  map(
    one_month_buffer_surplus_control_ols_bottom_liqudity_model_list,
    ~ linearHypothesis(.x, zero_buffer_surplus_control_vec, vcov. = vcovBS(.x, cluster = ~ bank))
  )



# Impulse responses -------------------------------------------------------


## Creating data -----------------------------------------------------------
preprocessed_data_banks_base_tbl_irs <- 
  preprocessed_data_banks_base_tbl %>% 
  dplyr::select( 
                bank, 
                date,
                change_in_log_of_non_financial_corporate_unsecured_credit,
                change_in_log_of_non_financial_corporate_secured_credit,
                change_in_log_of_non_financial_corporate_sector_mortgages,
                change_in_log_of_household_sector_unsecured_credit,
                change_in_log_of_household_sector_secured_credit,
                change_in_log_of_households_residential_mortgages,
                change_in_required_capital_dummy,
                return_on_assets,
                return_on_equity,
                log_of_level_one_high_quality_liquid_assets_required_to_be_held
                ) 

preprocessed_data_banks_base_tbl %>% glimpse()
preprocessed_data_banks_base_tbl_irs %>% glimpse()


## Corporations unsecured --------------------------------------------------

result_nfc_unsecured <- 
  lp_lin_panel(
  data_set = preprocessed_data_banks_base_tbl_irs,
  endog_data = "change_in_log_of_non_financial_corporate_unsecured_credit",
  shock = "change_in_required_capital_dummy",
  cumul_mult = FALSE,
  diff_shock = FALSE,
  panel_model = "within",
  panel_effect = "twoways",
  robust_cov = "vcovBK",
  robust_cluster = "group",
  l_exog_data = c("return_on_assets", 
                  "return_on_equity", 
                  "log_of_level_one_high_quality_liquid_assets_required_to_be_held"),
  lags_exog_data = 1,
  confint = 1.96,
  hor = 11
)

result_nfc_unsecured_gg <- 
  plot(result_nfc_unsecured) +
  labs(x = "Month (0 is the moment of implementation and the shock)", 
       y = "Estimated on KR",
       title = "Non-financial corporations unsecured") 


## Corporations secured ----------------------------------------------------

result_nfc_secured <- 
  lp_lin_panel(
    data_set = preprocessed_data_banks_base_tbl_irs,
    endog_data = "change_in_log_of_non_financial_corporate_secured_credit",
    shock = "change_in_required_capital_dummy",
    cumul_mult = FALSE,
    diff_shock = FALSE,
    panel_model = "within",
    panel_effect = "twoways",
    robust_cov = "vcovBK",
    robust_cluster = "group",
    l_exog_data = c("return_on_assets", 
                    "return_on_equity", 
                    "log_of_level_one_high_quality_liquid_assets_required_to_be_held"),
    lags_exog_data = 1,
    confint = 1.96,
    hor = 11
  )

result_nfc_secured_gg <- 
  plot(result_nfc_secured) +
  labs(x = "Month (0 is the moment of implementation and the shock)", 
       y = "Estimated on KR",
       title = "Non-financial corporations secured") 

## Corporations mortgages --------------------------------------------------
result_nfc_mortgage <- 
  lp_lin_panel(
    data_set = preprocessed_data_banks_base_tbl_irs,
    endog_data = "change_in_log_of_non_financial_corporate_sector_mortgages",
    shock = "change_in_required_capital_dummy",
    cumul_mult = FALSE,
    diff_shock = FALSE,
    panel_model = "within",
    panel_effect = "twoways",
    robust_cov = "vcovBK",
    robust_cluster = "group",
    l_exog_data = c("return_on_assets", 
                    "return_on_equity", 
                    "log_of_level_one_high_quality_liquid_assets_required_to_be_held"),
    lags_exog_data = 1,
    confint = 1.96,
    hor = 11
  )

result_nfc_mortgage_gg <- 
  plot(result_nfc_mortgage) +
  labs(x = "Month (0 is the moment of implementation and the shock)", 
       y = "Estimated on KR",
       title = "Non-financial corporations mortgages") 

## Household unsecured --------------------------------------------------
result_hh_unsecured <- 
  lp_lin_panel(
    data_set = preprocessed_data_banks_base_tbl_irs,
    endog_data = "change_in_log_of_household_sector_unsecured_credit",
    shock = "change_in_required_capital_dummy",
    cumul_mult = FALSE,
    diff_shock = FALSE,
    panel_model = "within",
    panel_effect = "twoways",
    robust_cov = "vcovBK",
    robust_cluster = "group",
    l_exog_data = c("return_on_assets", 
                    "return_on_equity", 
                    "log_of_level_one_high_quality_liquid_assets_required_to_be_held"),
    lags_exog_data = 1,
    confint = 1.96,
    hor = 11
  )

result_hh_unsecured_gg <- 
  plot(result_hh_unsecured) +
  labs(x = "Month (0 is the moment of implementation and the shock)", 
       y = "Estimated on KR",
       title = "Household unsecured") 


## Household secured ----------------------------------------------------
result_hh_secured <- 
  lp_lin_panel(
    data_set = preprocessed_data_banks_base_tbl_irs,
    endog_data = "change_in_log_of_household_sector_secured_credit",
    shock = "change_in_required_capital_dummy",
    cumul_mult = FALSE,
    diff_shock = FALSE,
    panel_model = "within",
    panel_effect = "twoways",
    robust_cov = "vcovBK",
    robust_cluster = "group",
    l_exog_data = c("return_on_assets", 
                    "return_on_equity", 
                    "log_of_level_one_high_quality_liquid_assets_required_to_be_held"),
    lags_exog_data = 1,
    confint = 1.96,
    hor = 11
  )

result_hh_secured_gg <- 
  plot(result_hh_secured) +
  labs(x = "Month (0 is the moment of implementation and the shock)", 
       y = "Estimated on KR",
       title = "Household secured") 

## Household mortgages --------------------------------------------------
result_hh_mortgage <- 
  lp_lin_panel(
    data_set = preprocessed_data_banks_base_tbl_irs,
    endog_data = "change_in_log_of_households_residential_mortgages",
    cumul_mult = FALSE,
    shock = "change_in_required_capital_dummy",
    diff_shock = FALSE,
    panel_model = "within",
    panel_effect = "twoways",
    robust_cov = "vcovBK",
    robust_cluster = "group",
    l_exog_data = c("return_on_assets", 
                    "return_on_equity", 
                    "log_of_level_one_high_quality_liquid_assets_required_to_be_held"),
    lags_exog_data = 1,
    confint = 1.96,
    hor = 11
  )

result_hh_mortgage_gg <- 
  plot(result_hh_mortgage) +
  labs(x = "Month (0 is the moment of implementation and the shock)", 
       y = "Estimated on KR",
       title = "Household residential mortgages") 



## Patchwork ---------------------------------------------------------------
path_gg <- (result_hh_unsecured_gg + result_hh_secured_gg) /
            (result_hh_mortgage_gg + result_nfc_unsecured_gg)/
            (result_nfc_secured_gg + result_nfc_mortgage_gg)

# Export ---------------------------------------------------------------
artifacts_base_model <- list (
  lm_models = list(
    one_month_buffer_ols_model_list = one_month_buffer_ols_model_list,
    one_month_buffer_surplus_ols_model_list = one_month_buffer_surplus_ols_model_list,
    one_month_buffer_surplus_demand_ols_model_list = one_month_buffer_surplus_demand_ols_model_list,
    one_month_buffer_surplus_control_ols_model_list = one_month_buffer_surplus_control_ols_model_list,
    one_month_buffer_surplus_demand_control_ols_model_list = one_month_buffer_surplus_demand_control_ols_model_list
  ),
  coef_models = list(
    one_month_buffer_coeftest_model_list = one_month_buffer_coeftest_model_list,
    one_month_buffer_surplus_coeftest_model_list = one_month_buffer_surplus_coeftest_model_list,
    one_month_buffer_surplus_demand_coeftest_model_list = one_month_buffer_surplus_demand_coeftest_model_list,
    one_month_buffer_surplus_control_coeftest_model_list = one_month_buffer_surplus_control_coeftest_model_list,
    one_month_buffer_surplus_demand_control_coeftest_model_list = one_month_buffer_surplus_demand_control_coeftest_model_list
  ),
  joint_test  = list(
    joint_test_buffer = joint_test_buffer,
    joint_test_buffer_surplus = joint_test_buffer_surplus,
    joint_test_buffer_surplus_demand = joint_test_buffer_surplus_demand,
    joint_test_buffer_surplus_control = joint_test_buffer_surplus_control,
    joint_test_buffer_surplus_demand_control = joint_test_buffer_surplus_demand_control,
    joint_test_buffer_surplus_control_top_return_on_assets = joint_test_buffer_surplus_control_top_return_on_assets,
    joint_test_buffer_surplus_control_bottom_return_on_assets = joint_test_buffer_surplus_control_bottom_return_on_assets,
    joint_test_buffer_surplus_control_top_liqudity = joint_test_buffer_surplus_control_top_liqudity
  ),
  data = list(preprocessed_data_banks_base_tbl = preprocessed_data_banks_base_tbl),
  graphs = list(
    path_gg  = path_gg
  ),
  summaries = list(
    summaries_tbl = summaries_tbl
  )
)

write_rds(artifacts_base_model,
          file = here("Outputs", "artifacts_base_model.rds"))
