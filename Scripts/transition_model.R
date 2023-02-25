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
library(janitor)
library(datawizard)

# econometrics
library(tseries)
library(strucchange)
library(vars)
library(urca)
library(mFilter)
library(car)


# Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))
source(here("Functions", "formular_function.R"))

# Import -------------------------------------------------------------
preprocessed_data <-
  read_rds(here("Outputs", "artifacts_preprocessing_monthly.rds"))
preprocessed_data_banks_tbl <-
  preprocessed_data$masters$banks_master_tbl


preprocessed_data_banks_tbl %>% glimpse()

# Transformations ---------------------------------------------------------
preprocessed_data_banks_transition_tbl <-
  preprocessed_data_banks_tbl %>%
  mutate(across(
    .cols = 3:9,
    .fns = ~ log(.x),
    .names = "Log of {.col}"
  )) %>%     # logging loans
  mutate(across(
    .cols = contains("Log of"),
    .fns = ~ .x - lag(.x, n = 1),
    .names = "Change in {.col}"
  )) %>%    # one month change
  mutate(across(
    .cols = 17,
    .fns = ~  lag(.x),
    .names = "First lag of {.col}"
  )) %>%    
  mutate(across(
    .cols = 17,
    .fns = ~  lag(.x, n = 2),
    .names = "Second lag of {.col}"
  )) %>%
  mutate(across(
    .cols = 17,
    .fns = ~  lag(.x, n = 3),
    .names = "Third lag of {.col}"
  )) %>%
  mutate(across(
    .cols = 17,
    .fns = ~  lag(.x, n = 4),
    .names = "Fourth lag of {.col}"
  )) %>%
  mutate(across(
    .cols = 17,
    .fns = ~  lag(.x, n = 5),
    .names = "Fifth lag of {.col}"
  )) %>%
  mutate(across(
    .cols = 17,
    .fns = ~  lag(.x, n = 6),
    .names = "Sixth lag of {.col}"
  )) %>%
  mutate(across(
    .cols = 17,
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  )) %>%  # one month change
  mutate(across(
    .cols = matches("First lag of Surplus capital"),
    .fns = ~  .x - lag(.x),
    .names = "Change in  {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Second lag of Surplus capital"),
    .fns = ~  .x - lag(.x),
    .names = "Change in {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Third lag of Surplus capital"),
    .fns = ~  .x - lag(.x),
    .names = "Change in  {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Fourth lag of Surplus capital"),
    .fns = ~  .x - lag(.x),
    .names = "Change in  {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Fifth lag of Surplus capital"),
    .fns = ~  .x - lag(.x),
    .names = "Change in  {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Sixth lag of Surplus capital"),
    .fns = ~  .x - lag(.x),
    .names = "Change in  {.col}"
  )) %>%
  mutate(across(
    .cols = 17,
    .fns = ~  .x - lag(.x, n = 3),
    .names = "Three Month Change in {.col}"
  )) %>% # three month change
  mutate(across(
    .cols = matches("First lag of Surplus capital"),
    .fns = ~  .x - lag(.x, n = 3),
    .names = "Three Month Change in  {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Second lag of Surplus capital"),
    .fns = ~  .x - lag(.x, n = 3),
    .names = "Three Month Change in {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Third lag of Surplus capital"),
    .fns = ~  .x - lag(.x, n = 3),
    .names = "Three Month Change in  {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Fourth lag of Surplus capital"),
    .fns = ~  .x - lag(.x, n = 3),
    .names = "Three Month Change in  {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Fifth lag of Surplus capital"),
    .fns = ~  .x - lag(.x, n = 3),
    .names = "Three Month Change in  {.col}"
  )) %>%
  mutate(across(
    .cols = matches("Sixth lag of Surplus capital"),
    .fns = ~  .x - lag(.x, n = 3),
    .names = "Three Month Change in  {.col}"
  )) %>%
  clean_names() %>%
  mutate(year = lubridate::year(date))


preprocessed_data_banks_transition_tbl %>% glimpse()


# Outliers ----------------------------------------------------------------
preprocessed_data_banks_transition_tbl <-
  preprocessed_data_banks_transition_tbl %>%
  mutate(across(matches("change_in_log"), .fns = ~ winsorize(.x, threshold = .01))) %>%
  mutate(across(
    contains("surplus_capital"),
    .fns = ~ winsorize(.x, threshold = .01)
  ))

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

# Graphing ----------------------------------------------------------------
Surplus_gg <-
  preprocessed_data_banks_transition_tbl %>%
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
  preprocessed_data_banks_transition_tbl %>%
  dplyr::select(date, bank, matches("change_in_log")) %>%
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


