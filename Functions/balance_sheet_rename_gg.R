balance_sheet_rename <-
  function(data) {
    data %>% 
      pivot_wider(names_from = Series, values_from = Value) %>% 
      rename("Farm mortgages" = 
               "Farm mortgages: (total of items 152 to 154)",
             "Household credit cards" = 
               "Household sector-5",
             "Commercial and other mortgage advances" =  
               "Commercial and other mortgage advances: (total of items 160 to 165)",
             "Non-financial corporate sector overdrafts"  = 
               "Non-financial corporate sector-4",
             "Unincorporated business enterprises of households overdrafts" = 
               "Unincorporated business enterprises of households",
             "Household overdrafts" = "Households",
             "Other loans and advances" =
               "Other loans and advances: (total of items 189 to 193)",
             "Credit impairments in respect of loans and advances" =
               "Less: credit impairments in respect of loans and advances" ,
             "Residential mortgages" = 
               "Residential mortgages: (total of items 156 to 158)"
      ) %>% 
      pivot_longer(-Date, names_to = "Series", values_to = "Value") %>% 
      mutate(Value = Value * 1000)   # to include scaling ("000)
  }

balance_sheet_rename_gg <-
  function(data) {
    data %>% 
      fx_nopivot_plot(ncol = 2, variables_color = 10) +
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
