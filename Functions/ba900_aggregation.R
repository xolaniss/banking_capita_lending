ba900_aggregration <-
  function(data) {
    data %>%
      pivot_wider(names_from = Series, values_from = Value) %>%
      mutate(
        `Non-financial corporate unsecured credit` =
          `Non-financial corporate sector credit cards` +
          `Non-financial corporate sector overdrafts` +
          `Factoring debtors` +
          `Non-financial corporate sector other loans and advances`
      ) %>%
      mutate(
        `Non-financial corporate secured credit` =
          `Non-financial corporate sector instalment sales` +
          `Non-financial corporate sector leasing transactions`
      ) %>% 
    mutate(
      `Household sector unsecured credit` =
        `Households credit cards` +
        `Households overdrafts` +
        `Households other loans and advances` +
        `Non-profit organisations serving households overdrafts` +
        `Non-profit organisations serving households other loans and advances` +
        `Unincorporated business enterprises of households overdrafts` + #including
        `Unincorporated business enterprises of households other loans and advances` # including
    ) %>%
      mutate(`Household sector secured credit` =
               `Households leasing transactions` +
               `Household sector instalment sales`) %>%
      mutate(
          `Non-financial corporate sector mortgages` =
          `Non-financial corporate sector farm mortgages` +
          `Households farm mortgages` +
          `Other farm mortgages` +
          `Non-financial corporate sector residential mortgages` +
          `Other residential mortgages` +
          `Private non-financial corporate sector commercial and other mortgages` +
          `Households commercial and other mortgages` +
          `Other commercial and other mortgages`
      ) %>%
      
      dplyr::select(
        Date,
        `Non-financial corporate unsecured credit`,
        `Non-financial corporate secured credit`,
        `Non-financial corporate sector mortgages`,
        `Household sector unsecured credit`,
        `Household sector secured credit`,
        `Households residential mortgages`,
        `Total assets`
      ) %>%
      mutate(`Our total` = rowSums(across(.cols = 2:6))) %>%
      mutate(`Other assets` = `Total assets` - `Our total`) %>%
      dplyr::select(-`Total assets`,-`Our total`)  %>%
      pivot_longer(-Date, names_to = "Series", values_to = "Value")
  }
