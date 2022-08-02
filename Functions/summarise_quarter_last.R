summarise_quarter_last <-
function(data) {
  data %>% 
    group_by(Series) %>% 
    summarise_by_time(
      .date_var = Date,
      .by = "quarter",
      Value = last(Value)
    )
}
