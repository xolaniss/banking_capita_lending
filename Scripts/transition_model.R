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
library(modelsummary)

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
  read_rds(here("Outputs", "artifacts_base_model.rds"))
preprocessed_data_banks_tbl <-
  preprocessed_data$data$preprocessed_data_banks_base_tbl %>% glimpse()


preprocessed_data_banks_tbl %>% glimpse()

# Transformations ---------------------------------------------------------
preprocessed_data_banks_transition_tbl <-
  preprocessed_data_banks_tbl %>%
  mutate(across(
    .cols = 65,
    .fns = ~  lag(.x),
    .names = "First lag of {.col}"
  )) %>%    
  mutate(across(
    .cols = 65,
    .fns = ~  lag(.x, n = 2),
    .names = "Second lag of {.col}"
  )) %>%
  mutate(across(
    .cols = 65,
    .fns = ~  lag(.x, n = 3),
    .names = "Third lag of {.col}"
  )) %>%
  mutate(across(
    .cols = 65,
    .fns = ~  lag(.x, n = 4),
    .names = "Fourth lag of {.col}"
  )) %>%
  clean_names() %>%
  mutate(
    first_change = first_lag_of_change_in_required_capital_dummy -  second_lag_of_change_in_required_capital_dummy,
    second_change = second_lag_of_change_in_required_capital_dummy -  third_lag_of_change_in_required_capital_dummy,
    third_change = third_lag_of_change_in_required_capital_dummy -  fourth_lag_of_change_in_required_capital_dummy
  )
  

preprocessed_data_banks_transition_tbl %>% glimpse()


# Outliers ----------------------------------------------------------------
preprocessed_data_banks_transition_tbl <-
  preprocessed_data_banks_transition_tbl %>%
  mutate(across(matches("change_in_log"), .fns = ~ winsorize(.x, threshold = .01))) %>%
  mutate(across(
    contains("surplus_capital"),
    .fns = ~ winsorize(.x, threshold = .01)
  ))


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
  preprocessed_data_banks_transition_tbl %>%
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


# First lag Model -------------------------------------------------------------------
response_vec = c(
  "change_in_log_of_household_sector_secured_credit",
  "change_in_log_of_household_sector_unsecured_credit",
  "change_in_log_of_households_residential_mortgages",
  "change_in_log_of_non_financial_corporate_secured_credit",
  "change_in_log_of_non_financial_corporate_unsecured_credit",
  "change_in_log_of_non_financial_corporate_sector_mortgages"
)

predictor_vec = c(
  "change_in_required_capital_dummy",
  "first_change",
  "lag(return_on_assets)",
  "lag(return_on_equity)",
  "lag(log_of_level_one_high_quality_liquid_assets_required_to_be_held)",
  "factor(bank)",
  "factor(month)",
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
  coef_omit = NULL,
  title = "first lag"
)
 zero_one_vec <- c(
  "first_change = 0"
)
joint_test_one <-
  map(one_month_ols_model_list,
      ~ linearHypothesis(.x, zero_one_vec), vcov. = vcovBS(.x, cluster = ~ bank))

# Second lag Model -------------------------------------------------------------------
predictor_vec_two = c(
  "change_in_required_capital_dummy",
  "first_change",
  "second_change",
  "lag(return_on_assets)",
  "lag(return_on_equity)",
  "lag(log_of_level_one_high_quality_liquid_assets_required_to_be_held)",
  "factor(bank)",
  "factor(month)",
  "-1"
)

vec_list <- list(
  all_vec_household_secured = predictor_vec_two,
  all_vec_household_unsecured = predictor_vec_two,
  all_vec_household_mortgage = predictor_vec_two,
  all_vec_corporate_secured = predictor_vec_two,
  all_vec_corporate_unsecured = predictor_vec_two,
  all_vec_corporate_mortgage = predictor_vec_two
)
two_month_formula_list <-
  map2(response_vec,
       vec_list,
       .f = ~ formula_function(.x, variable_vec = .y))
two_month_ols_model_list <-
  map(two_month_formula_list,
      .f = ~ lm(.x, data = preprocessed_data_banks_transition_tbl))
two_month_ols_model_list %>% map(., ~ summary(.x))
two_month_coeftest_model_list <-
  map(two_month_ols_model_list,
      .f = ~ coeftest(.x, vcov = vcovCL, cluster = ~ bank))

modelsummary(
  two_month_coeftest_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = NULL,
  title = "first lag"
)
zero_two_vec <- c(
  "first_change = 0",
  "second_change = 0"
)
joint_test_two <-
  map(two_month_ols_model_list,
      ~ linearHypothesis(.x, zero_two_vec), vcov. = vcovBS(.x, cluster = ~ bank))


# Third lag Model -------------------------------------------------------------------
predictor_vec_three = c(
  "change_in_required_capital_dummy",
  "first_change",
  "second_change",
  "third_change",
  "lag(return_on_assets)",
  "lag(return_on_equity)",
  "lag(log_of_level_one_high_quality_liquid_assets_required_to_be_held)",
  "factor(bank)",
  "factor(month)",
  "-1"
)

vec_list <- list(
  all_vec_household_secured = predictor_vec_three,
  all_vec_household_unsecured = predictor_vec_three,
  all_vec_household_mortgage = predictor_vec_three,
  all_vec_corporate_secured = predictor_vec_three,
  all_vec_corporate_unsecured = predictor_vec_three,
  all_vec_corporate_mortgage = predictor_vec_three
)
three_month_formula_list <-
  map2(response_vec,
       vec_list,
       .f = ~ formula_function(.x, variable_vec = .y))
three_month_ols_model_list <-
  map(three_month_formula_list,
      .f = ~ lm(.x, data = preprocessed_data_banks_transition_tbl))
three_month_ols_model_list %>% map(., ~ summary(.x))
three_month_coeftest_model_list <-
  map(three_month_ols_model_list,
      .f = ~ coeftest(.x, vcov = vcovCL, cluster = ~ bank))

modelsummary(
  three_month_coeftest_model_list,
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_omit = NULL,
  title = "first lag"
)
zero_three_vec <- c(
  "first_change = 0",
  "second_change = 0",
  "third_change = 0")
joint_test_three <-
  map(three_month_ols_model_list,
      ~ linearHypothesis(.x, zero_three_vec), vcov. = vcovBS(.x, cluster = ~ bank))


# Export ---------------------------------------------------------------
artifacts_transition_model <- list (
  lm_models = list(
    one_month_ols_model_list = one_month_ols_model_list,
    two_month_ols_model_list = two_month_ols_model_list,
    three_month_ols_model_list = three_month_ols_model_list
  ),
  coef_models = list(
    one_month_coeftest_model_list = one_month_coeftest_model_list,
    two_month_coeftest_model_list = two_month_coeftest_model_list,
    three_month_coeftest_model_list = three_month_coeftest_model_list
  ),
  joint_test = list(joint_test_one = joint_test_one,
                    joint_test_two = joint_test_two,
                    joint_test_three = joint_test_three),
  data = list(preprocessed_data_banks_transition_tbl = preprocessed_data_banks_transition_tbl)
)

write_rds(artifacts_transition_model,
          file = here("Outputs", "artifacts_transition_model.rds"))