# t, t - 1 Model -------------------------------------------------------------------
response_vec = c(
  "change_in_log_of_household_sector_secured_credit",
  "change_in_log_of_household_sector_unsecured_credit",
  "change_in_log_of_households_residential_mortgages",
  "change_in_log_of_non_financial_corporate_secured_credit",
  "change_in_log_of_non_financial_corporate_unsecured_credit",
  "change_in_log_of_non_financial_corporate_sector_mortgages"
)

predictor_vec = c(
  "change_in_surplus_capital",
  "change_in_first_lag_of_surplus_capital",
  "change_in_second_lag_of_surplus_capital",
  "change_in_third_lag_of_surplus_capital",
  # "change_in_fourth_lag_of_surplus_capital", # No significance after third lad
  # "change_in_fifth_lag_of_surplus_capital",
  # "change_in_sixth_lag_of_surplus_capital",
  "factor(bank)",
  "factor(year)",
  "-1"
)

vec_list <- list(
  all_vec_household_secured = predictor_vec,
  all_vec_household_unsecured = predictor_vec,
  all_vec_household_mortgage = predictor_vec,
  all_vec_corporate_secured = predictor_vec,
  all_vec_corporate_unsecured = predictor_vec,
  all_vec_corporate_mortgage = predictor_vec
)

one_month_formula_list <-
  map2(response_vec,
       vec_list,
       .f = ~ formula_function(.x, variable_vec = .y))
one_month_ols_model_list <-
  map(one_month_formula_list,
      .f = ~ lm(.x, data = preprocessed_data_banks_transition_tbl))
one_month_ols_model_list %>% map(., ~ summary(.x))
one_month_coeftest_model_list <-
  map(one_month_ols_model_list,
      .f = ~ coeftest(.x, vcov = vcovCL, cluster = ~ bank))

modelsummary(
  one_month_coeftest_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = 5:20,
  title = "t to t-1"
)
zero_one_vec <- c(
  "change_in_surplus_capital = 0",
  "change_in_first_lag_of_surplus_capital = 0",
  "change_in_second_lag_of_surplus_capital = 0",
  "change_in_third_lag_of_surplus_capital = 0"
)
joint_test_one <-
  map(one_month_ols_model_list,
      ~ linearHypothesis(.x, zero_one_vec))


# t, t-3 model ------------------------------------------------------------
three_predictor_vec = c(
  "three_month_change_in_surplus_capital",
  "three_month_change_in_first_lag_of_surplus_capital",
  "three_month_change_in_second_lag_of_surplus_capital",
  "three_month_change_in_third_lag_of_surplus_capital",
  # "change_in_fourth_lag_of_surplus_capital", # No significance after third lad
  # "change_in_fifth_lag_of_surplus_capital",
  # "change_in_sixth_lag_of_surplus_capital",
  "factor(bank)",
  "factor(year)",
  "-1"
)

three_vec_list <- list(
  all_vec_household_secured = three_predictor_vec,
  all_vec_household_unsecured = three_predictor_vec,
  all_vec_household_mortgage = three_predictor_vec,
  all_vec_corporate_secured = three_predictor_vec,
  all_vec_corporate_unsecured = three_predictor_vec,
  all_vec_corporate_mortgage = three_predictor_vec
)

three_formula_list <-
  map2(response_vec,
       three_vec_list,
       .f = ~ formula_function(.x, variable_vec = .y))
three_ols_model_list <-
  map(three_formula_list,
      .f = ~ lm(.x, data = preprocessed_data_banks_transition_tbl))
three_ols_model_list %>% map(., ~ summary(.x))
three_coef_model_list <-
  map(three_ols_model_list,
      .f = ~ coeftest(.x, vcov = vcovCL, cluster = ~ bank))

modelsummary(
  three_coef_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = 5:20,
  title = "t to t-3"
)

zero_three_vec <- c(
  "three_month_change_in_surplus_capital = 0",
  "three_month_change_in_first_lag_of_surplus_capital = 0",
  "three_month_change_in_second_lag_of_surplus_capital = 0",
  "three_month_change_in_third_lag_of_surplus_capital = 0"
)
joint_test_three <-
  map(three_ols_model_list, ~ linearHypothesis(.x, zero_three_vec))

# Export ---------------------------------------------------------------
artifacts_transition_model <- list (
  lm_models = list(
    one_month_ols_model_list = one_month_ols_model_list,
    three_ols_model_list = three_ols_model_list
  ),
  coef_models = list(
    one_month_coeftest_model_list = one_month_coeftest_model_list,
    three_coef_model_list = three_coef_model_list
  ),
  joint_test = list(joint_test_one = joint_test_one,
                    joint_test_three = joint_test_three),
  data = list(preprocessed_data_banks_transition_tbl = preprocessed_data_banks_transition_tbl)
)

write_rds(artifacts_transition_model,
          file = here("Outputs", "artifacts_transition_model.rds"))
