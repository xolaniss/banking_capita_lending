modelsummary_word <- function(models = models,
                              coef_map = NULL, 
                              coef_rename = NULL,
                              stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01), 
                              decimals = 2,
                              vcov =  NULL,
                              # variables_omit = "AIC|BIC|Std|Log",
                              title = NULL,
                              gof_map = gof_map
) {
  modelsummary(
    models,
    output = "flextable",
    stars = stars,
    fmt = decimals,
    vcov =  vcov,
    # gof_omit = variables_omit,
    coef_map = coef_map,
    coef_rename = coef_rename,
    title = title,
    gof_map = "all"
  ) %>%
    theme_booktabs() %>%
    border_inner(border = fp_border(color = "white"), part = "all") 
}
