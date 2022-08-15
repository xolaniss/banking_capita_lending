balance_sheet_rename <-
  function(data) {
    data %>% 
      pivot_wider(names_from = Series, values_from = Value) %>% 
      rename(
             "Residential mortgages" = 
               "Residential mortgages: (total of items 156 to 158)",
             "Non-financial corporate sector instalment sales" = "Non-financial corporate sector-1",
             "Non-financial corporate sector credit cards" = "Non-financial corporate sector-3",
             "Non-financial corporate sector overdrafts" = "Non-financial corporate sector-4",
             "Factoring debtors" = "Factoring debtors",
             "Non-financial corporate sector other loans and advances" = "Non-financial corporate sector-5",
             "Unincorporated business enterprises of households overdrafts" = "Unincorporated business enterprises of households",
             "Unincorporated business enterprises of households other loans and advances" = 
               "Unincorporated business enterprises of households-1",
             "Household sector instalment sales" = "Household sector",
             "Household credit cards" = "Household sector-5",
             "Households overdrafts" = "Households",
             "Households other loans and advances" = "Households-1",
             "Commercial and other mortgage advances" = 
               "Commercial and other mortgage advances: (total of items 160 to 165)",
             "Total assets" =
               "Deposits, loans and advances (total of items 111, 117, 118, 126, 135, 139, 150, 166, 171 and 180, less item 194)"
      ) %>% 
      pivot_longer(-Date, names_to = "Series", values_to = "Value") %>% 
      mutate(Value = Value * 1000)   # to include scaling ("000)
  }

balance_sheet_rename_gg <-
  function(data, variable_color = 12) {
    data %>% 
      fx_nopivot_plot(ncol = 2, variables_color = variable_color) +
      scale_y_continuous(labels = scales::label_dollar(prefix = "R", 
                                                       scale_cut = cut_short_scale())) 
  }

balance_sheet_rename_quartely_gg <-
  function(data) {
    data %>% 
      fx_nopivot_plot(ncol = 2, variables_color = 10) +
      scale_y_continuous(labels = scales::label_dollar(prefix = "R", 
                                                       scale_cut = cut_short_scale()))  +
      scale_x_date(breaks = scales::breaks_pretty())
    
  }
