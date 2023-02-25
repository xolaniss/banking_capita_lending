cleanup <-
function(data, date_size = 175){
  data %>% 
    as_tibble() %>%
    mutate(...1 = make_unique_duplicates(...1, sep = "-")) %>% 
    # drop_na() %>%
    pivot_longer(-...1, names_to = "Date", values_to = "Value") %>% 
    rename("Series" = ...1) %>% 
    mutate(Date = rep(seq(as.Date("2008-01-01"), as.Date("2022-11-01"), by = "month"), date_size ))
}
