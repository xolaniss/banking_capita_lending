ba900_aggregration <-
function(data){
  data %>%  
    pivot_wider(names_from = Series, values_from = Value) %>% 
    mutate(`Non-financial corporate unsecured credit` = 
             `Non-financial corporate sector instalment sales` +
             `Non-financial corporate sector credit cards` +
             `Non-financial corporate sector overdrafts` +
             `Factoring debtors` +
             `Non-financial corporate sector other loans and advances`) %>% 
    mutate(`Unicorporated enterprise credit` = 
             `Unincorporated business enterprises of households overdrafts` +
             `Unincorporated business enterprises of households other loans and advances`) %>% 
    mutate(`Household sector unsecured lending` =
             `Household sector instalment sales` +
             `Household credit cards` +
             `Households overdrafts` +
             `Households other loans and advances`) %>% 
    dplyr::select(Date,
                  `Non-financial corporate unsecured credit`,
                  `Unicorporated enterprise credit`,
                  `Household sector unsecured lending`,
                  `Residential mortgages`,
                  `Commercial and other mortgage advances`,
                  `Total assets`
    ) %>% 
    mutate(`Our total` = rowSums(across(.cols = 2:6))) %>% 
    mutate(`Other assets` = `Total assets` - `Our total`) %>% 
    dplyr::select(-`Total assets`, -`Our total`)  %>%
    pivot_longer(-Date, names_to = "Series", values_to = "Value")  
}
